import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/article.dart';
import '../../../core/services/article_interaction_service.dart';
import 'articles_list_screen.dart' show ArticleCardTile;

/// The user's saved (bookmarked) articles — the first surface of the Revision
/// Hub. Backed by the Module-4 bookmarks API.
final _savedArticlesProvider = FutureProvider.autoDispose<List<ArticleCard>>((ref) async {
  return ArticleInteractionService.savedArticles();
});

class SavedArticlesScreen extends ConsumerWidget {
  const SavedArticlesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(_savedArticlesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Saved')),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => _Empty(
          icon: Icons.wifi_off_rounded,
          title: 'Could not load saved items',
          subtitle: 'Check your connection and try again.',
          onRetry: () => ref.invalidate(_savedArticlesProvider),
        ),
        data: (items) => items.isEmpty
            ? const _Empty(
                icon: Icons.bookmark_border_rounded,
                title: 'Nothing saved yet',
                subtitle: 'Tap the bookmark icon while reading an article to save it here.',
              )
            : RefreshIndicator(
                onRefresh: () async => ref.invalidate(_savedArticlesProvider),
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

class _Empty extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onRetry;
  const _Empty({required this.icon, required this.title, required this.subtitle, this.onRetry});

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
            Text(title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
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
