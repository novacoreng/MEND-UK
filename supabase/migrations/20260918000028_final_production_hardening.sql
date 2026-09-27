-- MEND UK Final Production Hardening: environments, verification, property compliance,
-- richer Job Passport, offline sync, accessibility/performance telemetry and observability.

create table if not exists public.trade_verification_requirements (
  id uuid primary key default gen_random_uuid(),
  trade_id uuid not null references public.trade_profiles(id) on delete cascade,
  requirement_type text not null check (requirement_type in ('identity','business','insurance','qualification','registration','background_check')),
  required boolean not null default true,
  status text not null default 'not_started' check (status in ('not_started','submitted','under_review','verified','rejected','expired','suspended')),
  evidence_document_id uuid references public.trade_documents(id) on delete set null,
  reviewed_by uuid references public.profiles(id) on delete set null,
  reviewed_at timestamptz,
  expires_at timestamptz,
  notes text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique(trade_id, requirement_type)
);

create table if not exists public.property_compliance_items (
  id uuid primary key default gen_random_uuid(), property_id uuid not null references public.properties(id) on delete cascade,
  compliance_type text not null, title text not null, status text not null default 'not_recorded' check (status in ('not_recorded','valid','due_soon','expired','not_applicable','under_review')),
  issued_at date, expires_at date, reference_number text, document_id uuid references public.documents(id) on delete set null, notes text, created_by uuid references public.profiles(id) on delete set null,
  created_at timestamptz not null default now(), updated_at timestamptz not null default now()
);
create table if not exists public.job_passport_events (
  id uuid primary key default gen_random_uuid(), repair_id uuid not null references public.repairs(id) on delete cascade, event_type text not null, title text not null, details text, actor_id uuid references public.profiles(id) on delete set null, occurred_at timestamptz not null default now(), metadata jsonb not null default '{}'::jsonb
);
create table if not exists public.repair_access_instructions (
  id uuid primary key default gen_random_uuid(), repair_id uuid unique not null references public.repairs(id) on delete cascade, access_method text, parking_notes text, contact_notes text, pets_notes text, safety_notes text, updated_by uuid references public.profiles(id) on delete set null, updated_at timestamptz not null default now()
);
create table if not exists public.offline_sync_actions (
  id uuid primary key default gen_random_uuid(), user_id uuid not null references public.profiles(id) on delete cascade, client_action_id text not null, action_type text not null, payload jsonb not null default '{}'::jsonb, status text not null default 'queued' check (status in ('queued','processing','completed','failed','dead_letter')), attempts integer not null default 0, last_error text, created_at timestamptz not null default now(), updated_at timestamptz not null default now(), unique(user_id, client_action_id)
);
create table if not exists public.app_observability_events (
  id uuid primary key default gen_random_uuid(), user_id uuid references public.profiles(id) on delete set null, environment text not null default 'production', platform text, event_name text not null, severity text not null default 'info' check (severity in ('debug','info','warning','error','fatal')), screen text, trace_id text, app_version text, metadata jsonb not null default '{}'::jsonb, created_at timestamptz not null default now()
);
create table if not exists public.performance_metrics (
  id uuid primary key default gen_random_uuid(), user_id uuid references public.profiles(id) on delete set null, metric_name text not null, duration_ms integer, value numeric, screen text, app_version text, platform text, metadata jsonb not null default '{}'::jsonb, created_at timestamptz not null default now()
);
create index if not exists idx_trade_verification_requirements_trade on public.trade_verification_requirements(trade_id,status);
create index if not exists idx_property_compliance_property on public.property_compliance_items(property_id,status,expires_at);
create index if not exists idx_job_passport_events_repair on public.job_passport_events(repair_id,occurred_at desc);
create index if not exists idx_offline_sync_user_status on public.offline_sync_actions(user_id,status,created_at);
create index if not exists idx_observability_created on public.app_observability_events(created_at desc,severity);
create index if not exists idx_performance_created on public.performance_metrics(created_at desc,metric_name);

alter table public.trade_verification_requirements enable row level security;
alter table public.property_compliance_items enable row level security;
alter table public.job_passport_events enable row level security;
alter table public.repair_access_instructions enable row level security;
alter table public.offline_sync_actions enable row level security;
alter table public.app_observability_events enable row level security;
alter table public.performance_metrics enable row level security;

