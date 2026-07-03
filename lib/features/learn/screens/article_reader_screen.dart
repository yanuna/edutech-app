import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/models/article.dart';
import '../../../core/providers/article_provider.dart';
import '../providers/reader_settings_provider.dart';
import '../widgets/article_block_view.dart';

/// Premium article reader: reading-progress bar, sticky Table of Contents,
/// adjustable font size, light/sepia/dark reading themes, image zoom, and the
/// knowledge-graph "Related" section. Renders the Content-v2 block body.
class ArticleReaderScreen extends ConsumerStatefulWidget {
  final String slug;
  const ArticleReaderScreen({super.key, required this.slug});

  @override
  ConsumerState<ArticleReaderScreen> createState() => _ArticleReaderScreenState();
}

class _ArticleReaderScreenState extends ConsumerState<ArticleReaderScreen> {
  final _scroll = ScrollController();
  final Map<int, GlobalKey> _blockKeys = {}; // block index → key (for the TOC)
  double _progress = 0;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scroll.removeListener(_onScroll);
    _scroll.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scroll.hasClients) return;
    final max = _scroll.position.maxScrollExtent;
    final p = max <= 0 ? 0.0 : (_scroll.offset / max).clamp(0.0, 1.0);
    if ((p - _progress).abs() > 0.01) setState(() => _progress = p);
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(readerSettingsProvider);
    final theme = settings.theme;
    final async = ref.watch(articleDetailProvider(widget.slug));

    return Scaffold(
      backgroundColor: theme.background,
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => _Error(onRetry: () => ref.invalidate(articleDetailProvider(widget.slug)), theme: theme),
        data: (article) => Stack(
          children: [
            _body(article, settings),
            Positioned(
              top: 0, left: 0, right: 0,
              child: LinearProgressIndicator(
                value: _progress,
                minHeight: 3,
                backgroundColor: Colors.transparent,
                valueColor: const AlwaysStoppedAnimation(Color(0xFF6366F1)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _body(Article article, ReaderSettings settings) {
    final theme = settings.theme;
    final headings = <({int index, String title})>[];
    for (var i = 0; i < article.body.length; i++) {
      final h = articleBlockHeading(article.body[i]);
      if (h != null) headings.add((index: i, title: h));
    }

    return CustomScrollView(
      controller: _scroll,
      slivers: [
        SliverAppBar(
          pinned: true,
          backgroundColor: theme.background,
          foregroundColor: theme.text,
          expandedHeight: article.card.heroImage != null ? 220 : 0,
          leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.pop()),
          actions: [
            if (headings.isNotEmpty)
              IconButton(tooltip: 'Contents', icon: const Icon(Icons.list_rounded), onPressed: () => _openToc(headings, theme)),
            IconButton(tooltip: 'Reading options', icon: const Icon(Icons.text_fields_rounded), onPressed: () => _openSettings()),
          ],
          flexibleSpace: article.card.heroImage == null
              ? null
              : FlexibleSpaceBar(
                  background: Image.network(article.card.heroImage!, fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => Container(color: theme.text.withValues(alpha: .06))),
                ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 12, 18, 48),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Header(article: article, settings: settings),
                const SizedBox(height: 8),
                for (var i = 0; i < article.body.length; i++)
                  Container(
                    key: _blockKeys[i] ??= GlobalKey(),
                    alignment: Alignment.centerLeft,
                    child: ArticleBlockView(block: article.body[i], theme: theme, fontScale: settings.fontScale),
                  ),
                _Relevance(article: article, theme: theme, fontScale: settings.fontScale),
                _Tags(tags: article.tags, theme: theme),
                _Related(article: article, theme: theme, fontScale: settings.fontScale),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _openToc(List<({int index, String title})> headings, ReaderTheme theme) {
    showModalBottomSheet(
      context: context,
      backgroundColor: theme.background,
      builder: (_) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Text('Contents', style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700, fontSize: 16, color: theme.text)),
            ),
            for (final h in headings)
              ListTile(
                title: Text(h.title, style: TextStyle(color: theme.text)),
                leading: Icon(Icons.chevron_right_rounded, color: theme.muted),
                onTap: () {
                  Navigator.pop(context);
                  final key = _blockKeys[h.index];
                  final ctx = key?.currentContext;
                  if (ctx != null) {
                    Scrollable.ensureVisible(ctx, duration: const Duration(milliseconds: 400), curve: Curves.easeInOut, alignment: 0.05);
                  }
                },
              ),
          ],
        ),
      ),
    );
  }

  void _openSettings() {
    showModalBottomSheet(
      context: context,
      builder: (_) => Consumer(
        builder: (_, ref, _) {
          final s = ref.watch(readerSettingsProvider);
          final n = ref.read(readerSettingsProvider.notifier);
          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Reading options', style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700, fontSize: 16)),
                  const SizedBox(height: 16),
                  Row(children: [
                    const Text('A', style: TextStyle(fontSize: 14)),
                    Expanded(
                      child: Slider(
                        value: s.fontScale, min: 0.85, max: 1.6, divisions: 5,
                        label: '${(s.fontScale * 100).round()}%',
                        onChanged: (v) => n.setFontScale(v),
                      ),
                    ),
                    const Text('A', style: TextStyle(fontSize: 22)),
                  ]),
                  const SizedBox(height: 8),
                  const Text('Theme', style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      for (final t in ReaderTheme.values)
                        Padding(
                          padding: const EdgeInsets.only(right: 12),
                          child: GestureDetector(
                            onTap: () => n.setTheme(t),
                            child: Container(
                              width: 52, height: 52,
                              decoration: BoxDecoration(
                                color: t.background,
                                shape: BoxShape.circle,
                                border: Border.all(color: s.theme == t ? const Color(0xFF6366F1) : Colors.grey.withValues(alpha: .4), width: s.theme == t ? 3 : 1),
                              ),
                              child: Center(child: Text('Aa', style: TextStyle(color: t.text, fontWeight: FontWeight.w700))),
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final Article article;
  final ReaderSettings settings;
  const _Header({required this.article, required this.settings});

  @override
  Widget build(BuildContext context) {
    final theme = settings.theme;
    final c = article.card;
    final chips = <Widget>[
      if (c.subjectName != null) _chip(c.subjectName!, theme),
      if (c.readingTime != null) _chip('${c.readingTime} min read', theme, icon: Icons.schedule),
      _chip(c.difficulty[0].toUpperCase() + c.difficulty.substring(1), theme, icon: Icons.signal_cellular_alt),
      for (final gs in c.gsPaper) _chip(gs, theme),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(c.title, style: TextStyle(fontFamily: 'Poppins', fontSize: 24 * settings.fontScale, fontWeight: FontWeight.w800, height: 1.25, color: theme.text)),
        if (c.summary != null && c.summary!.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(c.summary!, style: TextStyle(fontSize: 15.5 * settings.fontScale, color: theme.muted, height: 1.5)),
        ],
        const SizedBox(height: 12),
        Wrap(spacing: 8, runSpacing: 8, children: chips),
        const SizedBox(height: 8),
        Divider(color: theme.text.withValues(alpha: .12)),
      ],
    );
  }

  Widget _chip(String label, ReaderTheme theme, {IconData? icon}) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    decoration: BoxDecoration(color: theme.text.withValues(alpha: .06), borderRadius: BorderRadius.circular(999)),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      if (icon != null) ...[Icon(icon, size: 13, color: theme.muted), const SizedBox(width: 4)],
      Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: theme.muted)),
    ]),
  );
}

class _Relevance extends StatelessWidget {
  final Article article;
  final ReaderTheme theme;
  final double fontScale;
  const _Relevance({required this.article, required this.theme, required this.fontScale});

  @override
  Widget build(BuildContext context) {
    final rows = <(String, String?)>[
      ('Prelims', article.prelimsRelevance),
      ('Mains', article.mainsRelevance),
      ('Optional', article.optionalRelevance),
    ].where((r) => (r.$2 ?? '').isNotEmpty).toList();
    if (rows.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Exam Relevance', style: TextStyle(fontFamily: 'Poppins', fontSize: 18 * fontScale, fontWeight: FontWeight.w700, color: theme.text)),
          const SizedBox(height: 10),
          for (final r in rows)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Container(
                  width: 68, padding: const EdgeInsets.symmetric(vertical: 3),
                  decoration: BoxDecoration(color: const Color(0xFF10B981).withValues(alpha: .12), borderRadius: BorderRadius.circular(6)),
                  child: Text(r.$1, textAlign: TextAlign.center, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF059669))),
                ),
                const SizedBox(width: 10),
                Expanded(child: Text(r.$2!, style: TextStyle(fontSize: 14 * fontScale, color: theme.text, height: 1.45))),
              ]),
            ),
        ],
      ),
    );
  }
}

