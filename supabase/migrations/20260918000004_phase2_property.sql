-- MEND UK Phase 2: Home Passport / Property System
create table if not exists public.property_rooms (
  id uuid primary key default gen_random_uuid(),
  property_id uuid not null references public.properties(id) on delete cascade,
  name text not null,
  room_type text,
  floor text,
  notes text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.property_assets (
  id uuid primary key default gen_random_uuid(),
  property_id uuid not null references public.properties(id) on delete cascade,
  room_id uuid references public.property_rooms(id) on delete set null,
  name text not null,
  asset_type text not null,
  brand text,
  model text,
  serial_number text,
  installed_on date,
  warranty_end date,
  notes text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists property_rooms_property_idx on public.property_rooms(property_id);
create index if not exists property_assets_property_idx on public.property_assets(property_id);
create index if not exists property_assets_warranty_idx on public.property_assets(warranty_end);

alter table public.property_rooms enable row level security;
alter table public.property_assets enable row level security;

create policy "property members can read rooms" on public.property_rooms for select to authenticated
using (public.is_property_member(property_id));
create policy "property managers can create rooms" on public.property_rooms for insert to authenticated
with check (public.is_property_member(property_id));
create policy "property managers can update rooms" on public.property_rooms for update to authenticated
using (public.is_property_member(property_id)) with check (public.is_property_member(property_id));
create policy "property managers can delete rooms" on public.property_rooms for delete to authenticated
using (public.is_property_member(property_id));

create policy "property members can read assets" on public.property_assets for select to authenticated
using (public.is_property_member(property_id));
create policy "property managers can create assets" on public.property_assets for insert to authenticated
with check (public.is_property_member(property_id));
create policy "property managers can update assets" on public.property_assets for update to authenticated
using (public.is_property_member(property_id)) with check (public.is_property_member(property_id));
create policy "property managers can delete assets" on public.property_assets for delete to authenticated
using (public.is_property_member(property_id));

-- Keep the property owner represented as a member so member-based access works consistently.
create or replace function public.add_property_owner_member()
returns trigger language plpgsql security invoker as $$
begin
  if new.owner_id is not null then
    insert into public.property_members(property_id,user_id,member_role,can_view,can_create_repair,can_manage_repair,can_approve_payment,can_manage_documents,can_manage_property)
    values(new.id,new.owner_id,'owner',true,true,true,true,true,true)
    on conflict (property_id,user_id) do update set
      member_role='owner', can_view=true, can_create_repair=true, can_manage_repair=true,
      can_approve_payment=true, can_manage_documents=true, can_manage_property=true;
  end if;
  return new;
end $$;

drop trigger if exists property_owner_member_trigger on public.properties;
create trigger property_owner_member_trigger
after insert or update of owner_id on public.properties
for each row execute function public.add_property_owner_member();

create or replace function public.touch_property_children()
returns trigger language plpgsql as $$ begin new.updated_at=now(); return new; end $$;
drop trigger if exists property_rooms_updated_at on public.property_rooms;
create trigger property_rooms_updated_at before update on public.property_rooms for each row execute function public.touch_property_children();
drop trigger if exists property_assets_updated_at on public.property_assets;
create trigger property_assets_updated_at before update on public.property_assets for each row execute function public.touch_property_children();
