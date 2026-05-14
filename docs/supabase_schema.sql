-- TripGraph Supabase Schema
-- Run this in your Supabase project → SQL Editor

-- Enable PostGIS for geo queries (optional but recommended)
-- create extension if not exists postgis;

-- ─── Travel Cards ─────────────────────────────────────────────────────────────
create table if not exists public.travel_cards (
  id                  uuid primary key default gen_random_uuid(),
  user_id             uuid references auth.users(id) on delete cascade not null,
  title               text not null,
  description         text default '',
  origin_lat          double precision,
  origin_lng          double precision,
  origin_name         text,
  radius_meters       integer default 10000,
  status              text default 'draft' check (status in ('draft','active','completed')),
  selected_categories jsonb default '[]'::jsonb,
  discovered_places   jsonb default '[]'::jsonb,
  routes              jsonb default '[]'::jsonb,
  place_statuses      jsonb default '{}'::jsonb,
  created_at          timestamptz default now(),
  updated_at          timestamptz default now()
);

-- Row-level security: users can only see their own cards
alter table public.travel_cards enable row level security;

create policy "Users see own cards"
  on public.travel_cards for all
  using (auth.uid() = user_id);

-- Auto-update updated_at
create or replace function public.set_updated_at()
returns trigger language plpgsql as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

create trigger travel_cards_updated_at
  before update on public.travel_cards
  for each row execute function public.set_updated_at();

-- Index for fast user queries
create index if not exists travel_cards_user_id_idx
  on public.travel_cards (user_id, updated_at desc);
