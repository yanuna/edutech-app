import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/models/app_notification.dart';
import '../../../core/providers/notifications_provider.dart';

/// The notification inbox (bell icon) — admin broadcasts. Opening the screen
/// marks everything read so the home badge clears. Tapping an item follows its
/// deep-link (article / app screen / web link).
class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  bool _markedRead = false;

  @override
  void initState() {
    super.initState();
    // Clear the unread badge once the inbox has loaded.
    WidgetsBinding.instance.addPostFrameCallback((_) => _markReadOnce());
  }

  void _markReadOnce() {
    if (_markedRead) return;
    _markedRead = true;
    markNotificationsRead(ref);
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(notificationInboxProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Notifications')),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => _Empty(
          icon: Icons.wifi_off_rounded,
          title: 'Could not load notifications',
          subtitle: 'Check your connection and try again.',
          onRetry: () => ref.invalidate(notificationInboxProvider),
        ),
        data: (inbox) => inbox.items.isEmpty
            ? const _Empty(
                icon: Icons.notifications_none_rounded,
                title: 'No notifications yet',
                subtitle: 'Announcements and updates will show up here.',
              )
            : RefreshIndicator(
                onRefresh: () async => ref.invalidate(notificationInboxProvider),
                child: ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: inbox.items.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (_, i) => _NotificationCard(
                    item: inbox.items[i],
                    onTap: () => _handleTap(inbox.items[i]),
                  ),
                ),
              ),
      ),
    );
  }

  Future<void> _handleTap(AppNotification n) async {
    switch (n.actionType) {
      case 'article':
        if (n.actionValue != null && n.actionValue!.isNotEmpty) {
          context.push('/learn/article/${n.actionValue}');
        }
      case 'screen':
        if (n.actionValue != null && n.actionValue!.startsWith('/')) {
          context.push(n.actionValue!);
        }
      case 'url':
        final url = n.actionValue;
        if (url != null && url.isNotEmpty) {
          final uri = Uri.tryParse(url);
          if (uri != null) {
            await launchUrl(uri, mode: LaunchMode.externalApplication);
          }
        }
      default:
        break; // 'none' — no navigation
    }
  }
}

class _NotificationCard extends StatelessWidget {
  final AppNotification item;
  final VoidCallback onTap;
  const _NotificationCard({required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final hasAction = item.actionType != 'none';
    return InkWell(
      onTap: hasAction ? onTap : null,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: item.isRead ? null : const Color(0xFFEEF2FF),
          border: Border.all(color: Theme.of(context).dividerColor.withValues(alpha: .5)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (item.imageUrl != null) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.network(item.imageUrl!, width: double.infinity, height: 150, fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => const SizedBox.shrink()),
              ),
              const SizedBox(height: 12),
            ],
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (!item.isRead)
                  Container(
                    margin: const EdgeInsets.only(top: 5, right: 8),
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(color: Color(0xFF4F46E5), shape: BoxShape.circle),
                  ),
                Expanded(
                  child: Text(item.title,
                      style: const TextStyle(fontFamily: 'Poppins', fontSize: 15.5, fontWeight: FontWeight.w700)),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(item.body, style: TextStyle(fontSize: 13.5, height: 1.35, color: Colors.grey.shade700)),
            const SizedBox(height: 10),
            Row(
              children: [
                Text(_relativeTime(item.sentAt), style: TextStyle(fontSize: 11.5, color: Colors.grey.shade500)),
                if (hasAction) ...[
                  const Spacer(),
                  const Text('Open', style: TextStyle(fontSize: 12.5, color: Color(0xFF4F46E5), fontWeight: FontWeight.w600)),
                  const Icon(Icons.chevron_right_rounded, size: 18, color: Color(0xFF4F46E5)),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  static String _relativeTime(DateTime? dt) {
    if (dt == null) return '';
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${dt.day}/${dt.month}/${dt.year}';
  }
}

class _Empty extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onRetry;
  const _Empty({required this.icon, required this.title, required this.subtitle, this.onRetry});

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(icon, size: 46, color: Colors.grey.shade400),
            const SizedBox(height: 14),
            Text(title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700), textAlign: TextAlign.center),
            const SizedBox(height: 6),
            Text(subtitle, textAlign: TextAlign.center, style: TextStyle(color: Colors.grey.shade600)),
            if (onRetry != null) ...[
              const SizedBox(height: 16),
              FilledButton.tonal(onPressed: onRetry, child: const Text('Retry')),
            ],
          ]),
        ),
      );
}
