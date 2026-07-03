import 'package:flutter/material.dart';

class NewsArticle {
  final String id;
  final String title;
  final String description;
  final String? imageUrl;
  final String url;
  final String sourceKey;
  final String sourceLabel;
  final String sourceColor;
  final DateTime publishedAt;
  final List<String> tags;
  final bool isCurated;
  final bool isPinned;
  final String? curatorNote;

  const NewsArticle({
    required this.id,
    required this.title,
    required this.description,
    this.imageUrl,
    required this.url,
    required this.sourceKey,
    required this.sourceLabel,
    required this.sourceColor,
    required this.publishedAt,
    required this.tags,
    required this.isCurated,
    required this.isPinned,
    this.curatorNote,
  });

  factory NewsArticle.fromJson(Map<String, dynamic> json) {
    return NewsArticle(
      id: json['id']?.toString() ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      imageUrl: json['image_url'] as String?,
      url: json['url'] ?? '',
      sourceKey: json['source_key'] ?? '',
      sourceLabel: json['source_label'] ?? '',
      sourceColor: json['source_color'] ?? '#4F46E5',
      publishedAt: _parseDate(json['published_at']),
      tags: (json['tags'] as List?)?.cast<String>() ?? [],
      isCurated: json['is_curated'] == true,
      isPinned: json['is_pinned'] == true,
      curatorNote: json['curator_note'] as String?,
    );
  }

  static DateTime _parseDate(dynamic value) {
    if (value == null) return DateTime.now();
    try {
      return DateTime.parse(value.toString());
    } catch (_) {
      return DateTime.now();
    }
  }

  Color get color {
    try {
      final hex = sourceColor.replaceAll('#', '');
      return Color(int.parse('0xFF$hex'));
    } catch (_) {
      return const Color(0xFF4F46E5);
    }
  }
}

class NewsSourceConfig {
  final String key;
  final String displayName;
  final String colorHex;
  final String? icon;

  const NewsSourceConfig({
    required this.key,
    required this.displayName,
    required this.colorHex,
    this.icon,
  });

  factory NewsSourceConfig.fromJson(Map<String, dynamic> json) {
    return NewsSourceConfig(
      key: json['key'] ?? '',
      displayName: json['display_name'] ?? '',
      colorHex: json['color_hex'] ?? '#4F46E5',
      icon: json['icon'] as String?,
    );
  }

  Color get color {
    try {
      final hex = colorHex.replaceAll('#', '');
      return Color(int.parse('0xFF$hex'));
    } catch (_) {
      return const Color(0xFF4F46E5);
    }
  }
}
