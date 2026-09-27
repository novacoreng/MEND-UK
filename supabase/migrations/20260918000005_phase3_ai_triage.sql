-- Phase 3: MEND AI triage, safety and evidence metadata
create table if not exists public.ai_triage_sessions (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references public.profiles(id) on delete set null,
  repair_id uuid references public.repairs(id) on delete set null,
  description text not null,
  selected_category text,
  result jsonb not null default '{}',
  model text,
  confidence numeric(5,4),
  safety_level text not null default 'standard' check (safety_level in ('standard','urgent','emergency','immediate_danger')),
  created_at timestamptz not null default now()
);

alter table public.repairs add column if not exists triage_session_id uuid references public.ai_triage_sessions(id) on delete set null;
alter table public.repairs add column if not exists safety_level text default 'standard';
alter table public.repairs add column if not exists safety_notes text;
alter table public.repairs add column if not exists ai_recommended_action text;
alter table public.repairs add column if not exists ai_confidence numeric(5,4);

create index if not exists ai_triage_user_idx on public.ai_triage_sessions(user_id, created_at desc);
create index if not exists ai_triage_repair_idx on public.ai_triage_sessions(repair_id, created_at desc);
create index if not exists repairs_safety_idx on public.repairs(safety_level, status);

alter table public.ai_triage_sessions enable row level security;

drop policy if exists "triage own read" on public.ai_triage_sessions;
create policy "triage own read" on public.ai_triage_sessions
for select to authenticated
using (user_id = (select auth.uid()) or public.is_admin());

drop policy if exists "triage own insert" on public.ai_triage_sessions;
create policy "triage own insert" on public.ai_triage_sessions
for insert to authenticated
with check (user_id = (select auth.uid()));

drop policy if exists "triage own update" on public.ai_triage_sessions;

drop policy if exists "evidence update blocked" on public.repair_evidence;
create policy "evidence update blocked" on public.repair_evidence for update to authenticated using (false) with check (false);
