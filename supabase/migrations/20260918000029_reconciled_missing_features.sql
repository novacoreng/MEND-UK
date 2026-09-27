-- MEND UK reconciliation migration
-- Recreates the remaining production feature foundations when the historical phase
-- migrations are not available in the repository. Safe to run repeatedly.

create extension if not exists pgcrypto;

-- Tenant experience
create table if not exists public.tenant_profiles (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  property_id uuid,
  tenancy_status text not null default 'active',
  move_in_date date,
  move_out_date date,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique(user_id, property_id)
);

-- Landlord experience
create table if not exists public.landlord_profiles (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  portfolio_name text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique(user_id)
);

create table if not exists public.landlord_properties (
  id uuid primary key default gen_random_uuid(),
  landlord_id uuid not null references public.landlord_profiles(id) on delete cascade,
  property_id uuid,
  created_at timestamptz not null default now()
);

-- Property manager experience
create table if not exists public.manager_profiles (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  company_name text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique(user_id)
);

create table if not exists public.manager_invitations (
  id uuid primary key default gen_random_uuid(),
  manager_id uuid not null references public.manager_profiles(id) on delete cascade,
  email text not null,
  token text not null unique,
  status text not null default 'pending',
  expires_at timestamptz,
  created_at timestamptz not null default now()
);

-- Trade professional capabilities
create table if not exists public.trade_profiles (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  business_name text,
  verification_status text not null default 'pending',
  bio text,
  service_area text,
  rating numeric(3,2),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique(user_id)
);

create table if not exists public.trade_services (
  id uuid primary key default gen_random_uuid(),
  trade_id uuid not null references public.trade_profiles(id) on delete cascade,
  service_name text not null,
  description text,
  hourly_rate numeric(12,2),
  active boolean not null default true,
  created_at timestamptz not null default now()
);

-- Trust and safety
create table if not exists public.safety_events (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references public.profiles(id) on delete set null,
  repair_id uuid,
  event_type text not null,
  severity text not null default 'info',
  details jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);

create table if not exists public.fraud_flags (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references public.profiles(id) on delete set null,
  repair_id uuid,
  reason text not null,
  status text not null default 'open',
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  resolved_at timestamptz
);

-- Notifications and communications
create table if not exists public.notification_devices (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  provider text not null,
  token text not null,
  active boolean not null default true,
  created_at timestamptz not null default now(),
  unique(provider, token)
);

create table if not exists public.notification_deliveries (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references public.profiles(id) on delete set null,
  channel text not null,
  notification_type text not null,
  payload jsonb not null default '{}'::jsonb,
  status text not null default 'queued',
  delivered_at timestamptz,
  created_at timestamptz not null default now()
);

create table if not exists public.messages (
  id uuid primary key default gen_random_uuid(),
  sender_id uuid not null references public.profiles(id) on delete cascade,
  recipient_id uuid not null references public.profiles(id) on delete cascade,
  repair_id uuid,
  body text not null,
  read_at timestamptz,
  created_at timestamptz not null default now()
);

-- Analytics and observability
create table if not exists public.analytics_events (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references public.profiles(id) on delete set null,
  event_name text not null,
  properties jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);

create table if not exists public.performance_metrics (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references public.profiles(id) on delete set null,
  metric_name text not null,
  value numeric,
  unit text,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);

-- MEND Intelligence audit layer
create table if not exists public.intelligence_events (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references public.profiles(id) on delete set null,
  repair_id uuid,
  event_type text not null,
  input_data jsonb not null default '{}'::jsonb,
  output_data jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);

-- Stripe Connect / payout linkage
create table if not exists public.stripe_connect_accounts (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  stripe_account_id text not null unique,
  charges_enabled boolean not null default false,
  payouts_enabled boolean not null default false,
  details_submitted boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique(user_id)
);

