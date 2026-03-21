# Echo Memories

iOS app that uses NFC chips (e.g. Timeskey NTAG215/216) sewn into clothing as a physical journal: tap a tag to open that garment’s journal, log when you wore it, and write memory entries. Data is stored locally and can sync to Supabase for backup.

## Requirements

- Xcode 15+ (for iOS 16+)
- iPhone with NFC (iPhone XS or newer for background tag reading)
- [XcodeGen](https://github.com/yonaskolb/XcodeGen) (optional; used to generate the Xcode project)

## Open and run the project

1. **Generate the Xcode project** (if you use XcodeGen):
   ```bash
   brew install xcodegen   # if needed
   xcodegen generate
   ```
   Or create a new iOS App in Xcode, add the `EchoMemories` folder as source, set the app’s **Info.plist** and **entitlements** (NFC + Sign in with Apple), and add the Supabase Swift package.

2. **Open** `EchoMemories.xcodeproj` in Xcode.

3. **Select your team** under Signing & Capabilities so the app can run on a device.

4. **Run on a physical iPhone** (NFC does not work in the simulator). Choose your device and press Run.

## Deploy for testing

Two ways to get the app onto your iPhone for testing.

**Prerequisites:** Physical iPhone (iPhone XS or newer for background NFC). For Option 1, a free Apple ID is enough; for Option 2 you need a paid [Apple Developer](https://developer.apple.com) account ($99/year). Ensure Xcode is the active developer directory (`xcode-select -s /Applications/Xcode.app/Contents/Developer` if needed).

### Option 1: Run from Xcode (no review, fastest)

Best for daily use on your own device.

1. Open `EchoMemories.xcodeproj` in Xcode (run `xcodegen generate` first if needed).
2. Connect your iPhone via USB and select it as the run destination in the toolbar.
3. Under **Signing & Capabilities**, select your **Team** (your Apple ID). If you see "Failed to register bundle identifier", change the **Bundle Identifier** in the project to something unique (e.g. `com.yourname.EchoMemories`).
4. Press **Run** (Cmd+R). Xcode builds and installs the app on the device.

With a **free Apple ID**, the app runs for about 7 days, then run again from Xcode to reinstall. With a **paid Developer account**, the app stays installed for up to 1 year before you need to run from Xcode again.

### Option 2: TestFlight (install over the air)

Best for installing without a cable or sharing with a few testers. Requires a paid Apple Developer account.

1. Enroll in the [Apple Developer Program](https://developer.apple.com) if you have not already.
2. In Xcode, set the project **Team** to your paid team and ensure the **Bundle ID** is unique.
3. **Archive:** Product → **Archive**. Wait for the archive to appear in the Organizer.
4. In the Organizer, select the archive and click **Distribute App**.
5. Choose **TestFlight & App Store** → **Upload** and follow the prompts (defaults are fine).
6. In [App Store Connect](https://appstoreconnect.apple.com), open your app → **TestFlight**. Wait for the build to finish **processing** (often 5–15 minutes). Apple runs a short beta app review.
7. Under **Internal Testing**, add yourself (and any other team members) as internal testers. They receive an email to install via the TestFlight app.
8. On your iPhone, install the **TestFlight** app from the App Store, accept the invite, and install Echo Memories from TestFlight.

Each new build requires a new Archive and Upload, then processing and review.

| Goal | Use |
|------|-----|
| Quick testing on your phone only | **Option 1** – Run from Xcode. |
| Install without cable or share with 1–2 people | **Option 2** – TestFlight (paid account). |

## Using the app

- **Add a garment**: Tap +, enter a name, then tap “Link NFC tag” and hold your phone to the tag. The app writes a link to the tag so future taps open this garment.
- **Tap a tag**: With the app in the background or closed, tap the tag. iOS shows a notification; tap it to open the app to that garment’s journal.
- **Add a memory**: On a garment’s screen, tap “Add memory”, choose the date you wore it, and write your entry.
- **Settings**: Sign in with Apple and sync when Supabase is configured (see below).
- **Photos**: Optional image per memory (requires sign-in and Supabase).
- **Public sharing**: Edit a garment to mark it public, host `web/share.html`, set `PUBLIC_SHARE_BASE_URL`, sync, then rewrite the NFC tag (see README Supabase section).

## Optional: Supabase sync

To back up and sync data across devices:

1. Create a [Supabase](https://supabase.com) project.

2. In the SQL Editor, run the schema and RLS from [supabase/schema.sql](supabase/schema.sql) (create tables, storage bucket, and RLS). If you created the project with an **older** schema (before public sharing / photos), also run [supabase/migration_public_share_and_photos.sql](supabase/migration_public_share_and_photos.sql) once (fix any “policy already exists” errors by dropping those policies first).

3. In Supabase: **Auth → Providers → Apple**, enable Sign in with Apple and set your app’s Bundle ID and Key.

4. **Configure Supabase keys (not committed to git):**
   - Copy [Config/Secrets.xcconfig.example](Config/Secrets.xcconfig.example) to `Config/Secrets.xcconfig` (this path is in `.gitignore`).
   - Fill in:
     - `SUPABASE_URL` — project URL (e.g. `https://xxxx.supabase.co`)
     - `SUPABASE_ANON_KEY` — anon/public key from **Project Settings → API**
     - `PUBLIC_SHARE_BASE_URL` (optional) — where you host [web/share.html](web/share.html), **no trailing slash**. Needed only for **public** NFC links in the browser.

   The target uses [Config/App.xcconfig](Config/App.xcconfig), which merges [Config/Defaults.xcconfig](Config/Defaults.xcconfig) with optional `Secrets.xcconfig` and injects values into **Info.plist** at build time.

5. In the app, open **Settings**, tap **Sign in with Apple**, then **Sync now**.

### TestFlight / Xcode Cloud

Archive uploads do not include `Secrets.xcconfig` (it stays local). To enable Supabase, Sign in with Apple, and **photo uploads** on builds from **Xcode Cloud**:

1. In [App Store Connect](https://appstoreconnect.apple.com) → your app → **Xcode Cloud** → **Manage Workflows** → edit the workflow → **Environment** → **Environment variables**, add:
   - `SUPABASE_URL` — your Supabase project URL (mark as **Secret** if offered)
   - `SUPABASE_ANON_KEY` — anon key (**Secret**)
   - `PUBLIC_SHARE_BASE_URL` — optional; same as above

2. The repo includes [ci_scripts/ci_post_clone.sh](ci_scripts/ci_post_clone.sh). Xcode Cloud runs it after clone; it writes `Config/Secrets.xcconfig` from those variables before the build.

3. Trigger a new build. Then **Sign in with Apple** on device; **Add memory** → **Photo** should show **Add photo**.

### Public page (anyone can scan)

1. Turn **Public memories page** on for a garment under **Edit garment**, then **Sync now** so `is_public` is stored in Supabase.
2. Host `web/share.html` at the same origin as `PUBLIC_SHARE_BASE_URL` (e.g. upload `share.html` so it is served at `{PUBLIC_SHARE_BASE_URL}/share.html`). Edit the file and set `SUPABASE_URL` and `SUPABASE_ANON_KEY` in the script (same values as the app; RLS only exposes rows marked public).
3. Tap **Write NFC tag with current link** on that garment. Public garments get an **HTTPS** URL on the tag so guests see the same memories in Safari; private garments keep the `echomemories://` app link.

### Photos on memories

After you sign in, **Add memory** / **Edit entry** lets you attach a photo. Images upload to the Supabase Storage bucket `entry-photos` and sync like other fields. The share page shows photos for public entries.

**Privacy:** public garments and their entries are readable by anyone with the link; only enable **Public** for garments you are comfortable exposing.

## Project structure

- `EchoMemories/` – app source
  - **Models**: `Garment`, `JournalEntry` (Codable, sync-friendly)
  - **Views**: garment list, garment detail, entry form, add garment, settings
  - **Services**: `LocalStore` (JSON on device), `NFCService` (read/write NDEF URL), `SyncService` (Supabase), `AuthService` (Sign in with Apple), `AppState` (deep link), `EntryPhotoUpload` (Storage)

## NFC tag format

Each tag stores a single NDEF URI record:

- **Private (default):** `echomemories://garment/<uuid>` — opens the Echo Memories app.
- **Public:** `https://…/share.html?id=<uuid>` — opens the hosted share page in a browser for anyone (configure `PUBLIC_SHARE_BASE_URL` and deploy [web/share.html](web/share.html)).

Compatible with Timeskey NTAG215/216 and other writable NDEF tags. Tags programmed with the old `clothjournal://` scheme must be re-linked with the app to update the URL.
