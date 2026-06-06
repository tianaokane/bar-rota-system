-- ============================================================
-- bar-rota-system — initial schema
-- Run this in Supabase SQL editor (Database → SQL Editor)
-- ============================================================

-- Enable UUID generation
create extension if not exists "pgcrypto";


-- ============================================================
-- ROLES
-- The two qualifications: bar or kp
-- ============================================================
create table roles (
  id uuid primary key default gen_random_uuid(),
  name text not null unique,
  venue_area text not null,
  description text
);

insert into roles (name, venue_area, description) values
  ('bar', 'various', 'Bar staff — main bar, Wee Bar, Mandela, barista'),
  ('kp',  'kitchen', 'Kitchen porter');


-- ============================================================
-- USERS (extends Supabase auth.users)
-- ============================================================
create table users (
  id uuid primary key references auth.users(id) on delete cascade,
  name text not null,
  email text not null unique,
  role text not null default 'staff' check (role in ('staff', 'manager', 'admin')),
  contracted_hours int not null default 0,
  active boolean not null default true,
  created_at timestamptz not null default now()
);


-- ============================================================
-- USER ROLES (junction — who is qualified for what)
-- ============================================================
create table user_roles (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references users(id) on delete cascade,
  role_id uuid not null references roles(id) on delete cascade,
  is_primary boolean not null default false,
  granted_at timestamptz not null default now(),
  unique (user_id, role_id)
);


-- ============================================================
-- SHIFT TEMPLATES
-- Reusable shift definitions. is_adhoc = true for Mandela,
-- Wee Bar events etc. added as one-offs outside the fortnight.
-- ============================================================
create table shift_templates (
  id uuid primary key default gen_random_uuid(),
  role_id uuid not null references roles(id) on delete restrict,
  name text not null,
  venue_area text not null,
  start_time time not null,
  end_time time not null,
  min_staff int not null default 1,
  is_adhoc boolean not null default false
);

insert into shift_templates (role_id, name, venue_area, start_time, end_time, min_staff, is_adhoc)
values
  -- Bar regular
  ((select id from roles where name = 'bar'), 'Main bar',        'main_bar', '12:00', '23:00', 2, false),
  ((select id from roles where name = 'bar'), 'Barista morning', 'wee_bar',  '09:00', '13:00', 1, false),
  -- Bar ad hoc
  ((select id from roles where name = 'bar'), 'Wee Bar',         'wee_bar',  '12:00', '23:00', 1, true),
  ((select id from roles where name = 'bar'), 'Mandela concert', 'mandela',  '18:00', '23:00', 2, true),
  -- KP regular
  ((select id from roles where name = 'kp'),  'KP shift',        'kitchen',  '10:00', '18:00', 1, false);


-- ============================================================
-- FORTNIGHTS
-- Each scheduling period. status: draft → published → archived
-- ============================================================
create table fortnights (
  id uuid primary key default gen_random_uuid(),
  start_date date not null,
  end_date date not null,
  status text not null default 'draft' check (status in ('draft', 'published', 'archived')),
  published_at timestamptz,
  check (end_date = start_date + interval '13 days')
);


-- ============================================================
-- AVAILABILITY
-- Staff submit one row per shift slot they can/can't do.
-- status: available | unavailable | preferred
-- ============================================================
create table availability (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references users(id) on delete cascade,
  fortnight_id uuid not null references fortnights(id) on delete cascade,
  shift_template_id uuid not null references shift_templates(id) on delete cascade,
  shift_date date not null,
  status text not null default 'available' check (status in ('available', 'unavailable', 'preferred')),
  submitted_at timestamptz not null default now(),
  unique (user_id, fortnight_id, shift_template_id, shift_date)
);


