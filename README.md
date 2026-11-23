# DuoDeen V2 (Supabase): setup

Your Supabase URL and publishable key are already in `lib/main.dart`.
The publishable key is safe in the app because your security rules (RLS) protect the data.
Never put the **secret** key in the app.

## 1. Supabase (one time, 2 minutes)
1. Open supabase.com → your project → **SQL Editor** → **New query**.
2. Open `supabase/fix.sql`, copy everything, paste it in, and click **Run**.
   This does NOT recreate your tables. It only:
   - adds the `tasbeeh_count` column
   - turns on Realtime (live sync)
   - adds safe pairing functions
3. **Authentication → Sign In / Providers → Email**: make sure **Confirm email** is OFF.

## 2. Upload to GitHub (replace the old version)
1. Open your `duodeen` repository → **Add file → Upload files**.
2. Drag in **everything** from this folder: `lib`, `tool`, `supabase`, `.github`, `pubspec.yaml`, `README.md`.
3. Click **Commit changes**.
4. **Actions** tab → wait for the green ✓ → open it → **Artifacts → DuoDeen-APK**.
5. Unzip it, send `app-release.apk` to your phone and install it.

## 3. Or run it on your computer (VS Code)
1. Put these files in your Flutter project folder (replace `lib` and `pubspec.yaml`).
2. In the terminal: `flutter pub get`
3. Connect your phone (USB debugging ON) and press **F5**.
   Note: if you build an APK on your own computer, add
   `<uses-permission android:name="android.permission.INTERNET"/>` to
   `android/app/src/main/AndroidManifest.xml`, or just run `python tool/patch_android.py` once.

## 4. Test that V2 works
1. You log in on your phone; your friend logs in on hers with a different email.
2. Profile icon (top right) → copy your pair code → your friend enters it → **Pair**.
3. You tick Fajr → your friend's phone updates within about 2 seconds.
4. Log out and log in again → your ticks are still there.
