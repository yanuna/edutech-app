# Release Guide (Android)

How to produce a signed, production-ready build and what must be set before
submitting to the Play Store.

## 1. Create the upload keystore (one time)

```bash
keytool -genkey -v -keystore ~/edutech-upload.jks \
  -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```

Store the `.jks` and its passwords somewhere safe (a password manager). **If you
lose the upload key you can no longer update the app** — recovery requires Play
App Signing key reset support from Google.

## 2. Configure signing

Copy the template and fill in real values:

```bash
cp android/key.properties.example android/key.properties
```

```properties
storePassword=...
keyPassword=...
keyAlias=upload
storeFile=/absolute/path/to/edutech-upload.jks
```

`android/key.properties` and any `.jks`/`.keystore` are gitignored — never commit
them. When the file is absent (fresh clone / CI without the secret) the release
build falls back to debug signing so it still compiles.

## 3. Build

```bash
# App bundle for the Play Store (preferred), with Dart obfuscation:
flutter build appbundle --release \
  --obfuscate --split-debug-info=build/symbols

# Or an APK for sideload/testing:
flutter build apk --release \
  --obfuscate --split-debug-info=build/symbols
```

`--split-debug-info` writes the symbol files that de-obfuscate Dart stack traces.
Keep the `build/symbols` directory for each release so Crashlytics reports stay
readable. Release builds already run R8 (code shrink + obfuscation) and resource
shrinking; rules live in `android/app/proguard-rules.pro`.

## 4. Before store submission — checklist

- [ ] **AdMob app ID**: `AndroidManifest.xml` still uses Google's TEST app ID
      (`ca-app-pub-3940256099942544~3347511713`). Replace with the real AdMob app
      ID. Real ad *unit* IDs come from the backend `/ads-config` at runtime.
- [ ] **Production API**: confirm `https://visionupsc.in/api` in
      `lib/core/api/api_endpoints.dart` is the live domain.
- [ ] **Facebook Login**: set real `facebook_app_id` / `facebook_client_token` in
      `android/app/src/main/res/values/strings.xml`.
- [ ] **Version bump**: increment `version:` in `pubspec.yaml` (e.g. `1.0.1+2`)
      for every upload — Play rejects duplicate `versionCode`s.
- [ ] **App icons**: verify `@mipmap/ic_launcher` is the final brand icon, not a
      placeholder.
- [ ] **Crashlytics**: trigger a test crash once and confirm it appears in the
      Firebase console.
- [ ] **Data safety / privacy policy**: complete the Play Console Data Safety
      form (the app collects account info + uses ads).

## Notes

- Cleartext HTTP is allowed in **debug only** (local backend); the release build
  blocks it via a manifest placeholder in `android/app/build.gradle.kts`.
- Network request logging (`LogInterceptor`) is compiled out of release builds.
