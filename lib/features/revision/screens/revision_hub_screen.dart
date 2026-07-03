import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../progress/providers/dashboard_provider.dart';

/// Revision Hub — one place for everything worth revising: saved articles,
/// bookmarked MCQs, the wrong-questions bank, flashcards, and weak topics.
/// Composes surfaces already built in earlier modules.
class RevisionHubScreen extends ConsumerWidget {
  const RevisionHubScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboard = ref.watch(dashboardProvider);

    final tiles = <_RevTile>[
      _RevTile('Saved Articles', 'Articles you bookmarked', Icons.article_outlined, const Color(0xFF6366F1), '/learn/saved'),
      _RevTile('Flashcards', 'Flip through your saved MCQs', Icons.style_outlined, const Color(0xFFF59E0B), '/revision/flashcards'),
      _RevTile('Bookmarked MCQs', 'Questions saved for later', Icons.bookmark_added_outlined, const Color(0xFF0EA5E9), '/practice/review/bookmarked'),
      _RevTile('Wrong Questions', 'Everything you got wrong', Icons.rule_rounded, const Color(0xFFEF4444), '/practice/review/wrong'),
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Revision Hub')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.35,
            children: [for (final t in tiles) _RevCard(tile: t)],
          ),
          const SizedBox(height: 22),

          // Weak topics from the progress dashboard.
          dashboard.maybeWhen(
            data: (d) => d.weakAreas.isEmpty
                ? const SizedBox.shrink()
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Weak Topics', style: TextStyle(fontFamily: 'Poppins', fontSize: 17, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 4),
                      Text('Focus your revision here — lowest accuracy.', style: TextStyle(fontSize: 12.5, color: Colors.grey.shade600)),
                      const SizedBox(height: 12),
                      for (final w in d.weakAreas)
                        Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEF4444).withValues(alpha: .07),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFEF4444).withValues(alpha: .2)),
                          ),
                          child: Row(children: [
                            const Icon(Icons.trending_down_rounded, color: Color(0xFFEF4444)),
                            const SizedBox(width: 12),
                            Expanded(child: Text(w.subject, style: const TextStyle(fontWeight: FontWeight.w600))),
                            Text('${w.accuracy.toStringAsFixed(0)}%', style: const TextStyle(fontWeight: FontWeight.w700, color: Color(0xFFB91C1C))),
                          ]),
                        ),
                    ],
                  ),
            orElse: () => const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}

class _RevTile {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final String route;
  const _RevTile(this.title, this.subtitle, this.icon, this.color, this.route);
}

class _RevCard extends StatelessWidget {
  final _RevTile tile;
  const _RevCard({required this.tile});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => context.push(tile.route),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: tile.color.withValues(alpha: .10), borderRadius: BorderRadius.circular(16)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Icon(tile.icon, color: tile.color, size: 26),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(tile.title, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14.5, color: tile.color)),
              const SizedBox(height: 2),
              Text(tile.subtitle, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 11.5, color: Colors.grey.shade600)),
            ]),
          ],
        ),
      ),
    );
  }
}
