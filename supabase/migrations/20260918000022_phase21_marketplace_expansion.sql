create table if not exists public.marketplace_products (
 id uuid primary key default gen_random_uuid(), supplier_name text not null, name text not null, category text not null, unit text not null default 'each', unit_price numeric(12,2) not null check (unit_price >= 0), currency text not null default 'GBP', stock_status text not null default 'available' check (stock_status in ('available','limited','unavailable')), is_active boolean not null default true, created_at timestamptz not null default now(), updated_at timestamptz not null default now()
);
create table if not exists public.marketplace_orders (
 id uuid primary key default gen_random_uuid(), customer_id uuid not null references public.profiles(id) on delete cascade, repair_id uuid references public.repairs(id) on delete set null, status text not null default 'draft' check (status in ('draft','pending_payment','paid','processing','shipped','delivered','cancelled','refunded')), subtotal numeric(12,2) not null default 0, platform_fee numeric(12,2) not null default 0, total numeric(12,2) not null default 0, currency text not null default 'GBP', created_at timestamptz not null default now(), updated_at timestamptz not null default now()
);
create table if not exists public.marketplace_order_items (
 id uuid primary key default gen_random_uuid(), order_id uuid not null references public.marketplace_orders(id) on delete cascade, product_id uuid references public.marketplace_products(id) on delete set null, description text not null, quantity numeric(12,3) not null check (quantity > 0), unit_price numeric(12,2) not null check (unit_price >= 0), total numeric(12,2) not null check (total >= 0)
);
create table if not exists public.maintenance_plans (
 id uuid primary key default gen_random_uuid(), trade_id uuid references public.trade_profiles(id) on delete set null, name text not null, description text not null, interval_months integer not null check (interval_months > 0), price numeric(12,2) not null check (price >= 0), currency text not null default 'GBP', is_active boolean not null default true, created_at timestamptz not null default now()
);
alter table public.marketplace_products enable row level security;
alter table public.marketplace_orders enable row level security;
alter table public.marketplace_order_items enable row level security;
alter table public.maintenance_plans enable row level security;
create policy "active products public authenticated read" on public.marketplace_products for select to authenticated using (is_active=true);
create policy "customer orders own read" on public.marketplace_orders for select to authenticated using (customer_id=(select auth.uid()));
create policy "customer order items own read" on public.marketplace_order_items for select to authenticated using (exists (select 1 from public.marketplace_orders o where o.id=order_id and o.customer_id=(select auth.uid())));
create policy "active maintenance plans read" on public.maintenance_plans for select to authenticated using (is_active=true);