-- ============================================================
-- ROTA SHIFTS
-- The actual assigned rota. One row per person per shift.
-- status: scheduled | swapped | cancelled
-- ============================================================
create table rota_shifts (
  id uuid primary key default gen_random_uuid(),
  fortnight_id uuid references fortnights(id) on delete cascade,
  user_id uuid not null references users(id) on delete cascade,
  shift_template_id uuid not null references shift_templates(id) on delete cascade,
  shift_date date not null,
  status text not null default 'scheduled' check (status in ('scheduled', 'swapped', 'cancelled')),
  created_by uuid not null references users(id)
);


-- ============================================================
-- SWAP REQUESTS
-- status: pending | accepted | rejected | expired | cancelled
-- ============================================================
create table swap_requests (
  id uuid primary key default gen_random_uuid(),
  rota_shift_id uuid not null references rota_shifts(id) on delete cascade,
  requester_id uuid not null references users(id) on delete cascade,
  acceptor_id uuid references users(id),
  reason text,
  status text not null default 'pending' check (status in ('pending', 'accepted', 'rejected', 'expired', 'cancelled')),
  needs_approval boolean not null default false,
  approved_by uuid references users(id),
  created_at timestamptz not null default now(),
  resolved_at timestamptz
);


-- ============================================================
-- NOTIFICATIONS
-- type examples: rota_published | swap_offered | swap_accepted
--               swap_rejected  | adhoc_posted | swap_approval_needed
-- ============================================================
create table notifications (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references users(id) on delete cascade,
  type text not null,
  message text not null,
  metadata jsonb,
  read boolean not null default false,
  created_at timestamptz not null default now()
);


-- ============================================================
-- ROW LEVEL SECURITY
-- Locked down by default — users only see their own data.
-- Managers can see everything. Expand these policies as needed.
-- ============================================================

alter table users           enable row level security;
alter table user_roles      enable row level security;
alter table shift_templates enable row level security;
alter table fortnights      enable row level security;
alter table availability    enable row level security;
alter table rota_shifts     enable row level security;
alter table swap_requests   enable row level security;
alter table notifications   enable row level security;

-- Helper: is the current user a manager or admin?
create or replace function is_manager()
returns boolean as $$
  select exists (
    select 1 from users
    where id = auth.uid()
    and role in ('manager', 'admin')
  );
$$ language sql security definer;

-- users: see own row; managers see all
create policy "users_select_own" on users for select
  using (id = auth.uid() or is_manager());

create policy "users_update_own" on users for update
  using (id = auth.uid());

-- user_roles: see own; managers see all
create policy "user_roles_select" on user_roles for select
  using (user_id = auth.uid() or is_manager());

-- shift_templates: everyone can read
create policy "shift_templates_select" on shift_templates for select
  using (true);

create policy "shift_templates_manage" on shift_templates for all
  using (is_manager());

-- fortnights: everyone can read; managers manage
create policy "fortnights_select" on fortnights for select
  using (true);

create policy "fortnights_manage" on fortnights for all
  using (is_manager());

-- availability: own rows only; managers see all
create policy "availability_select" on availability for select
  using (user_id = auth.uid() or is_manager());

create policy "availability_insert" on availability for insert
  with check (user_id = auth.uid());

create policy "availability_update" on availability for update
  using (user_id = auth.uid());

-- rota_shifts: own rows; managers see/manage all
create policy "rota_shifts_select" on rota_shifts for select
  using (user_id = auth.uid() or is_manager());

create policy "rota_shifts_manage" on rota_shifts for all
  using (is_manager());

-- swap_requests: involved parties or managers
create policy "swap_requests_select" on swap_requests for select
  using (
    requester_id = auth.uid() or
    acceptor_id  = auth.uid() or
    is_manager()
  );

create policy "swap_requests_insert" on swap_requests for insert
  with check (requester_id = auth.uid());

create policy "swap_requests_update" on swap_requests for update
  using (
    requester_id = auth.uid() or
    acceptor_id  = auth.uid() or
    is_manager()
  );

-- notifications: own only
create policy "notifications_select" on notifications for select
  using (user_id = auth.uid());

create policy "notifications_update" on notifications for update
  using (user_id = auth.uid());