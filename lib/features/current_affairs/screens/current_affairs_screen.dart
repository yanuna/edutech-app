import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/providers/article_provider.dart';
import '../../learn/screens/articles_list_screen.dart' show ArticleCardTile;

/// Structured Current Affairs — daily / weekly / monthly editorial-style pieces
/// (Articles with type=current_affairs). Opens in the premium article reader.
/// The RSS news feed remains reachable via the top-right action.
class CurrentAffairsScreen extends ConsumerStatefulWidget {
  const CurrentAffairsScreen({super.key});

  @override
  ConsumerState<CurrentAffairsScreen> createState() => _CurrentAffairsScreenState();
}

class _CurrentAffairsScreenState extends ConsumerState<CurrentAffairsScreen> {
  static const _periods = ['daily', 'weekly', 'monthly'];
  static const _labels = {'daily': 'Daily', 'weekly': 'Weekly', 'monthly': 'Monthly'};
  String _period = 'daily';

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(currentAffairsProvider(_period));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Current Affairs'),
        actions: [
          IconButton(
            tooltip: 'News feed',
            icon: const Icon(Icons.rss_feed_rounded),
            onPressed: () => context.push('/news'),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(52),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
            child: SegmentedButton<String>(
              segments: [for (final p in _periods) ButtonSegment(value: p, label: Text(_labels[p]!))],
              selected: {_period},
              onSelectionChanged: (s) => setState(() => _period = s.first),
              showSelectedIcon: false,
            ),
          ),
        ),
      ),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => _Message(
          icon: Icons.wifi_off_rounded,
          title: 'Could not load current affairs',
          subtitle: 'Check your connection and try again.',
          onRetry: () => ref.invalidate(currentAffairsProvider(_period)),
        ),
        data: (items) => items.isEmpty
            ? _Message(
                icon: Icons.event_note_outlined,
                title: 'Nothing for this ${_labels[_period]!.toLowerCase()} view',
                subtitle: 'New current-affairs pieces will appear here as they are published.',
              )
            : RefreshIndicator(
                onRefresh: () async => ref.invalidate(currentAffairsProvider(_period)),
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: items.length,
                  itemBuilder: (_, i) => ArticleCardTile(card: items[i]),
                ),
              ),
      ),
    );
  }
}

class _Message extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onRetry;
  const _Message({required this.icon, required this.title, required this.subtitle, this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 46, color: Colors.grey.shade400),
            const SizedBox(height: 14),
            Text(title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700), textAlign: TextAlign.center),
            const SizedBox(height: 6),
            Text(subtitle, textAlign: TextAlign.center, style: TextStyle(color: Colors.grey.shade600)),
            if (onRetry != null) ...[
              const SizedBox(height: 16),
              FilledButton.tonal(onPressed: onRetry, child: const Text('Retry')),
            ],
          ],
        ),
      ),
    );
  }
}
