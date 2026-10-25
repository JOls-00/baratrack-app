# BaraTrack app (Flutter)

## Run locally
```
flutter run --dart-define=API_BASE_URL=http://10.0.2.2/barangay_api     # Android emulator + XAMPP
flutter run -d chrome --dart-define=API_BASE_URL=http://127.0.0.1/barangay_api
```
(Debug builds already default to those addresses if you pass nothing. Release builds REQUIRE the define and HTTPS.)

## One-time: create your release keystore (keep it safe, back it up, never commit it)
```
keytool -genkey -v -keystore upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
base64 -w0 upload-keystore.jks      # macOS: base64 -i upload-keystore.jks
```
If you lose this keystore you cannot update the app under the same signing key (Play App Signing can recover an upload key, a sideloaded APK cannot).

## GitHub settings (repo > Settings > Secrets and variables > Actions)
- Variable  `API_BASE_URL`      = https://YOUR-API.onrender.com
- Secret    `KEYSTORE_BASE64`   = output of the base64 command
- Secret    `KEYSTORE_PASSWORD`, `KEY_ALIAS` (upload), `KEY_PASSWORD`

Then: Actions > "Build Android release" > Run workflow. Download the APK from the run's Artifacts, or push a tag
(`git tag v1.0.0 && git push --tags`) to get the APK attached to a GitHub Release anyone can download.

## Application ID
Set to `com.baratrack.app` in `android/app/build.gradle.kts` (and `MainActivity.kt`). Change it now if you want
another one; after publishing on Google Play it can never change.

## Privacy policy
`docs/privacy-policy.html` is a DRAFT. Fill the [brackets], have the barangay / a lawyer review it, then publish it
free with GitHub Pages (Settings > Pages > deploy from /docs). Use that URL in Google Play.
