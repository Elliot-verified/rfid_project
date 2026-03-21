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
  is_public boolean not null default false,
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
  photo_storage_path text,
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

-- Public share page / NFC HTTPS URL: anyone may read rows marked public
create policy "Anyone can read public garments"
  on public.garments for select
  to anon, authenticated
  using (is_public = true);

create policy "Anyone can read entries for public garments"
  on public.journal_entries for select
  to anon, authenticated
  using (
    exists (
      select 1 from public.garments g
      where g.id = journal_entries.garment_id and g.is_public = true
    )
  );

-- Storage for memory photos (see migration_public_share_and_photos.sql if bucket already exists)
insert into storage.buckets (id, name, public)
values ('entry-photos', 'entry-photos', true)
on conflict (id) do nothing;

create policy "Users can upload entry photos"
  on storage.objects for insert
  to authenticated
  with check (
    bucket_id = 'entry-photos'
    and (storage.foldername(name))[1] = auth.uid()::text
  );

create policy "Users can update own entry photos"
  on storage.objects for update
  to authenticated
  using (
    bucket_id = 'entry-photos'
    and (storage.foldername(name))[1] = auth.uid()::text
  );

create policy "Users can delete own entry photos"
  on storage.objects for delete
  to authenticated
  using (
    bucket_id = 'entry-photos'
    and (storage.foldername(name))[1] = auth.uid()::text
  );

create policy "Anyone can read entry photos"
  on storage.objects for select
  to anon, authenticated
  using (bucket_id = 'entry-photos');

-- Optional: indexes for common queries
create index if not exists garments_user_id_idx on public.garments(user_id);
create index if not exists journal_entries_user_id_idx on public.journal_entries(user_id);
create index if not exists journal_entries_garment_id_idx on public.journal_entries(garment_id);