class _Tags extends StatelessWidget {
  final List<ArticleTag> tags;
  final ReaderTheme theme;
  const _Tags({required this.tags, required this.theme});

  @override
  Widget build(BuildContext context) {
    if (tags.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 20),
      child: Wrap(
        spacing: 8, runSpacing: 8,
        children: [
          for (final t in tags)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(color: const Color(0xFF6366F1).withValues(alpha: .10), borderRadius: BorderRadius.circular(8)),
              child: Text('#${t.name}', style: const TextStyle(fontSize: 12.5, color: Color(0xFF6366F1), fontWeight: FontWeight.w600)),
            ),
        ],
      ),
    );
  }
}

class _Related extends StatelessWidget {
  final Article article;
  final ReaderTheme theme;
  final double fontScale;
  const _Related({required this.article, required this.theme, required this.fontScale});

  static const _titles = {
    'articles': 'Related Articles',
    'mcqs': 'Related MCQs',
    'pyqs': 'Related PYQs',
    'current_affairs': 'Related Current Affairs',
  };

  @override
  Widget build(BuildContext context) {
    if (article.related.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final entry in article.related.entries)
            if (entry.value.isNotEmpty) ...[
              Text(_titles[entry.key] ?? entry.key, style: TextStyle(fontFamily: 'Poppins', fontSize: 17 * fontScale, fontWeight: FontWeight.w700, color: theme.text)),
              const SizedBox(height: 10),
              for (final item in entry.value)
                _RelatedTile(item: item, theme: theme, fontScale: fontScale),
              const SizedBox(height: 18),
            ],
        ],
      ),
    );
  }
}

