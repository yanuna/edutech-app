import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/api_client.dart';
import '../api/api_endpoints.dart';
import '../models/app_notification.dart';

/// The notification inbox (admin broadcasts) + unread count. Refreshed on
/// pull-to-refresh and invalidated after marking read so the bell badge clears.
final notificationInboxProvider = FutureProvider<NotificationInbox>((ref) async {
  final res = await ApiClient.instance.get(ApiEndpoints.notifications);
  return NotificationInbox.fromJson((res.data as Map).cast<String, dynamic>());
});

/// Just the unread count for the home bell badge. Reuses the inbox fetch so we
/// don't hit the API twice; 0 while loading/erroring.
final unreadNotificationCountProvider = Provider<int>((ref) {
  return ref.watch(notificationInboxProvider).maybeWhen(
        data: (inbox) => inbox.unreadCount,
        orElse: () => 0,
      );
});

/// Marks every delivered notification as read, then refreshes the inbox.
Future<void> markNotificationsRead(WidgetRef ref) async {
  try {
    await ApiClient.instance.post(ApiEndpoints.notificationsRead);
  } catch (_) {
    // Non-fatal — the badge will simply re-appear on next load.
  }
  ref.invalidate(notificationInboxProvider);
}
