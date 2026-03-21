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

## Optional: Supabase sync

To back up and sync data across devices:

1. Create a [Supabase](https://supabase.com) project.

2. In the SQL Editor, run the schema and RLS from [supabase/schema.sql](supabase/schema.sql) (create tables and enable RLS).

3. In Supabase: **Auth → Providers → Apple**, enable Sign in with Apple and set your app’s Bundle ID and Key.

4. In Xcode, add your project URL and anon key to **Info.plist**:
   - `SUPABASE_URL`: your project URL (e.g. `https://xxxx.supabase.co`)
   - `SUPABASE_ANON_KEY`: the anon/public key from Project Settings → API

5. In the app, open **Settings**, tap **Sign in with Apple**, then **Sync now**.

## Project structure

- `EchoMemories/` – app source
  - **Models**: `Garment`, `JournalEntry` (Codable, sync-friendly)
  - **Views**: garment list, garment detail, entry form, add garment, settings
  - **Services**: `LocalStore` (JSON on device), `NFCService` (read/write NDEF URL), `SyncService` (Supabase), `AuthService` (Sign in with Apple), `AppState` (deep link)

## NFC tag format

Each tag stores a single NDEF URI record: `echomemories://garment/<uuid>`. That URL is written when you link a tag to a garment. Compatible with Timeskey NTAG215/216 and any writable NDEF tag. Tags programmed with the old `clothjournal://` scheme must be re-linked with the app to update the URL.
