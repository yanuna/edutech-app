import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/api_endpoints.dart';
import '../models/news_article.dart';

final newsRepositoryProvider = Provider<NewsRepository>(
  (ref) => NewsRepository(),
);

class NewsRepository {
  final Dio _dio = Dio(
    BaseOptions(
      baseUrl: ApiEndpoints.baseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 20),
    ),
  );

  Future<List<NewsArticle>> getNews({
    String source = 'all',
    int limit = 30,
    bool refresh = false,
  }) async {
    final response = await _dio.get(
      ApiEndpoints.news,
      queryParameters: {
        'source': source,
        'limit': limit,
        if (refresh) 'refresh': '1',
      },
    );
    final data = response.data as Map<String, dynamic>;
    final articles = (data['articles'] as List?) ?? [];
    return articles
        .map((e) => NewsArticle.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<NewsSourceConfig>> getSources() async {
    final response = await _dio.get(ApiEndpoints.newsSources);
    final data = response.data as Map<String, dynamic>;
    final sources = (data['sources'] as List?) ?? [];
    return sources
        .map((e) => NewsSourceConfig.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
