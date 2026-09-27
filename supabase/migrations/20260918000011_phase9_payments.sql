-- Phase 9: provider-backed repair payments. The client never chooses the payable amount.
create unique index if not exists payments_one_active_repair_payment_idx
  on public.payments(repair_id, payment_type)
  where status not in ('cancelled','failed','refunded','partially_refunded');

create unique index if not exists payments_provider_payment_id_idx
  on public.payments(provider_payment_id)
  where provider_payment_id is not null;

create index if not exists payment_transactions_payment_idx
  on public.payment_transactions(payment_id, created_at desc);

-- Client may read payment state but may not insert/update financial records.
drop policy if exists "payments client insert" on public.payments;
drop policy if exists "payments client update" on public.payments;
drop policy if exists "payment transactions client insert" on public.payment_transactions;
drop policy if exists "payouts client insert" on public.payouts;

-- Canonical server-side transition after provider confirmation.
create or replace function public.mark_payment_protected(
  p_payment_id uuid,
  p_provider_payment_id text,
  p_provider_event_id text,
  p_amount_pence bigint
) returns public.payments
language plpgsql
security definer
set search_path = public
as $$
declare
  v_payment public.payments;
  v_amount numeric(12,2);
begin
  if p_amount_pence < 1 then raise exception 'Invalid provider amount'; end if;
  v_amount := round((p_amount_pence::numeric / 100), 2);

  select * into v_payment from public.payments where id = p_payment_id for update;
  if not found then raise exception 'Payment not found'; end if;
  if round(v_payment.amount,2) <> v_amount then raise exception 'Provider amount does not match payment'; end if;

  update public.payments
    set status='protected', provider_payment_id=coalesce(provider_payment_id,p_provider_payment_id), updated_at=now()
    where id=v_payment.id;

  insert into public.payment_transactions(payment_id,transaction_type,amount,provider_reference,idempotency_key,metadata)
  values(v_payment.id,'payment_protected',v_amount,p_provider_event_id,p_provider_event_id,jsonb_build_object('provider_payment_id',p_provider_payment_id))
  on conflict(idempotency_key) do nothing;

  select * into v_payment from public.payments where id=p_payment_id;
  return v_payment;
end;
$$;
revoke all on function public.mark_payment_protected(uuid,text,text,bigint) from public;
grant execute on function public.mark_payment_protected(uuid,text,text,bigint) to service_role;

create or replace function public.mark_payment_failed(
  p_payment_id uuid,
  p_provider_payment_id text,
  p_provider_event_id text,
  p_reason text
) returns public.payments
language plpgsql
security definer
set search_path = public
as $$
declare v_payment public.payments;
begin
  select * into v_payment from public.payments where id=p_payment_id for update;
  if not found then raise exception 'Payment not found'; end if;
  update public.payments set status='failed',provider_payment_id=coalesce(provider_payment_id,p_provider_payment_id),updated_at=now() where id=p_payment_id;
  insert into public.payment_transactions(payment_id,transaction_type,amount,provider_reference,idempotency_key,metadata)
  values(p_payment_id,'payment_failed',v_payment.amount,p_provider_event_id,p_provider_event_id,jsonb_build_object('reason',coalesce(p_reason,'')))
  on conflict(idempotency_key) do nothing;
  select * into v_payment from public.payments where id=p_payment_id;
  return v_payment;
end;
$$;
revoke all on function public.mark_payment_failed(uuid,text,text,text) from public;
grant execute on function public.mark_payment_failed(uuid,text,text,text) to service_role;
