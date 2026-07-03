import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/api_client.dart';
import '../api/api_endpoints.dart';
import '../models/article.dart';
import 'catalog_provider.dart' show contentLanguageProvider;

/// Notes for an optional format ('short' | 'revision' | 'one_page' |
/// 'cheat_sheet' | 'mind_map' | null = all).
final notesProvider = FutureProvider.family<List<ArticleCard>, String?>((ref, format) async {
  final lang = ref.watch(contentLanguageProvider);
  final res = await ApiClient.instance.get(ApiEndpoints.notes, params: {
    'lang': lang,
    'format': ?format,
  });
  return ((res.data['notes'] as List?) ?? const [])
      .map((e) => ArticleCard.fromJson((e as Map).cast<String, dynamic>()))
      .toList();
});

class EditorialData {
  final List<ArticleCard> editorials;
  final List<String> sources;
  const EditorialData({this.editorials = const [], this.sources = const []});
}

/// Editorials, optionally filtered by source (The Hindu / Indian Express / …).
final editorialsProvider = FutureProvider.family<EditorialData, String?>((ref, source) async {
  final lang = ref.watch(contentLanguageProvider);
  final res = await ApiClient.instance.get(ApiEndpoints.editorials, params: {
    'lang': lang,
    'source': ?source,
  });
  return EditorialData(
    editorials: ((res.data['editorials'] as List?) ?? const [])
        .map((e) => ArticleCard.fromJson((e as Map).cast<String, dynamic>()))
        .toList(),
    sources: ((res.data['sources'] as List?) ?? const []).map((e) => e.toString()).toList(),
  );
});
