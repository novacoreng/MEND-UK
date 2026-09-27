-- MEND UK Phase 10 — repair completion, evidence, warranty and Job Passport.

create index if not exists repair_evidence_repair_phase_created_idx
  on public.repair_evidence(repair_id, evidence_phase, created_at desc);

create index if not exists job_warranties_customer_end_idx
  on public.job_warranties(customer_id, end_date desc);

-- Completion evidence is immutable. Users may upload evidence but cannot rewrite or delete it.
drop policy if exists "evidence update blocked" on public.repair_evidence;
drop policy if exists "evidence delete blocked" on public.repair_evidence;
create policy "evidence update blocked" on public.repair_evidence
for update to authenticated using (false) with check (false);
create policy "evidence delete blocked" on public.repair_evidence
for delete to authenticated using (false);

-- Canonical completion workflow. Trade completion requires completion evidence; customer
-- confirmation creates the warranty from the accepted quote and leaves payment release
-- to the later financial release phase.
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
    update public.repair_status_history
      set note=coalesce(p_note,'Trade marked repair complete.')
      where id=(select id from public.repair_status_history where repair_id=v_repair.id order by created_at desc,id desc limit 1);
    return v_result;
  end if;

  if v_repair.customer_id <> v_actor and v_repair.tenant_id <> v_actor then
    raise exception 'Only the customer or tenant can confirm this repair.' using errcode='42501';
  end if;
  if v_repair.status not in ('completed','customer_review') then
    raise exception 'Repair is not ready for customer confirmation.';
  end if;

  select * into v_quote from public.quotes
    where repair_id=v_repair.id and status='accepted'
    order by version desc limit 1;
  if found then v_quote_found := true; v_warranty_days := greatest(coalesce(v_quote.warranty_days,0),0); end if;

  update public.repairs
    set status='confirmed', final_price=coalesce(final_price,estimated_price), updated_at=now()
    where id=v_repair.id returning * into v_result;

  update public.repair_status_history
    set note=coalesce(p_note,'Customer confirmed repair completion.')
    where id=(select id from public.repair_status_history where repair_id=v_repair.id order by created_at desc,id desc limit 1);

  if v_quote_found and v_warranty_days > 0 then
    insert into public.job_warranties(repair_id,trade_id,customer_id,start_date,end_date,terms,status)
    values(v_repair.id,v_repair.assigned_trade_id,v_repair.customer_id,current_date,current_date+v_warranty_days,
      coalesce(v_quote.scope_description,'Warranty for completed repair.'),'active')
    on conflict(repair_id) do update set
      trade_id=excluded.trade_id, customer_id=excluded.customer_id,
      start_date=excluded.start_date, end_date=excluded.end_date,
      terms=excluded.terms, status='active';
  end if;

  return v_result;
end;
$$;

grant execute on function public.complete_repair(uuid,text,text) to authenticated;

-- Read-only consolidated Job Passport payload for involved users. Individual child tables
-- remain protected by their own RLS policies.
create or replace function public.get_job_passport(p_repair_id uuid)
returns jsonb
language plpgsql
security invoker
set search_path=public
as $$
declare
  v_repair public.repairs;
  v_user uuid := auth.uid();
begin
  select * into v_repair from public.repairs where id=p_repair_id;
  if not found then raise exception 'Repair not found.'; end if;
  if not (v_repair.customer_id=v_user or v_repair.tenant_id=v_user or v_repair.landlord_id=v_user or
          v_repair.property_manager_id=v_user or
          exists(select 1 from public.trade_profiles t where t.id=v_repair.assigned_trade_id and t.user_id=v_user) or
          public.is_admin()) then
    raise exception 'You are not authorised to view this Job Passport.' using errcode='42501';
  end if;

  return jsonb_build_object(
    'repair', to_jsonb(v_repair),
    'history', coalesce((select jsonb_agg(to_jsonb(h) order by h.created_at asc) from public.repair_status_history h where h.repair_id=p_repair_id),'[]'::jsonb),
    'evidence', coalesce((select jsonb_agg(to_jsonb(e) order by e.created_at desc) from public.repair_evidence e where e.repair_id=p_repair_id),'[]'::jsonb),
    'quotes', coalesce((select jsonb_agg(to_jsonb(q) order by q.version desc) from public.quotes q where q.repair_id=p_repair_id),'[]'::jsonb),
    'appointments', coalesce((select jsonb_agg(to_jsonb(a) order by a.start_time asc) from public.appointments a where a.repair_id=p_repair_id),'[]'::jsonb),
    'payments', coalesce((select jsonb_agg(to_jsonb(p) order by p.created_at desc) from public.payments p where p.repair_id=p_repair_id),'[]'::jsonb),
    'warranties', coalesce((select jsonb_agg(to_jsonb(w) order by w.end_date desc) from public.job_warranties w where w.repair_id=p_repair_id),'[]'::jsonb),
    'reviews', coalesce((select jsonb_agg(to_jsonb(r) order by r.created_at desc) from public.reviews r where r.repair_id=p_repair_id),'[]'::jsonb),
    'disputes', coalesce((select jsonb_agg(to_jsonb(d) order by d.created_at desc) from public.disputes d where d.repair_id=p_repair_id),'[]'::jsonb)
  );
end;
$$;

grant execute on function public.get_job_passport(uuid) to authenticated;
