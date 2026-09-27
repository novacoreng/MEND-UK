-- MEND UK Phase 1 — Authentication & Identity hardening.
-- Apply after 002_production_hardening.sql.
-- Supabase Auth remains the source of truth for authentication. Public clients
-- may only read/update their own profile and read their own roles.

-- Never allow client-side role assignment. The signup trigger grants only customer.
drop policy if exists "roles client insert" on public.user_roles;
drop policy if exists "roles client update" on public.user_roles;
drop policy if exists "roles client delete" on public.user_roles;

-- Ensure profile email remains synchronized with the authenticated identity.
create or replace function public.sync_profile_email() returns trigger
language plpgsql security definer set search_path = public
as $$
begin
  update public.profiles
  set email = new.email, updated_at = now()
  where id = new.id;
  return new;
end;
$$;

drop trigger if exists on_auth_user_email_changed on auth.users;
create trigger on_auth_user_email_changed
after update of email on auth.users
for each row execute function public.sync_profile_email();

-- Keep the customer role bootstrap deterministic for accounts created before
-- the Phase 1 migration was applied.
insert into public.user_roles(user_id, role)
select p.id, 'customer'::public.user_role
from public.profiles p
where not exists (select 1 from public.user_roles r where r.user_id = p.id);

-- Explicitly restrict profile mutations to the authenticated owner/admin.
drop policy if exists "profiles own update" on public.profiles;
create policy "profiles own update" on public.profiles
for update to authenticated
using (id = (select auth.uid()) or public.is_admin())
with check (id = (select auth.uid()) or public.is_admin());

drop policy if exists "profiles own read" on public.profiles;
create policy "profiles own read" on public.profiles
for select to authenticated
using (id = (select auth.uid()) or public.is_admin());

-- The email address is owned by Supabase Auth. Clients may not mutate it via profiles.
-- The profile trigger above keeps the read-only profile email in sync.
