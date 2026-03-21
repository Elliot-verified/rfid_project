-- Run in Supabase SQL Editor after the base schema (schema.sql).
-- Enables: (1) public read for garments marked is_public, (2) entry photos in Storage.

-- --- Tables ---
alter table public.garments
  add column if not exists is_public boolean not null default false;

alter table public.journal_entries
  add column if not exists photo_storage_path text;

-- --- RLS: anonymous read for public garments and their entries ---
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

-- --- Storage bucket for memory photos (public read, authenticated write) ---
insert into storage.buckets (id, name, public)
values ('entry-photos', 'entry-photos', true)
on conflict (id) do update set public = excluded.public;

-- Authenticated users can upload/update/delete only under their user_id prefix
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

-- Public bucket: anyone can read objects (required for share page / AsyncImage)
create policy "Anyone can read entry photos"
  on storage.objects for select
  to anon, authenticated
  using (bucket_id = 'entry-photos');
