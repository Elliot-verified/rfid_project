-- Guest NFC / share URL (?k=) — mirrors migration_guest_tag_access.sql for Supabase CLI: supabase db push
-- See supabase/APPLY_GUEST_MIGRATION.md

alter table public.garments
  add column if not exists tag_write_secret text;

comment on column public.garments.tag_write_secret is
  'If set, share URL must include ?k=<same value> for guest_fetch / guest_append. Regenerate in app to revoke old links.';

alter table public.journal_entries
  add column if not exists is_guest boolean not null default false;

alter table public.journal_entries
  add column if not exists guest_label text;

alter table public.journal_entries
  alter column user_id drop not null;

comment on column public.journal_entries.is_guest is 'True when row was created via guest_append_journal_entry RPC.';
comment on column public.journal_entries.guest_label is 'Optional display name from guest (web form).';

drop policy if exists "Users can manage own journal_entries" on public.journal_entries;
drop policy if exists "journal_entries_select_authenticated" on public.journal_entries;
drop policy if exists "journal_entries_insert_authenticated" on public.journal_entries;
drop policy if exists "journal_entries_update_authenticated" on public.journal_entries;
drop policy if exists "journal_entries_delete_authenticated" on public.journal_entries;

create policy "journal_entries_select_authenticated"
  on public.journal_entries for select
  to authenticated
  using (
    (user_id is not null and auth.uid() = user_id)
    or exists (
      select 1 from public.garments g
      where g.id = journal_entries.garment_id and g.user_id = auth.uid()
    )
  );

create policy "journal_entries_insert_authenticated"
  on public.journal_entries for insert
  to authenticated
  with check (
    user_id is not null
    and auth.uid() = user_id
    and exists (
      select 1 from public.garments g
      where g.id = journal_entries.garment_id and g.user_id = auth.uid()
    )
  );

create policy "journal_entries_update_authenticated"
  on public.journal_entries for update
  to authenticated
  using (
    (user_id is not null and auth.uid() = user_id)
    or exists (
      select 1 from public.garments g
      where g.id = journal_entries.garment_id and g.user_id = auth.uid()
    )
  )
  with check (
    (user_id is not null and auth.uid() = user_id)
    or exists (
      select 1 from public.garments g
      where g.id = journal_entries.garment_id and g.user_id = auth.uid()
    )
  );

create policy "journal_entries_delete_authenticated"
  on public.journal_entries for delete
  to authenticated
  using (
    (user_id is not null and auth.uid() = user_id)
    or exists (
      select 1 from public.garments g
      where g.id = journal_entries.garment_id and g.user_id = auth.uid()
    )
  );

create or replace function public.guest_fetch_garment_memories(p_garment_id uuid, p_secret text)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  sec text;
begin
  select tag_write_secret into sec
  from public.garments
  where id = p_garment_id;

  if sec is null or sec is distinct from p_secret then
    return null;
  end if;

  return jsonb_build_object(
    'garment',
    (
      select jsonb_build_object('id', id, 'name', name, 'is_public', is_public)
      from public.garments
      where id = p_garment_id
    ),
    'entries',
    coalesce(
      (
        select jsonb_agg(to_jsonb(x) order by x.worn_date desc)
        from (
          select
            id,
            garment_id,
            worn_date,
            content,
            mood,
            photo_storage_path,
            created_at,
            is_guest,
            guest_label
          from public.journal_entries
          where garment_id = p_garment_id
        ) x
      ),
      '[]'::jsonb
    )
  );
end;
$$;

revoke all on function public.guest_fetch_garment_memories(uuid, text) from public;
grant execute on function public.guest_fetch_garment_memories(uuid, text) to anon, authenticated;

create or replace function public.guest_append_journal_entry(
  p_garment_id uuid,
  p_secret text,
  p_content text,
  p_worn_date date default (timezone('utc', now()))::date,
  p_mood text default null,
  p_guest_label text default null
)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  sec text;
  new_id uuid;
begin
  if p_content is null or length(trim(p_content)) = 0 then
    raise exception 'content required';
  end if;

  select tag_write_secret into sec
  from public.garments
  where id = p_garment_id;

  if sec is null or sec is distinct from p_secret then
    raise exception 'invalid garment or access';
  end if;

  insert into public.journal_entries (
    garment_id,
    worn_date,
    content,
    mood,
    user_id,
    is_guest,
    guest_label
  )
  values (
    p_garment_id,
    p_worn_date,
    trim(p_content),
    nullif(trim(p_mood), ''),
    null,
    true,
    nullif(trim(p_guest_label), '')
  )
  returning id into new_id;

  return new_id;
end;
$$;

revoke all on function public.guest_append_journal_entry(uuid, text, text, date, text, text) from public;
grant execute on function public.guest_append_journal_entry(uuid, text, text, date, text, text) to anon, authenticated;

drop policy if exists "Anon can upload guest entry photos" on storage.objects;

create policy "Anon can upload guest entry photos"
  on storage.objects for insert
  to anon
  with check (
    bucket_id = 'entry-photos'
    and (storage.foldername(name))[1] = 'guest'
    and exists (
      select 1 from public.garments g
      where g.id::text = (storage.foldername(name))[2]
        and g.tag_write_secret is not null
    )
  );