class _RelatedTile extends StatelessWidget {
  final RelatedItem item;
  final ReaderTheme theme;
  final double fontScale;
  const _RelatedTile({required this.item, required this.theme, required this.fontScale});

  @override
  Widget build(BuildContext context) {
    final tappable = item.group == 'articles' && item.slug != null;
    return InkWell(
      onTap: tappable ? () => context.push('/learn/article/${item.slug}') : null,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: theme.text.withValues(alpha: .04), borderRadius: BorderRadius.circular(10)),
        child: Row(
          children: [
            Icon(_icon, size: 18, color: const Color(0xFF6366F1)),
            const SizedBox(width: 10),
            Expanded(child: Text(item.title, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 14 * fontScale, color: theme.text))),
            if (tappable) Icon(Icons.chevron_right_rounded, color: theme.muted),
          ],
        ),
      ),
    );
  }

  IconData get _icon => switch (item.group) {
    'mcqs' => Icons.quiz_outlined,
    'pyqs' => Icons.history_edu_outlined,
    'current_affairs' => Icons.newspaper_outlined,
    _ => Icons.article_outlined,
  };
}

class _Error extends StatelessWidget {
  final VoidCallback onRetry;
  final ReaderTheme theme;
  const _Error({required this.onRetry, required this.theme});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.wifi_off_rounded, size: 44, color: theme.muted),
          const SizedBox(height: 12),
          Text('Could not load this article', style: TextStyle(color: theme.text)),
          const SizedBox(height: 12),
          FilledButton.tonal(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}
