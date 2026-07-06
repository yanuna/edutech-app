import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/api_client.dart';
import '../api/api_endpoints.dart';

/// Summary of a legal page (for the menu list).
class LegalPageSummary {
  final String slug;
  final String title;
  final String? subtitle;
  const LegalPageSummary({required this.slug, required this.title, this.subtitle});

  factory LegalPageSummary.fromJson(Map<String, dynamic> json) => LegalPageSummary(
        slug: json['slug']?.toString() ?? '',
        title: json['title']?.toString() ?? '',
        subtitle: json['subtitle']?.toString(),
      );
}

/// A full legal page with its HTML body.
class LegalPageDetail {
  final String slug;
  final String title;
  final String? subtitle;
  final String bodyHtml;
  final DateTime? updatedAt;
  const LegalPageDetail({required this.slug, required this.title, this.subtitle, required this.bodyHtml, this.updatedAt});

  factory LegalPageDetail.fromJson(Map<String, dynamic> json) => LegalPageDetail(
        slug: json['slug']?.toString() ?? '',
        title: json['title']?.toString() ?? '',
        subtitle: json['subtitle']?.toString(),
        bodyHtml: json['body_html']?.toString() ?? '',
        updatedAt: DateTime.tryParse(json['updated_at']?.toString() ?? ''),
      );
}

/// The list of published legal pages (admin-managed).
final legalPagesProvider = FutureProvider<List<LegalPageSummary>>((ref) async {
  final res = await ApiClient.instance.get(ApiEndpoints.legal);
  return ((res.data['pages'] as List?) ?? const [])
      .map((e) => LegalPageSummary.fromJson((e as Map).cast<String, dynamic>()))
      .toList();
});

/// A single legal page by slug.
final legalPageProvider = FutureProvider.family<LegalPageDetail, String>((ref, slug) async {
  final res = await ApiClient.instance.get(ApiEndpoints.legalPage(slug));
  return LegalPageDetail.fromJson((res.data as Map).cast<String, dynamic>());
});
