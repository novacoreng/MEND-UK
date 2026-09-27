-- MEND UK Phase 4 — repair lifecycle/state machine and Job Passport history.

create index if not exists repair_history_repair_created_idx on public.repair_status_history(repair_id, created_at asc);

create or replace function public.repair_actor_is_involved(p_repair_id uuid)
returns boolean language sql stable security definer set search_path=public
as $$
  select exists (
    select 1 from public.repairs r
    where r.id = p_repair_id
      and (r.customer_id = auth.uid() or r.tenant_id = auth.uid() or r.landlord_id = auth.uid()
        or r.property_manager_id = auth.uid()
        or exists(select 1 from public.trade_profiles t where t.id = r.assigned_trade_id and t.user_id = auth.uid())
        or public.is_admin())
  );
$$;

create or replace function public.validate_repair_status_transition()
returns trigger language plpgsql security definer set search_path=public
as $$
declare allowed boolean := false;
begin
  if new.status is not distinct from old.status then return new; end if;
  if public.is_admin() then return new; end if;
  if old.status = 'draft' and new.status = 'submitted' and (old.customer_id = auth.uid() or old.tenant_id = auth.uid()) then allowed := true;
  elsif new.status = 'cancelled' and old.status in ('draft','submitted','matching','quote_requested','quoted','accepted','scheduled') and (old.customer_id = auth.uid() or old.tenant_id = auth.uid()) then allowed := true;
  elsif old.status = 'scheduled' and new.status = 'on_the_way' and exists(select 1 from public.trade_profiles t where t.id = old.assigned_trade_id and t.user_id = auth.uid()) then allowed := true;
  elsif old.status = 'on_the_way' and new.status = 'arrived' and exists(select 1 from public.trade_profiles t where t.id = old.assigned_trade_id and t.user_id = auth.uid()) then allowed := true;
  elsif old.status = 'arrived' and new.status = 'in_progress' and exists(select 1 from public.trade_profiles t where t.id = old.assigned_trade_id and t.user_id = auth.uid()) then allowed := true;
  elsif old.status = 'in_progress' and new.status = 'completed' and exists(select 1 from public.trade_profiles t where t.id = old.assigned_trade_id and t.user_id = auth.uid()) then allowed := true;
  elsif old.status in ('completed','customer_review') and new.status = 'confirmed' and (old.customer_id = auth.uid() or old.tenant_id = auth.uid()) then allowed := true;
  elsif old.status = 'confirmed' and new.status = 'payment_completed' and (old.customer_id = auth.uid() or old.tenant_id = auth.uid()) then allowed := true;
  elsif old.status = 'payment_completed' and new.status = 'closed' and (old.customer_id = auth.uid() or old.tenant_id = auth.uid()) then allowed := true;
  end if;
  if not allowed then raise exception 'Status transition % → % is not permitted for this user.', old.status, new.status using errcode = '42501'; end if;
  return new;
end;
$$;

drop policy if exists "repairs involved update" on public.repairs;
create policy "repairs involved update" on public.repairs for update to authenticated
using (customer_id=(select auth.uid()) or tenant_id=(select auth.uid()) or landlord_id=(select auth.uid()) or property_manager_id=(select auth.uid()) or exists(select 1 from public.trade_profiles t where t.id=assigned_trade_id and t.user_id=(select auth.uid())) or public.is_admin())
with check (customer_id=(select auth.uid()) or tenant_id=(select auth.uid()) or landlord_id=(select auth.uid()) or property_manager_id=(select auth.uid()) or exists(select 1 from public.trade_profiles t where t.id=assigned_trade_id and t.user_id=(select auth.uid())) or public.is_admin());

drop trigger if exists repair_status_transition_guard on public.repairs;
create trigger repair_status_transition_guard before update of status on public.repairs for each row execute function public.validate_repair_status_transition();

create or replace function public.record_repair_status_change()
returns trigger language plpgsql security definer set search_path=public
as $$
begin
  if tg_op = 'INSERT' then insert into public.repair_status_history(repair_id, from_status, to_status, actor_id, note) values(new.id, null, new.status, auth.uid(), 'Repair created');
  elsif new.status is distinct from old.status then insert into public.repair_status_history(repair_id, from_status, to_status, actor_id) values(new.id, old.status, new.status, auth.uid()); end if;
  return new;
end;
$$;

drop trigger if exists repair_status_history_trigger on public.repairs;
create trigger repair_status_history_trigger after insert or update of status on public.repairs for each row execute function public.record_repair_status_change();

create or replace function public.transition_repair_status(p_repair_id uuid, p_to_status public.repair_status, p_note text default null)
returns public.repairs language plpgsql security invoker set search_path=public
as $$
declare result public.repairs;
begin
  if not public.repair_actor_is_involved(p_repair_id) then raise exception 'You are not authorised to update this repair.' using errcode = '42501'; end if;
  update public.repairs set status = p_to_status, updated_at = now() where id = p_repair_id returning * into result;
  if result.id is null then raise exception 'Repair not found.'; end if;
  if p_note is not null then update public.repair_status_history set note = p_note where id = (select id from public.repair_status_history where repair_id=p_repair_id order by created_at desc, id desc limit 1); end if;
  return result;
end;
$$;

grant execute on function public.transition_repair_status(uuid, public.repair_status, text) to authenticated;
