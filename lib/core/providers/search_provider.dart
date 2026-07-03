import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/api_client.dart';
import '../api/api_endpoints.dart';

/// One search hit; kept as a loose map so each result group renders differently.
class SearchHit {
  final String group; // articles | mcqs | pyqs | current_affairs | entities
  final Map<String, dynamic> data;
  const SearchHit({required this.group, required this.data});

  int get id => data['id'] as int? ?? 0;
  String? get slug => data['slug'] as String?;
  String? get url => data['url'] as String?;
  String get title => (data['title'] ?? data['question'] ?? data['name'] ?? '').toString();
  String? get subtitle {
    if (group == 'articles') {
      final parts = [data['subject'], if (data['reading_time'] != null) '${data['reading_time']} min'].where((e) => e != null);
      return parts.isEmpty ? null : parts.join(' · ');
    }
    if (group == 'entities') return (data['type'] as String?)?.replaceAll('_', ' ');
    return null;
  }
}

class SearchResults {
  final String query;
  final Map<String, List<SearchHit>> groups;
  const SearchResults({required this.query, this.groups = const {}});

  bool get isEmpty => groups.values.every((g) => g.isEmpty);
  int get total => groups.values.fold(0, (n, g) => n + g.length);
}

/// Universal search across all content types. Empty/short queries short-circuit
/// to an empty result without hitting the network.
final searchProvider = FutureProvider.family<SearchResults, String>((ref, query) async {
  final q = query.trim();
  if (q.length < 2) return SearchResults(query: q);

  final res = await ApiClient.instance.get(ApiEndpoints.search(q));
  final raw = (res.data['results'] as Map?)?.cast<String, dynamic>() ?? const {};
  final groups = <String, List<SearchHit>>{};
  raw.forEach((group, items) {
    groups[group] = ((items as List?) ?? const [])
        .map((e) => SearchHit(group: group, data: (e as Map).cast<String, dynamic>()))
        .toList();
  });

  return SearchResults(query: res.data['query'] as String? ?? q, groups: groups);
});
