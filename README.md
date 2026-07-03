# EduTech — Learn, Practice, Excel

The official **VisionUPSC** mobile app (Android & iOS) — a Flutter client for the
[edutech backend](https://github.com/yanuna/edutech-backend) that powers
[www.visionupsc.in](https://www.visionupsc.in). UPSC aspirants get study material,
practice, mock test series, previous-year papers, current affairs, and government-job
alerts in one app.

> Private repository. Package `edutech_app`, version `1.0.0+1`.

## Features

- **Auth** — email/password, Google & Facebook sign-in, single-session enforcement
- **Study material** — bilingual (EN/HI) notes with rich HTML/LaTeX content
- **Exam engine** — MCQ practice + timed mock **test series** with ranking
- **PYQs** — year-wise previous-year papers (Prelims / Mains / Optional), view-only
  secure viewer with **AES-256 encrypted offline** saving
- **Current affairs / news** and **government-job** alerts
- **Subscriptions** — Razorpay + redirect gateways (Paytm/PayU/Atom via WebView)
- **Gamification**, push notifications (FCM), and in-app ads

## Tech stack

| Concern        | Choice                                             |
| -------------- | -------------------------------------------------- |
| State          | Flutter Riverpod (`StateNotifierProvider`)         |
| Navigation     | GoRouter (`StatefulShellRoute` for bottom nav)     |
| Networking     | Dio (auth interceptor attaches the bearer token)   |
| Secure storage | `flutter_secure_storage` (Keystore / Keychain)     |
| Content        | `flutter_widget_from_html`, KaTeX-rendered math    |
| PDF security   | `pdfx` viewer + `encrypt` (AES-256) + `path_provider` |
| Push / Ads     | `firebase_messaging`, `google_mobile_ads`          |
| UI             | Material 3, Indigo/Violet theme, Poppins font      |

## Project structure

```
lib/
├── main.dart                 # entry, portrait-lock, system UI
├── app.dart                  # GoRouter + root app widget
├── core/
│   ├── api/                  # api_client.dart (Dio), api_endpoints.dart
│   ├── models/               # user, catalog, exam, subscription, pyq, …
│   ├── providers/            # Riverpod providers (auth, catalog, exam, pyq, …)
│   └── services/             # secure_file_store, pyq_service, notifications, …
├── features/                 # auth, catalog, exam, test_series, pyq, news,
│                             #   govt_jobs, subscription, gamification, home, profile
└── shared/widgets/           # secure_pdf_viewer, rich_content_view, …
```

## Getting started

**Prerequisites:** Flutter SDK `^3.12.2` (Dart 3.12+), Android SDK / Xcode, and a
running [backend](https://github.com/yanuna/edutech-backend) for local development.

```bash
flutter pub get
```

### Run

Release builds automatically target production (`https://visionupsc.in/api`).
Debug builds hit a local backend — because a laptop's LAN IP changes between
networks, pass it at launch instead of editing code:

```bash
# Against a local backend on your machine (Android emulator uses 10.0.2.2)
flutter run --dart-define=API_BASE_URL=http://<your-LAN-IP>:8000/api

# Against production
flutter run --dart-define=API_BASE_URL=https://www.visionupsc.in/api
```

See `lib/core/api/api_endpoints.dart` for the base-URL logic.

### Build

```bash
flutter build apk --release        # Android APK
flutter build appbundle --release  # Android App Bundle (Play Store)
flutter build ios --release        # iOS (needs a signed Apple provisioning profile)
```

## Content protection

Premium PDFs (PYQs) are **view-only**: rendered as images (no text layer, no
share/print), Android screen capture is blocked via `FLAG_SECURE`, iOS covers the
app in the switcher / during recording, and any offline copy is stored
**AES-256-encrypted** in the app's private sandbox with the key held in the OS
keystore. Plaintext PDF bytes only ever live in memory. (Still-image screenshots
on iOS cannot be blocked by design — deterrence only.)

## Configuration notes

- **Firebase:** `android/app/google-services.json` is committed (client config).
  Register the app's SHA-1/SHA-256 in the Firebase console for Google Sign-In.
- **Signing:** the Android release build currently uses the debug signing config.
  Add a real release keystore + `key.properties` (git-ignored) before a store release.
- Live API keys (payments, OAuth, SMS) are managed server-side in the admin panel,
  not in the app.
