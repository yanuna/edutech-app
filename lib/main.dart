import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app.dart';
import 'core/services/ad_service.dart';
import 'core/services/notification_service.dart';
import 'firebase_options.dart';

void main() async {
  // runZonedGuarded catches async errors that escape the widget tree so they
  // reach Crashlytics instead of vanishing. Everything from binding init to
  // runApp must live inside the same zone.
  runZonedGuarded(
    () async {
      WidgetsFlutterBinding.ensureInitialized();

      // Initialize Firebase before anything else
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );

      // ── Crash reporting ────────────────────────────────────────────────────
      // Collect in release only; in debug, errors already surface in the console
      // and we don't want to pollute Crashlytics with dev noise.
      await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(
        !kDebugMode,
      );
      // Framework (build/layout/paint) errors → Crashlytics, plus the usual
      // red-screen dump in debug.
      FlutterError.onError = (details) {
        FlutterError.presentError(details);
        FirebaseCrashlytics.instance.recordFlutterFatalError(details);
      };
      // Uncaught errors from the platform/engine layer.
      PlatformDispatcher.instance.onError = (error, stack) {
        FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
        return true;
      };

      SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
      ]);

      SystemChrome.setSystemUIOverlayStyle(
        const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark,
          statusBarBrightness: Brightness.light,
        ),
      );

      runApp(const ProviderScope(child: EduTechApp()));

      // Set up notifications and ads off the critical path. These hit the network
      // (FCM topic sync, AdMob SDK) and can hang or fail — e.g. when Play Services
      // returns SERVICE_NOT_AVAILABLE — so they must never block the first frame,
      // or the user is left staring at a blank white screen.
      unawaited(NotificationService.instance.initialize());
      unawaited(AdService.instance.initialize());
    },
    (error, stack) =>
        FirebaseCrashlytics.instance.recordError(error, stack, fatal: true),
  );
}
