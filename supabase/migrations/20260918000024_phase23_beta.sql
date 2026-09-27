create table if not exists public.beta_feedback (
 id uuid primary key default gen_random_uuid(), user_id uuid not null references public.profiles(id) on delete cascade, category text not null check (category in ('bug','feedback','safety','payment','other')), message text not null, screen text, severity text not null default 'normal' check (severity in ('low','normal','high','critical')), status text not null default 'open' check (status in ('open','triaged','resolved','closed')), created_at timestamptz not null default now(), updated_at timestamptz not null default now()
);
create table if not exists public.feature_flags (
 key text primary key, enabled boolean not null default false, beta_only boolean not null default true, updated_at timestamptz not null default now()
);
alter table public.beta_feedback enable row level security;
alter table public.feature_flags enable row level security;
create policy "users own beta feedback" on public.beta_feedback for select to authenticated using(user_id=(select auth.uid()));
create policy "users create beta feedback" on public.beta_feedback for insert to authenticated with check(user_id=(select auth.uid()));
create policy "admins manage beta feedback" on public.beta_feedback for update to authenticated using(exists(select 1 from public.profiles p where p.id=(select auth.uid()) and p.role in ('admin','super_admin','support_agent'))) with check(exists(select 1 from public.profiles p where p.id=(select auth.uid()) and p.role in ('admin','super_admin','support_agent')));
create policy "enabled feature flags read" on public.feature_flags for select to authenticated using(enabled=true);
