import '../api/api_client.dart';
import '../api/api_endpoints.dart';
import '../models/article.dart';

/// A user's per-article state fetched on reader open.
class ArticleInteractions {
  final bool bookmarked;
  final int progressPercent;
  final int lastBlockIndex;
  const ArticleInteractions({this.bookmarked = false, this.progressPercent = 0, this.lastBlockIndex = 0});

  factory ArticleInteractions.fromJson(Map<String, dynamic> j) {
    final p = (j['progress'] as Map?)?.cast<String, dynamic>();
    return ArticleInteractions(
      bookmarked: j['bookmarked'] as bool? ?? false,
      progressPercent: p?['percent'] as int? ?? 0,
      lastBlockIndex: p?['last_block_index'] as int? ?? 0,
    );
  }
}

/// Thin wrapper over the Module-4 interaction endpoints (all auth:sanctum).
class ArticleInteractionService {
  ArticleInteractionService._();

  static Future<ArticleInteractions> fetch(String slug) async {
    final res = await ApiClient.instance.get(ApiEndpoints.articleInteractions(slug));
    return ArticleInteractions.fromJson((res.data as Map).cast<String, dynamic>());
  }

  /// Toggle a bookmark on any content; returns the new bookmarked state.
  static Future<bool> toggleBookmark({required String type, required int id}) async {
    final res = await ApiClient.instance.post(ApiEndpoints.bookmarkToggle, data: {'type': type, 'id': id});
    return res.data['bookmarked'] as bool? ?? false;
  }

  /// Best-effort progress save — never throws into the UI.
  static Future<void> saveProgress(String slug, {required int percent, int? blockIndex, int? seconds}) async {
    try {
      await ApiClient.instance.post(ApiEndpoints.articleProgress(slug), data: {
        'percent': percent,
        'block_index': ?blockIndex,
        'seconds': ?seconds,
      });
    } catch (_) {/* progress is non-critical */}
  }

  static Future<List<ArticleCard>> savedArticles() async {
    final res = await ApiClient.instance.get(ApiEndpoints.bookmarks('article'));
    return ((res.data['items'] as List?) ?? const [])
        .map((e) => ArticleCard.fromJson((e as Map).cast<String, dynamic>()))
        .toList();
  }

  static Future<List<ArticleCard>> continueReading() async {
    final res = await ApiClient.instance.get(ApiEndpoints.continueReading);
    return ((res.data['items'] as List?) ?? const [])
        .map((e) => ArticleCard.fromJson((e as Map).cast<String, dynamic>()))
        .toList();
  }
}
