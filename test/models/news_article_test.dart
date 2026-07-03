import 'package:edutech_app/features/news/models/news_article.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('NewsArticle', () {
    test('parses a full article', () {
      final a = NewsArticle.fromJson({
        'id': 12,
        'title': 'Big news',
        'description': 'Details',
        'image_url': 'http://img/x.png',
        'url': 'http://news/x',
        'source_key': 'pib',
        'source_label': 'PIB',
        'source_color': '#FF0000',
        'published_at': '2026-06-01T10:00:00Z',
        'tags': ['exam', 'gk'],
        'is_curated': true,
        'is_pinned': true,
        'curator_note': 'must read',
      });
      expect(a.id, '12'); // numeric id coerced to string
      expect(a.title, 'Big news');
      expect(a.tags, ['exam', 'gk']);
      expect(a.isCurated, isTrue);
      expect(a.isPinned, isTrue);
      expect(a.publishedAt, DateTime.parse('2026-06-01T10:00:00Z'));
      expect(a.color, const Color(0xFFFF0000));
    });

    test('falls back to a default color for a malformed hex', () {
      final a = NewsArticle.fromJson({
        'url': 'u',
        'source_color': 'not-a-color',
      });
      expect(a.color, const Color(0xFF4F46E5));
    });

    test('falls back to now() for a missing/invalid published_at', () {
      final before = DateTime.now();
      final a = NewsArticle.fromJson({'url': 'u'});
      final after = DateTime.now();
      expect(
        a.publishedAt.isAfter(before.subtract(const Duration(seconds: 1))),
        isTrue,
      );
      expect(
        a.publishedAt.isBefore(after.add(const Duration(seconds: 1))),
        isTrue,
      );
    });

    test('defaults empty fields gracefully', () {
      final a = NewsArticle.fromJson(const {});
      expect(a.id, '');
      expect(a.title, '');
      expect(a.tags, isEmpty);
      expect(a.isCurated, isFalse);
      expect(a.isPinned, isFalse);
    });
  });

  group('NewsSourceConfig', () {
    test('parses config and resolves color', () {
      final c = NewsSourceConfig.fromJson({
        'key': 'pib',
        'display_name': 'PIB',
        'color_hex': '#00FF00',
      });
      expect(c.key, 'pib');
      expect(c.displayName, 'PIB');
      expect(c.color, const Color(0xFF00FF00));
    });

    test('uses default color when hex is invalid', () {
      final c = NewsSourceConfig.fromJson({'color_hex': 'xyz'});
      expect(c.color, const Color(0xFF4F46E5));
    });
  });
}
