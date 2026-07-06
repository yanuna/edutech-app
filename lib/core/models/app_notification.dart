/// A broadcast notification from the admin panel, shown in the app's inbox.
class AppNotification {
  final int id;
  final String title;
  final String body;
  final String? imageUrl;
  final String actionType; // none | article | url | screen
  final String? actionValue;
  final DateTime? sentAt;
  final bool isRead;

  const AppNotification({
    required this.id,
    required this.title,
    required this.body,
    this.imageUrl,
    this.actionType = 'none',
    this.actionValue,
    this.sentAt,
    this.isRead = false,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: (json['id'] as num).toInt(),
      title: json['title']?.toString() ?? '',
      body: json['body']?.toString() ?? '',
      imageUrl: json['image_url']?.toString(),
      actionType: json['action_type']?.toString() ?? 'none',
      actionValue: json['action_value']?.toString(),
      sentAt: DateTime.tryParse(json['sent_at']?.toString() ?? ''),
      isRead: json['is_read'] == true,
    );
  }
}

/// The inbox payload: the list plus the unread badge count.
class NotificationInbox {
  final int unreadCount;
  final List<AppNotification> items;
  const NotificationInbox({this.unreadCount = 0, this.items = const []});

  factory NotificationInbox.fromJson(Map<String, dynamic> json) {
    return NotificationInbox(
      unreadCount: (json['unread_count'] as num?)?.toInt() ?? 0,
      items: ((json['notifications'] as List?) ?? const [])
          .map((e) => AppNotification.fromJson((e as Map).cast<String, dynamic>()))
          .toList(),
    );
  }
}
