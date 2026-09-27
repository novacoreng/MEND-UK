-- MEND UK — Stripe Connect marketplace payments for iOS + Android.
-- Architecture: platform creates the PaymentIntent; Stripe PaymentSheet collects payment natively;
-- customer confirmation requests release; a server-side transfer pays the connected trade account.

create table if not exists public.stripe_connected_accounts (
  id uuid primary key default gen_random_uuid(),
  trade_id uuid not null unique references public.trade_profiles(id) on delete cascade,
  stripe_account_id text not null unique,
  account_type text not null default 'express',
  country text not null default 'GB',
  details_submitted boolean not null default false,
  charges_enabled boolean not null default false,
  payouts_enabled boolean not null default false,
  requirements_due jsonb not null default '[]'::jsonb,
  status text not null default 'pending',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table public.stripe_connected_accounts enable row level security;

drop policy if exists "stripe connected account trade read" on public.stripe_connected_accounts;
create policy "stripe connected account trade read"
  on public.stripe_connected_accounts for select to authenticated
  using (
    exists(select 1 from public.trade_profiles t where t.id=trade_id and t.user_id=(select auth.uid()))
    or public.is_admin()
  );

create index if not exists stripe_connected_accounts_trade_idx
  on public.stripe_connected_accounts(trade_id);

alter table public.payments add column if not exists platform_fee numeric(12,2) not null default 0;
alter table public.payments add column if not exists transfer_amount numeric(12,2) not null default 0;
alter table public.payments add column if not exists provider_charge_id text;
alter table public.payments add column if not exists provider_transfer_id text;
alter table public.payments add column if not exists transfer_group text;
alter table public.payments add column if not exists released_at timestamptz;
alter table public.payments add column if not exists refunded_amount numeric(12,2) not null default 0;

create unique index if not exists payments_provider_charge_id_idx
  on public.payments(provider_charge_id) where provider_charge_id is not null;
create unique index if not exists payments_provider_transfer_id_idx
  on public.payments(provider_transfer_id) where provider_transfer_id is not null;

create or replace function public.set_stripe_connected_account_state(
  p_trade_id uuid,
  p_account_id text,
  p_details_submitted boolean,
  p_charges_enabled boolean,
  p_payouts_enabled boolean,
  p_requirements_due jsonb,
  p_status text
) returns public.stripe_connected_accounts
language plpgsql
security definer
set search_path = public
as $$
declare v public.stripe_connected_accounts;
begin
  insert into public.stripe_connected_accounts(
    trade_id,stripe_account_id,details_submitted,charges_enabled,payouts_enabled,requirements_due,status,updated_at
  ) values(
    p_trade_id,p_account_id,p_details_submitted,p_charges_enabled,p_payouts_enabled,coalesce(p_requirements_due,'[]'::jsonb),p_status,now()
  )
  on conflict(trade_id) do update set
    stripe_account_id=excluded.stripe_account_id,
    details_submitted=excluded.details_submitted,
    charges_enabled=excluded.charges_enabled,
    payouts_enabled=excluded.payouts_enabled,
    requirements_due=excluded.requirements_due,
    status=excluded.status,
    updated_at=now()
  returning * into v;
  return v;
end;
$$;
revoke all on function public.set_stripe_connected_account_state(uuid,text,boolean,boolean,boolean,jsonb,text) from public;
grant execute on function public.set_stripe_connected_account_state(uuid,text,boolean,boolean,boolean,jsonb,text) to service_role;

create or replace function public.request_payment_release(p_payment_id uuid)
returns public.payments
language plpgsql
security definer
set search_path = public
as $$
declare
  v public.payments;
begin
  select * into v from public.payments where id=p_payment_id for update;
  if not found then raise exception 'Payment not found'; end if;
  if v.status not in ('protected','release_requested') then
    raise exception 'Payment is not eligible for release';
  end if;
  if v.provider_transfer_id is not null then return v; end if;

  update public.payments
    set status='release_requested', updated_at=now()
    where id=v.id;

  insert into public.payment_transactions(payment_id,transaction_type,amount,provider_reference,idempotency_key,metadata)
  values(v.id,'release_requested',v.amount,null,'release-request:'||v.id,jsonb_build_object('transfer_amount',v.transfer_amount,'platform_fee',v.platform_fee))
  on conflict(idempotency_key) do nothing;

  select * into v from public.payments where id=p_payment_id;
  return v;
end;
$$;
revoke all on function public.request_payment_release(uuid) from public;
grant execute on function public.request_payment_release(uuid) to service_role;

create or replace function public.mark_payment_released(
  p_payment_id uuid,
  p_transfer_id text,
  p_provider_event_id text
) returns public.payments
language plpgsql
security definer
set search_path = public
as $$
declare v public.payments;
begin
  select * into v from public.payments where id=p_payment_id for update;
  if not found then raise exception 'Payment not found'; end if;
  update public.payments
    set status='released', provider_transfer_id=coalesce(provider_transfer_id,p_transfer_id), released_at=coalesce(released_at,now()), updated_at=now()
    where id=v.id;
  insert into public.payment_transactions(payment_id,transaction_type,amount,provider_reference,idempotency_key,metadata)
  values(v.id,'payout_released',v.transfer_amount,p_provider_event_id,'release-event:'||p_provider_event_id,jsonb_build_object('transfer_id',p_transfer_id))
  on conflict(idempotency_key) do nothing;
  insert into public.payouts(payment_id,trade_id,amount,status,provider_reference)
  values(v.id,v.trade_id,v.transfer_amount,'paid',p_transfer_id)
  on conflict do nothing;
  select * into v from public.payments where id=p_payment_id;
  return v;
end;
$$;
revoke all on function public.mark_payment_released(uuid,text,text) from public;
grant execute on function public.mark_payment_released(uuid,text,text) to service_role;

create or replace function public.mark_payment_transfer_failed(
  p_payment_id uuid,
  p_transfer_id text,
  p_reason text,
  p_provider_event_id text
) returns public.payments
language plpgsql
security definer
set search_path = public
as $$
declare v public.payments;
begin
  select * into v from public.payments where id=p_payment_id for update;
  if not found then raise exception 'Payment not found'; end if;
  update public.payments set status='release_requested',updated_at=now() where id=v.id;
  insert into public.payment_transactions(payment_id,transaction_type,amount,provider_reference,idempotency_key,metadata)
  values(v.id,'payout_failed',v.transfer_amount,p_provider_event_id,'transfer-failed:'||p_provider_event_id,jsonb_build_object('transfer_id',p_transfer_id,'reason',coalesce(p_reason,'')))
  on conflict(idempotency_key) do nothing;
  select * into v from public.payments where id=p_payment_id;
  return v;
end;
$$;
revoke all on function public.mark_payment_transfer_failed(uuid,text,text,text) from public;
grant execute on function public.mark_payment_transfer_failed(uuid,text,text,text) to service_role;

create or replace function public.complete_repair(
  p_repair_id uuid,
  p_action text,
  p_note text default null
) returns public.repairs
language plpgsql
security invoker
set search_path = public
as $$
declare
  v_repair public.repairs;
  v_quote public.quotes;
  v_warranty_days integer := 0;
  v_quote_found boolean := false;
  v_actor uuid := auth.uid();
  v_result public.repairs;
begin
  if v_actor is null then raise exception 'Authentication required.' using errcode='42501'; end if;
  if p_action not in ('trade_complete','customer_confirm') then raise exception 'Invalid completion action.'; end if;

  select * into v_repair from public.repairs where id=p_repair_id for update;
  if not found then raise exception 'Repair not found.'; end if;

  if p_action='trade_complete' then
    if not exists(select 1 from public.trade_profiles t where t.id=v_repair.assigned_trade_id and t.user_id=v_actor) then
      raise exception 'Only the assigned trade can mark this repair complete.' using errcode='42501';
    end if;
    if v_repair.status <> 'in_progress' then raise exception 'Repair must be in progress before trade completion.'; end if;
    if not exists(select 1 from public.repair_evidence e where e.repair_id=v_repair.id and e.evidence_phase='completion') then
      raise exception 'Add at least one completion evidence item before marking the repair complete.'; end if;
    update public.repairs set status='completed', updated_at=now() where id=v_repair.id returning * into v_result;
    update public.repair_status_history set note=coalesce(p_note,'Trade marked repair complete.')
      where id=(select id from public.repair_status_history where repair_id=v_repair.id order by created_at desc,id desc limit 1);
    return v_result;
  end if;

  if v_repair.customer_id <> v_actor and v_repair.tenant_id <> v_actor then
    raise exception 'Only the customer or tenant can confirm this repair.' using errcode='42501';
  end if;
  if v_repair.status not in ('completed','customer_review') then raise exception 'Repair is not ready for customer confirmation.'; end if;

  select * into v_quote from public.quotes where repair_id=v_repair.id and status='accepted' order by version desc limit 1;
  if found then v_quote_found := true; v_warranty_days := greatest(coalesce(v_quote.warranty_days,0),0); end if;

  update public.repairs set status='confirmed', final_price=coalesce(final_price,estimated_price), updated_at=now()
    where id=v_repair.id returning * into v_result;
  update public.repair_status_history set note=coalesce(p_note,'Customer confirmed repair completion.')
    where id=(select id from public.repair_status_history where repair_id=v_repair.id order by created_at desc,id desc limit 1);

  if v_quote_found and v_warranty_days > 0 then
    insert into public.job_warranties(repair_id,trade_id,customer_id,start_date,end_date,terms,status)
    values(v_repair.id,v_repair.assigned_trade_id,v_repair.customer_id,current_date,current_date+v_warranty_days,
      coalesce(v_quote.scope_description,'Warranty for completed repair.'),'active')
    on conflict(repair_id) do update set trade_id=excluded.trade_id,customer_id=excluded.customer_id,start_date=excluded.start_date,end_date=excluded.end_date,terms=excluded.terms,status='active';
  end if;
  return v_result;
end;
$$;
grant execute on function public.complete_repair(uuid,text,text) to authenticated;

create unique index if not exists payouts_one_repair_payment_idx on public.payouts(payment_id);