create table if not exists public.payment_ledger (
  id uuid primary key default gen_random_uuid(),
  repair_id uuid,
  payer_id uuid references public.profiles(id) on delete set null,
  payee_id uuid references public.profiles(id) on delete set null,
  stripe_payment_intent_id text,
  stripe_transfer_id text,
  amount numeric(12,2) not null,
  currency text not null default 'gbp',
  platform_fee numeric(12,2) not null default 0,
  status text not null default 'pending',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- Feature flags / final launch controls
create table if not exists public.feature_flags (
  key text primary key,
  enabled boolean not null default false,
  rollout_percentage integer not null default 100 check (rollout_percentage between 0 and 100),
  metadata jsonb not null default '{}'::jsonb,
  updated_at timestamptz not null default now()
);

-- Indexes
create index if not exists tenant_profiles_user_idx on public.tenant_profiles(user_id);
create index if not exists landlord_properties_landlord_idx on public.landlord_properties(landlord_id);
create index if not exists manager_invitations_manager_idx on public.manager_invitations(manager_id);
create index if not exists trade_services_trade_idx on public.trade_services(trade_id);
create index if not exists safety_events_user_idx on public.safety_events(user_id);
create index if not exists fraud_flags_status_idx on public.fraud_flags(status);
create index if not exists notification_deliveries_status_idx on public.notification_deliveries(status);
create index if not exists messages_recipient_idx on public.messages(recipient_id, created_at desc);
create index if not exists analytics_events_name_idx on public.analytics_events(event_name, created_at desc);
create index if not exists intelligence_events_repair_idx on public.intelligence_events(repair_id, created_at desc);

-- RLS
alter table public.tenant_profiles enable row level security;
alter table public.landlord_profiles enable row level security;
alter table public.landlord_properties enable row level security;
alter table public.manager_profiles enable row level security;
alter table public.manager_invitations enable row level security;
alter table public.trade_profiles enable row level security;
alter table public.trade_services enable row level security;
alter table public.safety_events enable row level security;
alter table public.fraud_flags enable row level security;
alter table public.notification_devices enable row level security;
alter table public.notification_deliveries enable row level security;
alter table public.messages enable row level security;
alter table public.analytics_events enable row level security;
alter table public.performance_metrics enable row level security;
alter table public.intelligence_events enable row level security;
alter table public.stripe_connect_accounts enable row level security;
alter table public.payment_ledger enable row level security;
alter table public.feature_flags enable row level security;

create policy if not exists tenant_profiles_owner on public.tenant_profiles for all using (auth.uid() = user_id) with check (auth.uid() = user_id);
create policy if not exists landlord_profiles_owner on public.landlord_profiles for all using (auth.uid() = user_id) with check (auth.uid() = user_id);
create policy if not exists manager_profiles_owner on public.manager_profiles for all using (auth.uid() = user_id) with check (auth.uid() = user_id);
create policy if not exists trade_profiles_owner on public.trade_profiles for all using (auth.uid() = user_id) with check (auth.uid() = user_id);
create policy if not exists notification_devices_owner on public.notification_devices for all using (auth.uid() = user_id) with check (auth.uid() = user_id);
create policy if not exists messages_participant on public.messages for all using (auth.uid() = sender_id or auth.uid() = recipient_id) with check (auth.uid() = sender_id);
create policy if not exists analytics_owner on public.analytics_events for all using (auth.uid() = user_id) with check (auth.uid() = user_id);
create policy if not exists performance_owner on public.performance_metrics for all using (auth.uid() = user_id) with check (auth.uid() = user_id);
create policy if not exists stripe_connect_owner on public.stripe_connect_accounts for all using (auth.uid() = user_id) with check (auth.uid() = user_id);
create policy if not exists feature_flags_read on public.feature_flags for select using (true);

comment on table public.tenant_profiles is 'Reconciled tenant experience foundation';
comment on table public.landlord_profiles is 'Reconciled landlord experience foundation';
comment on table public.manager_profiles is 'Reconciled property manager foundation';
comment on table public.trade_profiles is 'Reconciled trade professional foundation';
comment on table public.safety_events is 'Reconciled trust and safety audit layer';
comment on table public.analytics_events is 'Reconciled product analytics layer';
comment on table public.intelligence_events is 'Reconciled MEND Intelligence audit layer';
comment on table public.stripe_connect_accounts is 'Reconciled Stripe Connect account linkage';
