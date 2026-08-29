import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app.dart';
import 'core/services/ad_service.dart';
import 'core/services/notification_service.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Firebase powers push notifications only — it is not required to run the
  // app. This await used to be unguarded, so on iOS (where firebase_options.dart
  // still holds REPLACE_WITH_… placeholders) FIRApp threw, runApp() was never
  // reached, and every launch showed a blank screen. Degrade to "no push"
  // instead of "no app".
  try {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  } catch (e, st) {
    debugPrint('Firebase init failed — push notifications disabled: $e');
    debugPrintStack(stackTrace: st);
  }

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
}
