import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/api_endpoints.dart';
import '../../../core/providers/catalog_provider.dart' show contentLanguageProvider;

class BookItem {
  final int id;
  final String title;
  final String? author;
  final String category;
  final String categoryLabel;
  final String? coverUrl;
  final String? fileUrl;
  const BookItem({required this.id, required this.title, this.author, required this.category, required this.categoryLabel, this.coverUrl, this.fileUrl});

  factory BookItem.fromJson(Map<String, dynamic> j) => BookItem(
    id: j['id'] as int,
    title: j['title'] as String? ?? '',
    author: j['author'] as String?,
    category: j['category'] as String? ?? '',
    categoryLabel: j['category_label'] as String? ?? '',
    coverUrl: j['cover_url'] as String?,
    fileUrl: j['file_url'] as String?,
  );
}

class BooksData {
  final List<({String key, String label})> categories;
  final List<BookItem> books;
  const BooksData({this.categories = const [], this.books = const []});
}

/// Books for an optional category (null = all).
final booksProvider = FutureProvider.family<BooksData, String?>((ref, category) async {
  final lang = ref.watch(contentLanguageProvider);
  final res = await ApiClient.instance.get(ApiEndpoints.books, params: {
    'lang': lang,
    'category': ?category,
  });
  return BooksData(
    categories: ((res.data['categories'] as List?) ?? const [])
        .map((e) => (key: (e as Map)['key'] as String, label: e['label'] as String))
        .toList(),
    books: ((res.data['books'] as List?) ?? const [])
        .map((e) => BookItem.fromJson((e as Map).cast<String, dynamic>()))
        .toList(),
  );
});
