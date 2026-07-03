import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/models/article.dart';
import '../../../core/models/catalog.dart';
import '../../../core/providers/article_provider.dart';
import '../../../core/providers/catalog_provider.dart';

/// The heart of the app — "Learn". A hub that surfaces featured Articles,
/// subject-wise browsing into the new Article system, and quick access to the
/// existing study material and PYQs. Bilingual via the content-language toggle.
class LearnScreen extends ConsumerWidget {
  const LearnScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subjectsAsync = ref.watch(subjectsProvider);
    final featuredAsync = ref.watch(articleListProvider(const ArticleQuery(featured: true)));
    final lang = ref.watch(contentLanguageProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Learn'),
        actions: [
          IconButton(
            tooltip: 'Search',
            icon: const Icon(Icons.search_rounded),
            onPressed: () => context.push('/search'),
          ),
          IconButton(
            tooltip: 'Saved',
            icon: const Icon(Icons.bookmark_border_rounded),
            onPressed: () => context.push('/learn/saved'),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: TextButton(
              onPressed: () => ref.read(contentLanguageProvider.notifier).set(lang == 'en' ? 'hi' : 'en'),
              child: Text(lang == 'en' ? 'हिं' : 'EN', style: const TextStyle(fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(subjectsProvider);
          ref.invalidate(articleListProvider(const ArticleQuery(featured: true)));
        },
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
          children: [
            _QuickAccessRow(),
            const SizedBox(height: 22),

            // ── Featured articles ─────────────────────────────────────────────
            featuredAsync.maybeWhen(
              data: (featured) => featured.isEmpty
                  ? const SizedBox.shrink()
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const _SectionTitle('Featured'),
                        const SizedBox(height: 10),
                        SizedBox(
                          height: 190,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            itemCount: featured.length,
                            separatorBuilder: (_, _) => const SizedBox(width: 12),
                            itemBuilder: (_, i) => _FeaturedCard(card: featured[i]),
                          ),
                        ),
                        const SizedBox(height: 22),
                      ],
                    ),
              orElse: () => const SizedBox.shrink(),
            ),

            // ── Browse by subject ────────────────────────────────────────────
            const _SectionTitle('Browse by Subject'),
            const SizedBox(height: 12),
            subjectsAsync.when(
              loading: () => const Padding(padding: EdgeInsets.all(24), child: Center(child: CircularProgressIndicator())),
              error: (_, _) => _InlineError(onRetry: () => ref.invalidate(subjectsProvider)),
              data: (subjects) => GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, mainAxisSpacing: 12, crossAxisSpacing: 12, childAspectRatio: 1.7),
                itemCount: subjects.length,
                itemBuilder: (_, i) => _SubjectCard(subject: subjects[i]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickAccessRow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final items = [
      (icon: Icons.menu_book_rounded, label: 'Study Material', color: const Color(0xFF6366F1), onTap: () => context.push('/subjects')),
      (icon: Icons.history_edu_rounded, label: 'PYQs', color: const Color(0xFF0EA5E9), onTap: () => context.push('/pyqs')),
    ];
    return Row(
      children: [
        for (final it in items)
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(right: 12),
              child: InkWell(
                onTap: it.onTap,
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 14),
                  decoration: BoxDecoration(color: it.color.withValues(alpha: .10), borderRadius: BorderRadius.circular(14)),
                  child: Row(children: [
                    Icon(it.icon, color: it.color),
                    const SizedBox(width: 10),
                    Expanded(child: Text(it.label, style: TextStyle(fontWeight: FontWeight.w700, color: it.color, fontSize: 13.5))),
                  ]),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _SubjectCard extends StatelessWidget {
  final Subject subject;
  const _SubjectCard({required this.subject});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => context.push('/learn/subject/${subject.id}?name=${Uri.encodeComponent(subject.name)}'),
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Theme.of(context).dividerColor.withValues(alpha: .5)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: Theme.of(context).colorScheme.primary.withValues(alpha: .10), borderRadius: BorderRadius.circular(10)),
              child: Icon(Icons.folder_special_outlined, color: Theme.of(context).colorScheme.primary, size: 20),
            ),
            Text(subject.name, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14.5)),
          ],
        ),
      ),
    );
  }
}

class _FeaturedCard extends StatelessWidget {
  final ArticleCard card;
  const _FeaturedCard({required this.card});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 260,
      child: Card(
        elevation: 0,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: Theme.of(context).dividerColor.withValues(alpha: .5))),
        child: InkWell(
          onTap: () => context.push('/learn/article/${card.slug}'),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: card.heroImage != null
                    ? Image.network(card.heroImage!, width: double.infinity, fit: BoxFit.cover, errorBuilder: (_, _, _) => _gradient(context))
                    : _gradient(context),
              ),
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(card.title, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, height: 1.25)),
                    const SizedBox(height: 4),
                    Text('${card.subjectName ?? ''}${card.readingTime != null ? ' · ${card.readingTime} min' : ''}', style: TextStyle(fontSize: 11.5, color: Colors.grey.shade600)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _gradient(BuildContext context) => Container(
    decoration: BoxDecoration(gradient: LinearGradient(colors: [Theme.of(context).colorScheme.primary, Theme.of(context).colorScheme.secondary])),
    child: const Center(child: Icon(Icons.article, color: Colors.white54, size: 40)),
  );
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);
  @override
  Widget build(BuildContext context) =>
      Text(text, style: const TextStyle(fontFamily: 'Poppins', fontSize: 18, fontWeight: FontWeight.w700));
}

class _InlineError extends StatelessWidget {
  final VoidCallback onRetry;
  const _InlineError({required this.onRetry});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(24),
    child: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
      Text('Could not load subjects', style: TextStyle(color: Colors.grey.shade600)),
      const SizedBox(height: 8),
      FilledButton.tonal(onPressed: onRetry, child: const Text('Retry')),
    ])),
  );
}
