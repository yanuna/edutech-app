import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/news_article.dart';
import '../services/news_repository.dart';

// ── Selected source filter ───────────────────────────────────────────────────
final selectedNewsSourceProvider = StateProvider<String>((ref) => 'all');

// ── Search query ─────────────────────────────────────────────────────────────
final newsSearchQueryProvider = StateProvider<String>((ref) => '');

// ── Active sources list ───────────────────────────────────────────────────────
final newsSourcesProvider = FutureProvider<List<NewsSourceConfig>>((ref) {
  return ref.read(newsRepositoryProvider).getSources();
});

// ── Articles for a given source (StateNotifier so we can refresh/paginate) ───
final newsArticlesProvider =
    StateNotifierProvider.family<
      NewsArticlesNotifier,
      AsyncValue<List<NewsArticle>>,
      String
    >(
      (ref, source) =>
          NewsArticlesNotifier(ref.read(newsRepositoryProvider), source),
    );

class NewsArticlesNotifier
    extends StateNotifier<AsyncValue<List<NewsArticle>>> {
  NewsArticlesNotifier(this._repo, this._source)
    : super(const AsyncValue.loading()) {
    fetch();
  }

  final NewsRepository _repo;
  final String _source;

  Future<void> fetch({bool refresh = false}) async {
    state = const AsyncValue.loading();
    try {
      final articles = await _repo.getNews(source: _source, refresh: refresh);
      state = AsyncValue.data(articles);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> refresh() => fetch(refresh: true);
}

// ── Filtered articles (search applied on top of fetched list) ────────────────
final filteredNewsProvider =
    Provider.family<AsyncValue<List<NewsArticle>>, String>((ref, source) {
      final raw = ref.watch(newsArticlesProvider(source));
      final query = ref.watch(newsSearchQueryProvider).trim().toLowerCase();

      return raw.whenData((articles) {
        if (query.isEmpty) return articles;
        return articles.where((a) {
          return a.title.toLowerCase().contains(query) ||
              a.description.toLowerCase().contains(query) ||
              a.tags.any((t) => t.toLowerCase().contains(query));
        }).toList();
      });
    });

// ── Bookmarks (local, shared_preferences) ────────────────────────────────────
final bookmarksProvider = StateNotifierProvider<BookmarksNotifier, Set<String>>(
  (ref) => BookmarksNotifier(),
);

class BookmarksNotifier extends StateNotifier<Set<String>> {
  static const _key = 'bookmarked_news_ids';

  BookmarksNotifier() : super({}) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final ids = prefs.getStringList(_key) ?? [];
    state = ids.toSet();
  }

  Future<void> toggle(String articleId) async {
    final next = Set<String>.from(state);
    if (next.contains(articleId)) {
      next.remove(articleId);
    } else {
      next.add(articleId);
    }
    state = next;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_key, next.toList());
  }

  bool isBookmarked(String articleId) => state.contains(articleId);
}
