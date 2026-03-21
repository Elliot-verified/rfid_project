-- Echo Memories: garments and journal_entries with RLS
-- Run this in the Supabase SQL Editor after creating a project.

-- Garments (one per NFC-tagged clothing item)
create table if not exists public.garments (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  tag_payload text,
  tag_uid text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  image_file_name text,
  user_id uuid references auth.users(id) on delete cascade
);

-- Journal entries (memories per garment)
create table if not exists public.journal_entries (
  id uuid primary key default gen_random_uuid(),
  garment_id uuid not null references public.garments(id) on delete cascade,
  worn_date date not null,
  content text not null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  mood text,
  location text,
  user_id uuid references auth.users(id) on delete cascade
);

-- RLS: users can only see and modify their own rows
alter table public.garments enable row level security;
alter table public.journal_entries enable row level security;

create policy "Users can manage own garments"
  on public.garments for all
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

create policy "Users can manage own journal_entries"
  on public.journal_entries for all
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

-- Optional: indexes for common queries
create index if not exists garments_user_id_idx on public.garments(user_id);
create index if not exists journal_entries_user_id_idx on public.journal_entries(user_id);
create index if not exists journal_entries_garment_id_idx on public.journal_entries(garment_id);
