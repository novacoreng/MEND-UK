-- MEND UK Phase 5: Trade marketplace hardening
alter table public.trade_profiles enable row level security;
alter table public.trade_services enable row level security;
alter table public.trade_service_areas enable row level security;
alter table public.trade_availability enable row level security;
alter table public.trade_documents enable row level security;
alter table public.trade_verifications enable row level security;
alter table public.services enable row level security;
alter table public.service_categories enable row level security;

create index if not exists idx_trade_profiles_active_rating on public.trade_profiles(is_active, average_rating desc);
create index if not exists idx_trade_profiles_location on public.trade_profiles(latitude, longitude);
create index if not exists idx_trade_service_areas_prefix on public.trade_service_areas(postcode_prefix);
create index if not exists idx_trade_availability_trade_weekday on public.trade_availability(trade_id, weekday, is_active);
create index if not exists idx_trade_verifications_status on public.trade_verifications(trade_id, status);

drop policy if exists "trade profiles public active read" on public.trade_profiles;
create policy "trade profiles public active read" on public.trade_profiles for select to anon, authenticated using (is_active = true or user_id = (select auth.uid()) or public.is_admin());
drop policy if exists "trade profiles owner insert" on public.trade_profiles;
create policy "trade profiles owner insert" on public.trade_profiles for insert to authenticated with check (user_id = (select auth.uid()));
drop policy if exists "trade profiles owner update" on public.trade_profiles;
create policy "trade profiles owner update" on public.trade_profiles for update to authenticated using (user_id = (select auth.uid()) or public.is_admin()) with check (user_id = (select auth.uid()) or public.is_admin());

drop policy if exists "services public active read" on public.services;
create policy "services public active read" on public.services for select to anon, authenticated using (is_active = true);
drop policy if exists "categories public read" on public.service_categories;
create policy "categories public read" on public.service_categories for select to anon, authenticated using (is_active = true);

drop policy if exists "trade services public active read" on public.trade_services;
create policy "trade services public active read" on public.trade_services for select to anon, authenticated using (exists(select 1 from public.trade_profiles tp where tp.id = trade_id and (tp.is_active = true or tp.user_id = (select auth.uid()) or public.is_admin())));
drop policy if exists "trade services owner write" on public.trade_services;
create policy "trade services owner write" on public.trade_services for all to authenticated using (exists(select 1 from public.trade_profiles tp where tp.id = trade_id and (tp.user_id = (select auth.uid()) or public.is_admin()))) with check (exists(select 1 from public.trade_profiles tp where tp.id = trade_id and (tp.user_id = (select auth.uid()) or public.is_admin())));

drop policy if exists "trade areas public read" on public.trade_service_areas;
create policy "trade areas public read" on public.trade_service_areas for select to anon, authenticated using (exists(select 1 from public.trade_profiles tp where tp.id = trade_id and (tp.is_active = true or tp.user_id = (select auth.uid()) or public.is_admin())));
drop policy if exists "trade areas owner write" on public.trade_service_areas;
create policy "trade areas owner write" on public.trade_service_areas for all to authenticated using (exists(select 1 from public.trade_profiles tp where tp.id = trade_id and (tp.user_id = (select auth.uid()) or public.is_admin()))) with check (exists(select 1 from public.trade_profiles tp where tp.id = trade_id and (tp.user_id = (select auth.uid()) or public.is_admin())));

drop policy if exists "trade availability public read" on public.trade_availability;
create policy "trade availability public read" on public.trade_availability for select to anon, authenticated using (exists(select 1 from public.trade_profiles tp where tp.id = trade_id and (tp.is_active = true or tp.user_id = (select auth.uid()) or public.is_admin())));
drop policy if exists "trade availability owner write" on public.trade_availability;
create policy "trade availability owner write" on public.trade_availability for all to authenticated using (exists(select 1 from public.trade_profiles tp where tp.id = trade_id and (tp.user_id = (select auth.uid()) or public.is_admin()))) with check (exists(select 1 from public.trade_profiles tp where tp.id = trade_id and (tp.user_id = (select auth.uid()) or public.is_admin())));

drop policy if exists "trade documents owner admin" on public.trade_documents;
create policy "trade documents owner admin" on public.trade_documents for all to authenticated using (exists(select 1 from public.trade_profiles tp where tp.id = trade_id and (tp.user_id = (select auth.uid()) or public.is_admin()))) with check (exists(select 1 from public.trade_profiles tp where tp.id = trade_id and (tp.user_id = (select auth.uid()) or public.is_admin())));

drop policy if exists "trade verification public status" on public.trade_verifications;
create policy "trade verification public status" on public.trade_verifications for select to anon, authenticated using (status = 'verified' or exists(select 1 from public.trade_profiles tp where tp.id = trade_id and (tp.user_id = (select auth.uid()) or public.is_admin())));
drop policy if exists "trade verification admin write" on public.trade_verifications;
create policy "trade verification admin write" on public.trade_verifications for all to authenticated using (public.is_admin()) with check (public.is_admin());

insert into public.services(category_id,name,description,pricing_model)
select c.id, s.name, s.description, 'quote'
from public.service_categories c
cross join (values ('Emergency plumbing','Leaks, burst pipes and urgent plumbing attendance'),('Boiler service','Boiler servicing and maintenance'),('Electrical fault','Domestic electrical fault diagnosis and repair'),('Roof repair','Roof leaks, tiles and minor roof repairs'),('General handyman','General home repairs and small maintenance jobs')) s(name,description)
where c.name in ('Plumbing','Heating & Boilers','Electrical','Roofing','Handyman')
on conflict (category_id,name) do nothing;

-- Only administrators can publish a trade. Registration creates an inactive profile.
