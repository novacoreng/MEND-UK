create table if not exists public.release_checklist (
 id uuid primary key default gen_random_uuid(), key text unique not null, title text not null, required boolean not null default true, status text not null default 'pending' check (status in ('pending','passed','blocked','waived')), evidence text, checked_by uuid references public.profiles(id) on delete set null, checked_at timestamptz
);
insert into public.release_checklist(key,title,required) values
('supabase_rls','Supabase migrations and RLS verified',true),('auth','Production authentication configuration verified',true),('payments','Payment provider and webhook verification completed',true),('notifications','Push/email/SMS providers verified',true),('storage','Private storage and signed access verified',true),('ai','AI provider, safety policy and audit trail verified',true),('mobile','iOS and Android release builds verified',true),('privacy','UK GDPR/privacy launch review completed',true),('backup','Backup and recovery test completed',true),('monitoring','Production monitoring and incident alerts enabled',true)
on conflict(key) do nothing;
alter table public.release_checklist enable row level security;
create policy "admins manage release checklist" on public.release_checklist for all to authenticated using(exists(select 1 from public.profiles p where p.id=(select auth.uid()) and p.role in ('admin','super_admin'))) with check(exists(select 1 from public.profiles p where p.id=(select auth.uid()) and p.role in ('admin','super_admin')));
