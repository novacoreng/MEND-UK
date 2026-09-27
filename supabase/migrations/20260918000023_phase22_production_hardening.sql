create table if not exists public.idempotency_keys (
 id uuid primary key default gen_random_uuid(), user_id uuid not null references public.profiles(id) on delete cascade, operation text not null, request_key text not null, response_hash text, created_at timestamptz not null default now(), expires_at timestamptz not null default (now()+interval '24 hours'), unique(user_id,operation,request_key)
);
create table if not exists public.security_audit_events (
 id uuid primary key default gen_random_uuid(), actor_id uuid references public.profiles(id) on delete set null, event_type text not null, target_type text, target_id uuid, metadata jsonb not null default '{}'::jsonb, created_at timestamptz not null default now()
);
create index if not exists security_audit_events_created_idx on public.security_audit_events(created_at desc);
alter table public.idempotency_keys enable row level security;
alter table public.security_audit_events enable row level security;
create policy "users own idempotency keys" on public.idempotency_keys for select to authenticated using (user_id=(select auth.uid()));
create policy "admins read security audit" on public.security_audit_events for select to authenticated using (exists(select 1 from public.profiles p where p.id=(select auth.uid()) and p.role in ('admin','super_admin','finance_admin','support_agent','verification_agent')));
revoke all on public.idempotency_keys from anon, authenticated;
revoke all on public.security_audit_events from anon, authenticated;
