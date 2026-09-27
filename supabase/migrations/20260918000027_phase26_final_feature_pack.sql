-- MEND UK final feature pack: customer, trade, support, maintenance, compliance and QA foundations.
create table if not exists public.saved_trades (
  user_id uuid not null references public.profiles(id) on delete cascade,
  trade_id uuid not null references public.trade_profiles(id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key(user_id, trade_id)
);

create table if not exists public.maintenance_plans (
  id uuid primary key default gen_random_uuid(),
  property_id uuid not null references public.properties(id) on delete cascade,
  title text not null,
  description text,
  frequency_months integer not null check (frequency_months > 0),
  next_due_at timestamptz,
  status text not null default 'active' check (status in ('active','paused','completed')),
  created_by uuid references public.profiles(id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.maintenance_tasks (
  id uuid primary key default gen_random_uuid(),
  plan_id uuid not null references public.maintenance_plans(id) on delete cascade,
  title text not null,
  category text,
  due_at timestamptz,
  completed_at timestamptz,
  completed_by uuid references public.profiles(id) on delete set null,
  status text not null default 'scheduled' check (status in ('scheduled','due','completed','skipped')),
  created_at timestamptz not null default now()
);

create table if not exists public.support_tickets (
  id uuid primary key default gen_random_uuid(),
  ticket_number text unique not null,
  user_id uuid not null references public.profiles(id) on delete cascade,
  repair_id uuid references public.repairs(id) on delete set null,
  subject text not null,
  category text not null,
  priority text not null default 'normal' check (priority in ('low','normal','high','urgent')),
  status text not null default 'open' check (status in ('open','in_progress','waiting_customer','resolved','closed')),
  description text not null,
  assigned_agent uuid references public.profiles(id) on delete set null,
  resolved_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.support_messages (
  id uuid primary key default gen_random_uuid(),
  ticket_id uuid not null references public.support_tickets(id) on delete cascade,
  sender_id uuid not null references public.profiles(id) on delete cascade,
  body text not null,
  internal_note boolean not null default false,
  created_at timestamptz not null default now()
);

create table if not exists public.compliance_consents (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  document_type text not null check (document_type in ('terms','privacy','ai_notice','marketing','payment_terms')),
  document_version text not null,
  accepted_at timestamptz not null default now(),
  withdrawn_at timestamptz
);

create table if not exists public.account_deletion_requests (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  reason text,
  status text not null default 'requested' check (status in ('requested','reviewing','scheduled','completed','cancelled')),
  requested_at timestamptz not null default now(),
  completed_at timestamptz
);

create table if not exists public.data_export_requests (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  status text not null default 'requested' check (status in ('requested','processing','ready','expired','failed')),
  requested_at timestamptz not null default now(),
  ready_at timestamptz,
  expires_at timestamptz
);

create table if not exists public.release_test_runs (
  id uuid primary key default gen_random_uuid(),
  environment text not null check (environment in ('development','staging','production')),
  platform text not null check (platform in ('android','ios','web','backend')),
  test_name text not null,
  status text not null check (status in ('passed','failed','blocked','not_run')),
  details text,
  run_by uuid references public.profiles(id) on delete set null,
  created_at timestamptz not null default now()
);

create index if not exists idx_saved_trades_user on public.saved_trades(user_id);
create index if not exists idx_maintenance_plans_property on public.maintenance_plans(property_id, status);
create index if not exists idx_maintenance_tasks_due on public.maintenance_tasks(due_at, status);
create index if not exists idx_support_tickets_user on public.support_tickets(user_id, created_at desc);
create index if not exists idx_support_tickets_status on public.support_tickets(status, priority, created_at desc);
create index if not exists idx_support_messages_ticket on public.support_messages(ticket_id, created_at);
create index if not exists idx_consents_user on public.compliance_consents(user_id, document_type, accepted_at desc);

alter table public.saved_trades enable row level security;
alter table public.maintenance_plans enable row level security;
alter table public.maintenance_tasks enable row level security;
alter table public.support_tickets enable row level security;
alter table public.support_messages enable row level security;
alter table public.compliance_consents enable row level security;
alter table public.account_deletion_requests enable row level security;
alter table public.data_export_requests enable row level security;
alter table public.release_test_runs enable row level security;

create policy saved_trades_own_select on public.saved_trades for select using (auth.uid() = user_id);
create policy saved_trades_own_insert on public.saved_trades for insert with check (auth.uid() = user_id);
create policy saved_trades_own_delete on public.saved_trades for delete using (auth.uid() = user_id);

create policy maintenance_plans_member_select on public.maintenance_plans for select using (exists (select 1 from public.property_members pm where pm.property_id = maintenance_plans.property_id and pm.user_id = auth.uid() and pm.can_view = true) or exists (select 1 from public.properties p where p.id = maintenance_plans.property_id and p.owner_id = auth.uid()));
create policy maintenance_plans_member_write on public.maintenance_plans for all using (exists (select 1 from public.property_members pm where pm.property_id = maintenance_plans.property_id and pm.user_id = auth.uid() and pm.can_manage_property = true) or exists (select 1 from public.properties p where p.id = maintenance_plans.property_id and p.owner_id = auth.uid())) with check (created_by = auth.uid() or exists (select 1 from public.properties p where p.id = maintenance_plans.property_id and p.owner_id = auth.uid()));
create policy maintenance_tasks_member_select on public.maintenance_tasks for select using (exists (select 1 from public.maintenance_plans mp join public.property_members pm on pm.property_id=mp.property_id where mp.id=maintenance_tasks.plan_id and pm.user_id=auth.uid() and pm.can_view=true) or exists (select 1 from public.maintenance_plans mp join public.properties p on p.id=mp.property_id where mp.id=maintenance_tasks.plan_id and p.owner_id=auth.uid()));
create policy maintenance_tasks_member_write on public.maintenance_tasks for all using (exists (select 1 from public.maintenance_plans mp join public.properties p on p.id=mp.property_id where mp.id=maintenance_tasks.plan_id and p.owner_id=auth.uid()));

create policy support_tickets_own_select on public.support_tickets for select using (auth.uid()=user_id or auth.uid()=assigned_agent);
create policy support_tickets_own_insert on public.support_tickets for insert with check (auth.uid()=user_id);
create policy support_tickets_own_update on public.support_tickets for update using (auth.uid()=user_id or auth.uid()=assigned_agent) with check (auth.uid()=user_id or auth.uid()=assigned_agent);
create policy support_messages_ticket_select on public.support_messages for select using (exists(select 1 from public.support_tickets st where st.id=support_messages.ticket_id and (st.user_id=auth.uid() or st.assigned_agent=auth.uid())));
create policy support_messages_ticket_insert on public.support_messages for insert with check (sender_id=auth.uid() and exists(select 1 from public.support_tickets st where st.id=support_messages.ticket_id and (st.user_id=auth.uid() or st.assigned_agent=auth.uid())));

create policy consents_own_select on public.compliance_consents for select using (auth.uid()=user_id);
create policy consents_own_insert on public.compliance_consents for insert with check (auth.uid()=user_id);
create policy deletion_own_select on public.account_deletion_requests for select using (auth.uid()=user_id);
create policy deletion_own_insert on public.account_deletion_requests for insert with check (auth.uid()=user_id);
create policy export_own_select on public.data_export_requests for select using (auth.uid()=user_id);
create policy export_own_insert on public.data_export_requests for insert with check (auth.uid()=user_id);
create policy release_tests_admin_select on public.release_test_runs for select using (exists(select 1 from public.user_roles ur where ur.user_id=auth.uid() and ur.role in ('admin','super_admin')));

create or replace function public.create_support_ticket(p_subject text,p_category text,p_priority text,p_description text,p_repair_id uuid default null)
returns public.support_tickets language plpgsql security invoker set search_path=public as $$
declare result public.support_tickets;
begin
 if auth.uid() is null then raise exception 'Authentication required'; end if;
 insert into public.support_tickets(ticket_number,user_id,repair_id,subject,category,priority,description)
 values ('MEND-'||upper(substr(replace(gen_random_uuid()::text,'-',''),1,10)),auth.uid(),p_repair_id,trim(p_subject),trim(p_category),p_priority,trim(p_description)) returning * into result;
 return result;
end; $$;

grant execute on function public.create_support_ticket(text,text,text,text,uuid) to authenticated;
