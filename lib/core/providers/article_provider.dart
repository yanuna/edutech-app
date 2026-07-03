import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/api_client.dart';
import '../api/api_endpoints.dart';
import '../models/article.dart';
import '../services/article_interaction_service.dart';
import 'catalog_provider.dart' show contentLanguageProvider;

/// Filter for an article list query. Immutable + value-equal so Riverpod can
/// cache one provider instance per distinct filter.
class ArticleQuery {
  final int? subjectId;
  final int? topicId;
  final int? subtopicId;
  final bool featured;
  final String? difficulty;

  const ArticleQuery({this.subjectId, this.topicId, this.subtopicId, this.featured = false, this.difficulty});

  Map<String, dynamic> toParams(String lang) => {
    'lang': lang,
    if (subjectId != null) 'subject_id': subjectId,
    if (topicId != null) 'topic_id': topicId,
    if (subtopicId != null) 'subtopic_id': subtopicId,
    if (featured) 'featured': 1,
    if (difficulty != null) 'difficulty': difficulty,
  };

  @override
  bool operator ==(Object other) =>
      other is ArticleQuery &&
      other.subjectId == subjectId &&
      other.topicId == topicId &&
      other.subtopicId == subtopicId &&
      other.featured == featured &&
      other.difficulty == difficulty;

  @override
  int get hashCode => Object.hash(subjectId, topicId, subtopicId, featured, difficulty);
}

/// Paginated-but-first-page list of article cards for a filter.
final articleListProvider = FutureProvider.family<List<ArticleCard>, ArticleQuery>((ref, query) async {
  final lang = ref.watch(contentLanguageProvider);
  final res = await ApiClient.instance.get(ApiEndpoints.articles, params: query.toParams(lang));
  return ((res.data['articles'] as List?) ?? const [])
      .map((e) => ArticleCard.fromJson((e as Map).cast<String, dynamic>()))
      .toList();
});

/// Structured Current Affairs for a period ('daily' | 'weekly' | 'monthly').
final currentAffairsProvider = FutureProvider.family<List<ArticleCard>, String>((ref, period) async {
  final lang = ref.watch(contentLanguageProvider);
  final res = await ApiClient.instance.get(ApiEndpoints.currentAffairs(period), params: {'lang': lang});
  return ((res.data['articles'] as List?) ?? const [])
      .map((e) => ArticleCard.fromJson((e as Map).cast<String, dynamic>()))
      .toList();
});

/// The user's in-progress (not finished) articles — Home "Continue Reading".
final continueReadingProvider = FutureProvider.autoDispose<List<ArticleCard>>((ref) async {
  return ArticleInteractionService.continueReading();
});

/// Full article (body blocks + related graph) by slug.
final articleDetailProvider = FutureProvider.family<Article, String>((ref, slug) async {
  final lang = ref.watch(contentLanguageProvider);
  final res = await ApiClient.instance.get(ApiEndpoints.article(slug), params: {'lang': lang});
  return Article.fromResponse((res.data as Map).cast<String, dynamic>());
});
