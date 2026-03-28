-- Run in Supabase SQL Editor after applying guest migration.
-- Expect: 2 rows under guest_rpcs; tag_write_secret listed under garments columns.

select
  p.proname as function_name,
  pg_get_function_identity_arguments(p.oid) as args
from pg_proc p
join pg_namespace n on p.pronamespace = n.oid
where n.nspname = 'public'
  and p.proname in (
    'guest_fetch_garment_memories',
    'guest_append_journal_entry'
  )
order by p.proname;

select column_name, data_type, is_nullable
from information_schema.columns
where table_schema = 'public'
  and table_name = 'garments'
  and column_name = 'tag_write_secret';
