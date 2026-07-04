# Running the app (Android Studio)

Quick guide to run and develop the EduTech / VisionUPSC Flutter app locally.

## Prerequisites (already ✓ on this machine)
- Flutter 3.44+ (`flutter --version`)
- Android SDK + Xcode
- Android Studio with the **Flutter** and **Dart** plugins
  (Settings → Plugins → search "Flutter" → Install → restart)

## 1. Open the project
Android Studio → **File → Open** → select this folder
(`/Users/anunay/Developer/edutech_app_new`). Trust the project if asked.

## 2. Get dependencies
Click the **Pub get** banner, or run in the terminal:
```bash
flutter pub get
```

## 3. Create an Android emulator (first time only)
Android Studio → **Device Manager** (right sidebar) → **Create Device** →
pick e.g. *Pixel 7* → choose a system image (API 34/35 — click **Download**
next to it, ~1 GB) → **Finish** → press ▶ to boot it.

> The CLI can't create one until a system image is installed; the Device
> Manager downloads it for you.

You can also run on a **real phone**: enable *Developer options → USB
debugging*, plug it in, and it appears in the device dropdown.

## 4. Point the app at the live backend  ⚠️ important
In **debug** mode the app defaults to a dev LAN IP and will show
"connection failed". Pass the real API URL:

**In Android Studio** — Run config dropdown → *Edit Configurations…* →
**Additional run args**:
```
--dart-define=API_BASE_URL=https://www.visionupsc.in/api
```

**Or from the terminal:**
```bash
flutter run --dart-define=API_BASE_URL=https://www.visionupsc.in/api
```

(Release builds hit production automatically and need no flag.)

## 5. Run
Select the emulator/phone in the device dropdown → press ▶.
- **Hot reload:** save a file, or click ⚡
- **Hot restart:** the ↻ button

## Project layout
```
lib/
├── main.dart             entry point
├── app.dart              GoRouter routes + bottom navigation
├── core/
│   ├── api/              api_client.dart, api_endpoints.dart
│   ├── models/           user, article, catalog, exam, pyq, subscription…
│   ├── providers/        Riverpod providers (auth, article, search, catalog…)
│   └── services/         secure_file_store, article_interaction, notifications…
└── features/             home, learn, practice, current_affairs, search,
                          revision, progress, books, entities, pyq, exam,
                          test_series, news, govt_jobs, subscription, profile, auth
```

## Git
Already connected to GitHub (`yanuna/edutech-app`, branch `main`).
```bash
git pull
# …edit…
git add -A && git commit -m "message"
git push
```

## Build outputs
```bash
flutter build apk --debug        # test APK
flutter build apk --release      # (needs a signing keystore for the store)
flutter build appbundle --release
```

## Known harmless warning
A KGP deprecation warning about `pdfx / share_plus / wakelock_plus` prints on
build. It's only a warning — the app builds and runs.
