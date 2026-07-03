import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/api_client.dart';
import '../api/api_endpoints.dart';
import '../models/article.dart';
import 'catalog_provider.dart' show contentLanguageProvider;

class EntityItem {
  final int id;
  final String slug;
  final String name;
  final int articlesCount;
  const EntityItem({required this.id, required this.slug, required this.name, this.articlesCount = 0});

  factory EntityItem.fromJson(Map<String, dynamic> j) => EntityItem(
    id: j['id'] as int,
    slug: j['slug'] as String? ?? '',
    name: j['name'] as String? ?? '',
    articlesCount: j['articles_count'] as int? ?? 0,
  );
}

/// Typed entities (scheme | committee | sc_case | report | article).
final entitiesProvider = FutureProvider.family<List<EntityItem>, String>((ref, type) async {
  final lang = ref.watch(contentLanguageProvider);
  final res = await ApiClient.instance.get(ApiEndpoints.entities(type), params: {'lang': lang});
  return ((res.data['entities'] as List?) ?? const [])
      .map((e) => EntityItem.fromJson((e as Map).cast<String, dynamic>()))
      .toList();
});

class EntityDetail {
  final String name;
  final String type;
  final String? description;
  final List<ArticleCard> articles;
  const EntityDetail({required this.name, required this.type, this.description, this.articles = const []});
}

final entityDetailProvider = FutureProvider.family<EntityDetail, String>((ref, slug) async {
  final lang = ref.watch(contentLanguageProvider);
  final res = await ApiClient.instance.get(ApiEndpoints.entity(slug), params: {'lang': lang});
  final e = (res.data['entity'] as Map).cast<String, dynamic>();
  return EntityDetail(
    name: e['name'] as String? ?? '',
    type: e['type'] as String? ?? '',
    description: e['description'] as String?,
    articles: ((res.data['articles'] as List?) ?? const [])
        .map((a) => ArticleCard.fromJson((a as Map).cast<String, dynamic>()))
        .toList(),
  );
});
