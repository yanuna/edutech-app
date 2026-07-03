import 'dart:async';
import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// ── Background message handler (top-level function required by Firebase) ─────
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Firebase is already initialized at this point — no action needed here;
  // the notification is shown automatically by the system for data-only messages.
}

/// Handles FCM initialization, token management, and in-app notification display.
class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final _messaging = FirebaseMessaging.instance;
  final _localNotifications = FlutterLocalNotificationsPlugin();

  // Android notification channel — must match the channel_id in FcmService.php
  static const _channelId = 'edutech_main';
  static const _channelName = 'EduTech Notifications';

  // ── Initialize ────────────────────────────────────────────────────────────

  Future<void> initialize() async {
    // Register background handler before any async work
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // Request permission (iOS; Android 13+ also prompts)
    try {
      await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        announcement: false,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
      );
    } catch (_) {
      // Permission flow can fail when Play Services is unavailable — ignore.
    }

    // Set up local notifications for foreground display
    await _setupLocalNotifications();

    // Listen to foreground messages and show them as local notifications
    FirebaseMessaging.onMessage.listen(_onForegroundMessage);

    // Subscribe to the 'all_users' topic for admin broadcasts. This depends on
    // FCM reaching Google's servers and can hang/throw (SERVICE_NOT_AVAILABLE),
    // so it is fire-and-forget and never blocks initialization.
    unawaited(_messaging.subscribeToTopic('all_users').catchError((_) {}));
  }

  // ── Token Management ──────────────────────────────────────────────────────

  /// Returns the current FCM token, or null if not available.
  Future<String?> getToken() async {
    try {
      return await _messaging.getToken();
    } catch (_) {
      return null;
    }
  }

  /// Stream that emits every time the FCM token is refreshed.
  /// Call this on app start and upload the latest token to the backend.
  Stream<String> get onTokenRefresh => _messaging.onTokenRefresh;

  // ── Tap Handling ──────────────────────────────────────────────────────────

  /// Returns the RemoteMessage that launched the app from a terminated state, if any.
  Future<RemoteMessage?> getInitialMessage() => _messaging.getInitialMessage();

  /// Stream for notification taps when the app is in the background (not terminated).
  Stream<RemoteMessage> get onMessageOpenedApp =>
      FirebaseMessaging.onMessageOpenedApp;

  // ── Local Notifications ───────────────────────────────────────────────────

  Future<void> _setupLocalNotifications() async {
    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    await _localNotifications.initialize(
      const InitializationSettings(android: androidSettings, iOS: iosSettings),
    );

    // Create the Android notification channel
    if (Platform.isAndroid) {
      await _localNotifications
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.createNotificationChannel(
            const AndroidNotificationChannel(
              _channelId,
              _channelName,
              importance: Importance.high,
              enableVibration: true,
            ),
          );
    }
  }

  void _onForegroundMessage(RemoteMessage message) {
    final notification = message.notification;
    if (notification == null) return;

    _localNotifications.show(
      notification.hashCode,
      notification.title,
      notification.body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: const DarwinNotificationDetails(),
      ),
    );
  }
}

// ── Provider ──────────────────────────────────────────────────────────────────

final notificationServiceProvider = Provider<NotificationService>(
  (_) => NotificationService.instance,
);