create policy trade_verification_owner_select on public.trade_verification_requirements for select to authenticated using (exists(select 1 from public.trade_profiles t where t.id=trade_id and t.user_id=auth.uid()) or public.is_admin());
create policy trade_verification_admin_update on public.trade_verification_requirements for all to authenticated using (public.is_admin()) with check (public.is_admin());
create policy property_compliance_member_select on public.property_compliance_items for select to authenticated using (exists(select 1 from public.properties p where p.id=property_id and p.owner_id=auth.uid()) or exists(select 1 from public.property_members pm where pm.property_id=property_id and pm.user_id=auth.uid() and pm.can_view=true) or public.is_admin());
create policy property_compliance_manager_write on public.property_compliance_items for all to authenticated using (exists(select 1 from public.properties p where p.id=property_id and p.owner_id=auth.uid()) or exists(select 1 from public.property_members pm where pm.property_id=property_id and pm.user_id=auth.uid() and pm.can_manage_documents=true) or public.is_admin()) with check (created_by=auth.uid() or exists(select 1 from public.properties p where p.id=property_id and p.owner_id=auth.uid()) or public.is_admin());
create policy job_passport_events_select on public.job_passport_events for select to authenticated using (public.repair_actor_is_involved(repair_id) or public.is_admin());
create policy repair_access_instructions_select on public.repair_access_instructions for select to authenticated using (public.repair_actor_is_involved(repair_id) or public.is_admin());
create policy repair_access_instructions_write on public.repair_access_instructions for all to authenticated using (public.repair_actor_is_involved(repair_id) or public.is_admin()) with check (updated_by=auth.uid() or public.is_admin());
create policy offline_sync_own_select on public.offline_sync_actions for select to authenticated using (user_id=auth.uid());
create policy offline_sync_own_insert on public.offline_sync_actions for insert to authenticated with check (user_id=auth.uid());
create policy offline_sync_own_update on public.offline_sync_actions for update to authenticated using (user_id=auth.uid()) with check (user_id=auth.uid());
create policy observability_own_insert on public.app_observability_events for insert to authenticated with check (user_id=auth.uid() or user_id is null);
create policy observability_admin_select on public.app_observability_events for select to authenticated using (public.is_admin());
create policy performance_own_insert on public.performance_metrics for insert to authenticated with check (user_id=auth.uid() or user_id is null);
create policy performance_admin_select on public.performance_metrics for select to authenticated using (public.is_admin());

create or replace function public.upsert_trade_verification_requirement(p_trade_id uuid,p_type text,p_status text,p_document_id uuid default null,p_expires_at timestamptz default null,p_notes text default null) returns public.trade_verification_requirements language plpgsql security invoker set search_path=public as $$ declare r public.trade_verification_requirements;u uuid:=auth.uid(); begin if u is null then raise exception 'Authentication required' using errcode='42501';end if;if not(public.is_admin() or exists(select 1 from public.trade_profiles t where t.id=p_trade_id and t.user_id=u)) then raise exception 'Not authorised' using errcode='42501';end if;insert into public.trade_verification_requirements(trade_id,requirement_type,status,evidence_document_id,expires_at,notes) values(p_trade_id,p_type,p_status,p_document_id,p_expires_at,p_notes) on conflict(trade_id,requirement_type) do update set status=excluded.status,evidence_document_id=excluded.evidence_document_id,expires_at=excluded.expires_at,notes=excluded.notes,updated_at=now() returning * into r;return r;end; $$;
grant execute on function public.upsert_trade_verification_requirement(uuid,text,text,uuid,timestamptz,text) to authenticated;
create or replace function public.record_observability_event(p_event_name text,p_severity text default 'info',p_screen text default null,p_trace_id text default null,p_app_version text default null,p_platform text default null,p_metadata jsonb default '{}'::jsonb) returns uuid language plpgsql security invoker set search_path=public as $$ declare id_out uuid;begin if auth.uid() is null then raise exception 'Authentication required' using errcode='42501';end if;insert into public.app_observability_events(user_id,event_name,severity,screen,trace_id,app_version,platform,metadata) values(auth.uid(),left(p_event_name,120),p_severity,p_screen,p_trace_id,p_app_version,p_platform,coalesce(p_metadata,'{}'::jsonb)) returning id into id_out;return id_out;end; $$;
grant execute on function public.record_observability_event(text,text,text,text,text,text,jsonb) to authenticated;
create or replace function public.record_performance_metric(p_metric_name text,p_duration_ms integer default null,p_value numeric default null,p_screen text default null,p_app_version text default null,p_platform text default null,p_metadata jsonb default '{}'::jsonb) returns uuid language plpgsql security invoker set search_path=public as $$ declare id_out uuid;begin if auth.uid() is null then raise exception 'Authentication required' using errcode='42501';end if;insert into public.performance_metrics(user_id,metric_name,duration_ms,value,screen,app_version,platform,metadata) values(auth.uid(),left(p_metric_name,120),p_duration_ms,p_value,p_screen,p_app_version,p_platform,coalesce(p_metadata,'{}'::jsonb)) returning id into id_out;return id_out;end; $$;
grant execute on function public.record_performance_metric(text,integer,numeric,text,text,text,jsonb) to authenticated;
create or replace function public.enqueue_offline_action(p_client_action_id text,p_action_type text,p_payload jsonb) returns public.offline_sync_actions language plpgsql security invoker set search_path=public as $$ declare r public.offline_sync_actions;begin if auth.uid() is null then raise exception 'Authentication required' using errcode='42501';end if;insert into public.offline_sync_actions(user_id,client_action_id,action_type,payload) values(auth.uid(),p_client_action_id,p_action_type,coalesce(p_payload,'{}'::jsonb)) on conflict(user_id,client_action_id) do update set payload=excluded.payload,updated_at=now() returning * into r;return r;end; $$;
grant execute on function public.enqueue_offline_action(text,text,jsonb) to authenticated;
