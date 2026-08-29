import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/news_provider.dart';
import '../widgets/news_card.dart';
import '../widgets/news_shimmer.dart';
import '../../../core/api/api_client.dart';

class CurrentNewsScreen extends ConsumerStatefulWidget {
  const CurrentNewsScreen({super.key});

  @override
  ConsumerState<CurrentNewsScreen> createState() => _CurrentNewsScreenState();
}

class _CurrentNewsScreenState extends ConsumerState<CurrentNewsScreen> {
  final _searchController = TextEditingController();
  bool _searchVisible = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final selectedSource = ref.watch(selectedNewsSourceProvider);
    final sourcesAsync = ref.watch(newsSourcesProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: NestedScrollView(
        headerSliverBuilder: (ctx, innerScrolled) => [
          SliverAppBar(
            title: const Text(
              'Current News',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w700,
                fontSize: 18,
              ),
            ),
            backgroundColor: Colors.white,
            foregroundColor: const Color(0xFF111827),
            elevation: 0,
            floating: true,
            snap: true,
            actions: [
              IconButton(
                icon: Icon(_searchVisible ? Icons.search_off : Icons.search),
                onPressed: () {
                  setState(() => _searchVisible = !_searchVisible);
                  if (!_searchVisible) {
                    _searchController.clear();
                    ref.read(newsSearchQueryProvider.notifier).state = '';
                  }
                },
              ),
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: () => ref
                    .read(newsArticlesProvider(selectedSource).notifier)
                    .refresh(),
              ),
            ],
            bottom: PreferredSize(
              preferredSize: Size.fromHeight(_searchVisible ? 104 : 52),
              child: Column(
                children: [
                  if (_searchVisible)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                      child: TextField(
                        controller: _searchController,
                        autofocus: true,
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 13,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Search news, tags…',
                          hintStyle: const TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 13,
                          ),
                          prefixIcon: const Icon(Icons.search, size: 18),
                          filled: true,
                          fillColor: const Color(0xFFF3F4F6),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 10,
                          ),
                        ),
                        onChanged: (v) =>
                            ref.read(newsSearchQueryProvider.notifier).state =
                                v,
                      ),
                    ),
                  // Source filter chips
                  SizedBox(
                    height: 44,
                    child: sourcesAsync.when(
                      loading: () => const SizedBox.shrink(),
                      error: (_, _) => const SizedBox.shrink(),
                      data: (sources) => ListView(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
                        children: [
                          _FilterChip(
                            label: 'All',
                            sourceKey: 'all',
                            color: const Color(0xFF4F46E5),
                            selected: selectedSource == 'all',
                          ),
                          const SizedBox(width: 8),
                          _FilterChip(
                            label: 'Curated',
                            sourceKey: 'curated',
                            color: const Color(0xFF7C3AED),
                            selected: selectedSource == 'curated',
                          ),
                          ...sources.map(
                            (s) => Padding(
                              padding: const EdgeInsets.only(left: 8),
                              child: _FilterChip(
                                label: s.displayName,
                                sourceKey: s.key,
                                color: s.color,
                                selected: selectedSource == s.key,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
        body: _NewsFeed(source: selectedSource),
      ),
    );
  }
}

// ── Source Filter Chip ────────────────────────────────────────────────────────

class _FilterChip extends ConsumerWidget {
  final String label;
  final String sourceKey;
  final Color color;
  final bool selected;

  const _FilterChip({
    required this.label,
    required this.sourceKey,
    required this.color,
    required this.selected,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onTap: () {
        ref.read(selectedNewsSourceProvider.notifier).state = sourceKey;
        ref.read(newsSearchQueryProvider.notifier).state = '';
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? color : color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: color.withValues(alpha: selected ? 0 : 0.3),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w600,
            fontSize: 12,
            color: selected ? Colors.white : color,
          ),
        ),
      ),
    );
  }
}

// ── News Feed ─────────────────────────────────────────────────────────────────

class _NewsFeed extends ConsumerWidget {
  final String source;
  const _NewsFeed({required this.source});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final articlesAsync = ref.watch(filteredNewsProvider(source));

    return articlesAsync.when(
      loading: () => const NewsShimmer(),
      error: (e, _) => _ErrorView(
        message: apiErrorMessage(e),
        onRetry: () =>
            ref.read(newsArticlesProvider(source).notifier).refresh(),
      ),
      data: (articles) => RefreshIndicator(
        onRefresh: () =>
            ref.read(newsArticlesProvider(source).notifier).refresh(),
        color: const Color(0xFF4F46E5),
        child: articles.isEmpty
            ? const _EmptyView()
            : ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                itemCount: articles.length,
                itemBuilder: (_, i) => NewsCard(article: articles[i]),
              ),
      ),
    );
  }
}

// ── Empty State ───────────────────────────────────────────────────────────────

class _EmptyView extends StatelessWidget {
  const _EmptyView();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.newspaper_outlined, size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          const Text(
            'No articles found',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w600,
              color: Colors.grey,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Pull down to refresh',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 12,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Error State ───────────────────────────────────────────────────────────────

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.cloud_off_outlined,
              size: 56,
              color: Colors.grey.shade300,
            ),
            const SizedBox(height: 16),
            const Text(
              'Could not load news',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w600,
                color: Color(0xFF374151),
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 11,
                color: Colors.grey,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh, size: 16),
              label: const Text(
                'Retry',
                style: TextStyle(fontFamily: 'Poppins'),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4F46E5),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
