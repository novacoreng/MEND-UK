-- MEND UK Phase 11 — warranty claims and disputes.
create index if not exists warranty_claims_warranty_status_idx on public.warranty_claims(warranty_id,status,created_at desc);
create index if not exists disputes_repair_status_idx on public.disputes(repair_id,status,created_at desc);
create index if not exists dispute_evidence_dispute_idx on public.dispute_evidence(dispute_id,created_at desc);

create or replace function public.open_warranty_claim(p_warranty_id uuid, p_reason text, p_description text)
returns public.warranty_claims language plpgsql security invoker set search_path=public as $$
declare w public.job_warranties; c public.warranty_claims; u uuid:=auth.uid();
begin
 if u is null then raise exception 'Authentication required.' using errcode='42501'; end if;
 if length(trim(coalesce(p_reason,'')))<3 or length(trim(coalesce(p_description,'')))<10 then raise exception 'Provide a clear reason and description.'; end if;
 select * into w from public.job_warranties where id=p_warranty_id for update;
 if not found then raise exception 'Warranty not found.'; end if;
 if w.customer_id<>u and not exists(select 1 from public.trade_profiles t where t.id=w.trade_id and t.user_id=u) and not public.is_admin() then raise exception 'Not authorised.' using errcode='42501'; end if;
 if current_date < w.start_date or current_date > w.end_date or w.status<>'active' then raise exception 'This warranty is not currently active.'; end if;
 insert into public.warranty_claims(warranty_id,reason,description,status) values(w.id,trim(p_reason),trim(p_description),'opened') returning * into c;
 return c;
end; $$;
grant execute on function public.open_warranty_claim(uuid,text,text) to authenticated;

create or replace function public.open_repair_dispute(p_repair_id uuid, p_reason text, p_description text)
returns public.disputes language plpgsql security invoker set search_path=public as $$
declare r public.repairs; d public.disputes; u uuid:=auth.uid(); against uuid;
begin
 if u is null then raise exception 'Authentication required.' using errcode='42501'; end if;
 if length(trim(coalesce(p_reason,'')))<3 or length(trim(coalesce(p_description,'')))<10 then raise exception 'Provide a clear reason and description.'; end if;
 select * into r from public.repairs where id=p_repair_id for update;
 if not found then raise exception 'Repair not found.'; end if;
 if u<>r.customer_id and u<>r.tenant_id and not exists(select 1 from public.trade_profiles t where t.id=r.assigned_trade_id and t.user_id=u) and not public.is_admin() then raise exception 'Not authorised.' using errcode='42501'; end if;
 if exists(select 1 from public.disputes where repair_id=r.id and status not in ('resolved','closed')) then raise exception 'An active dispute already exists for this repair.'; end if;
 if exists(select 1 from public.trade_profiles where t.id=r.assigned_trade_id and t.user_id<>u) then select t.user_id into against from public.trade_profiles t where t.id=r.assigned_trade_id; end if;
 insert into public.disputes(repair_id,raised_by,against_user,reason,description,status) values(r.id,u,against,trim(p_reason),trim(p_description),'opened') returning * into d;
 if r.status not in ('cancelled','closed') then update public.repairs set status='disputed',updated_at=now() where id=r.id; end if;
 return d;
end; $$;
grant execute on function public.open_repair_dispute(uuid,text,text) to authenticated;

create or replace function public.resolve_dispute(p_dispute_id uuid, p_status public.dispute_status, p_resolution text, p_refund_amount numeric default null)
returns public.disputes language plpgsql security invoker set search_path=public as $$
declare d public.disputes; u uuid:=auth.uid(); r public.repairs;
begin
 if u is null or not public.is_admin() then raise exception 'Only authorised dispute staff can resolve disputes.' using errcode='42501'; end if;
 if p_status not in ('resolution_proposed','resolved','escalated','closed') then raise exception 'Invalid resolution status.'; end if;
 if length(trim(coalesce(p_resolution,'')))<10 then raise exception 'Resolution details are required.'; end if;
 select * into d from public.disputes where id=p_dispute_id for update; if not found then raise exception 'Dispute not found.'; end if;
 if p_refund_amount is not null and p_refund_amount<0 then raise exception 'Refund cannot be negative.'; end if;
 update public.disputes set status=p_status,resolution=trim(p_resolution),refund_amount=p_refund_amount,updated_at=now() where id=d.id returning * into d;
 if p_status in ('resolved','closed') then select * into r from public.repairs where id=d.repair_id for update; if r.status='disputed' then update public.repairs set status='customer_review'.updated_at=now() where id=r.id; end if; end if; return d;
end; $$;
grant execute on function public.resolve_dispute(uuid,public.dispute_status,text,numeric) to authenticated;

-- Participants may read their own dispute evidence, but evidence is immutable.
drop policy if exists "dispute evidence involved read" on public.dispute_evidence;
create policy "dispute evidence involved read" on public.dispute_evidence for select to authenticated using (exists(select 1 from public.disputes d join public.repairs r on r.id=d.repair_id where d.id=dispute_id and (d.raised_by=(select auth.uid()) or d.against_user=(select auth.uid()) or r.customer_id=(select auth.uid()) or public.is_admin())));
drop policy if exists "dispute evidence insert" on public.dispute_evidence;
create policy "dispute evidence insert" on public.dispute_evidence for insert to authenticated with check (uploaded_by=(select auth.uid()) and exists(select 1 from public.disputes d where d.id=dispute_id and (d.raised_by=(select auth.uid()) or d.against_user=(select auth.uid()) or public.is_admin())));
