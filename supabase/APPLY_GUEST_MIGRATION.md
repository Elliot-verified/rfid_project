# Apply guest NFC / `?k=` migration to Supabase

The SQL is in the repo; **you** run it against **your** Supabase project (the assistant cannot sign in to your dashboard).

## Option A — SQL Editor (simplest)

1. Open [Supabase Dashboard](https://supabase.com/dashboard) → your project → **SQL Editor** → **New query**.
2. Open in this repo: [`migration_guest_tag_access.sql`](./migration_guest_tag_access.sql).
3. Copy the **entire** file, paste into the editor, click **Run**.
4. **`schema.sql`**, **`migration_public_share_and_photos.sql`**, and **`migration_guest_tag_access.sql`** now drop each policy before recreating it, so you can usually re-run the full file without `42710` errors. If you still hit a duplicate policy from older one-off SQL, drop that policy by name and re-run.

**Prerequisites:** Tables `garments` and `journal_entries` must already exist (from [`schema.sql`](./schema.sql) or earlier setup). If you never added public share / photos, run [`migration_public_share_and_photos.sql`](./migration_public_share_and_photos.sql) first when applicable.

## Option B — Supabase CLI

From the repo root (after `supabase link` to your project):

```bash
supabase db push
```

This applies pending files under [`migrations/`](./migrations/) (including `20260328120000_guest_tag_access.sql`).

## After SQL succeeds

- **Auth → Providers → Apple** — still required for owner Sign in with Apple in the iOS app.
- **Web:** Configure [`web/share.html`](../web/share.html) (see below) and deploy next to your `PUBLIC_SHARE_BASE_URL`.

## Verify RPCs

In **SQL Editor**, run [`verify_guest_rpcs.sql`](./verify_guest_rpcs.sql). You should see two function rows and `tag_write_secret` on `garments`.

## Web credentials (`share.html`)

1. Copy [`web/share-config.example.js`](../web/share-config.example.js) to `web/share-config.js` and set your project URL and anon key (same as the iOS app). `share-config.js` is gitignored.
2. Deploy **`share.html`**, **`share-config.js`**, and keep the Supabase JS CDN script as in the HTML.
3. Alternatively, edit the `YOUR_SUPABASE_*` placeholders directly in `share.html` (easier, but do not commit real keys to a public repo).

**Deploy:** Upload/host the `web/` assets on the origin you set as `PUBLIC_SHARE_BASE_URL` (e.g. Vercel with root `web`).
