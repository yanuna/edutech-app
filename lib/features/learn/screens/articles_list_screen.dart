import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/models/article.dart';
import '../../../core/providers/article_provider.dart';

/// Lists article cards for a subject (or any [ArticleQuery]). Tapping opens the
/// premium reader.
class ArticlesListScreen extends ConsumerWidget {
  final int subjectId;
  final String subjectName;
  const ArticlesListScreen({super.key, required this.subjectId, required this.subjectName});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final query = ArticleQuery(subjectId: subjectId);
    final async = ref.watch(articleListProvider(query));

    return Scaffold(
      appBar: AppBar(title: Text(subjectName.isEmpty ? 'Articles' : subjectName)),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => _Message(
          icon: Icons.wifi_off_rounded,
          title: 'Could not load articles',
          subtitle: 'Check your connection and try again.',
          onRetry: () => ref.invalidate(articleListProvider(query)),
        ),
        data: (articles) => articles.isEmpty
            ? const _Message(icon: Icons.article_outlined, title: 'No articles yet', subtitle: 'Articles for this subject will appear here.')
            : RefreshIndicator(
                onRefresh: () async => ref.invalidate(articleListProvider(query)),
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: articles.length,
                  itemBuilder: (_, i) => ArticleCardTile(card: articles[i]),
                ),
              ),
      ),
    );
  }
}

/// Reusable article card — used in the list, Learn hub, and (later) Home.
class ArticleCardTile extends StatelessWidget {
  final ArticleCard card;
  const ArticleCardTile({super.key, required this.card});

  Color _difficultyColor() => switch (card.difficulty) {
    'easy' => const Color(0xFF10B981),
    'hard' => const Color(0xFFEF4444),
    _ => const Color(0xFFF59E0B),
  };

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Theme.of(context).dividerColor.withValues(alpha: .5)),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.push('/learn/article/${card.slug}'),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (card.heroImage != null)
              AspectRatio(
                aspectRatio: 16 / 8,
                child: Image.network(card.heroImage!, fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => Container(color: Theme.of(context).colorScheme.surfaceContainerHighest)),
              ),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(card.title, style: const TextStyle(fontSize: 15.5, fontWeight: FontWeight.w700, height: 1.3)),
                  if (card.summary != null && card.summary!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(card.summary!, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 13, color: Colors.grey.shade600, height: 1.4)),
                  ],
                  const SizedBox(height: 10),
                  Row(children: [
                    if (card.readingTime != null) ...[
                      Icon(Icons.schedule, size: 13, color: Colors.grey.shade500),
                      const SizedBox(width: 4),
                      Text('${card.readingTime} min', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                      const SizedBox(width: 12),
                    ],
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(color: _difficultyColor().withValues(alpha: .12), borderRadius: BorderRadius.circular(999)),
                      child: Text(card.difficulty[0].toUpperCase() + card.difficulty.substring(1),
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: _difficultyColor())),
                    ),
                    const Spacer(),
                    for (final gs in card.gsPaper.take(2))
                      Padding(
                        padding: const EdgeInsets.only(left: 6),
                        child: Text(gs, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Theme.of(context).colorScheme.primary)),
                      ),
                  ]),
                ],
              ),
            ),
          ],
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
