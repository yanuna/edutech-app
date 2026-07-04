// Models for the Learn section's structured Articles (Content v2 backend).
// Body is a list of typed blocks the reader renders; related content powers
// the knowledge-graph section at the bottom of an article.

class ArticleCard {
  final int id;
  final String slug;
  final String title;
  final String? summary;
  final String? heroImage;
  final int? readingTime; // minutes
  final String difficulty; // easy | medium | hard
  final List<String> gsPaper;
  final bool isFeatured;
  final String? subjectName;
  final String? topicName;
  final String? publishedAt;

  const ArticleCard({
    required this.id,
    required this.slug,
    required this.title,
    this.summary,
    this.heroImage,
    this.readingTime,
    this.difficulty = 'medium',
    this.gsPaper = const [],
    this.isFeatured = false,
    this.subjectName,
    this.topicName,
    this.publishedAt,
  });

  factory ArticleCard.fromJson(Map<String, dynamic> j) => ArticleCard(
    id: j['id'] as int,
    slug: j['slug'] as String,
    title: j['title'] as String? ?? '',
    summary: j['summary'] as String?,
    heroImage: j['hero_image'] as String?,
    readingTime: j['reading_time'] as int?,
    // Normalise a null OR empty value to 'medium' — call sites index
    // difficulty[0], so an empty string would throw a RangeError.
    difficulty: (j['difficulty'] as String?)?.isNotEmpty == true
        ? j['difficulty'] as String
        : 'medium',
    gsPaper: ((j['gs_paper'] as List?) ?? const []).map((e) => e.toString()).toList(),
    isFeatured: j['is_featured'] as bool? ?? false,
    // `subject`/`topic` come as {id,name} from the article endpoints but as a
    // plain name string from bookmarks / continue-reading — accept both.
    subjectName: _name(j['subject']),
    topicName: _name(j['topic']),
    publishedAt: j['published_at'] as String?,
  );

  /// Accepts either a `{id, name}` object or a bare name string (or null).
  static String? _name(dynamic v) => v is Map ? v['name'] as String? : v as String?;
}

/// One typed content block, e.g. {type: 'rich_text', data: {html: '...'}}.
class ArticleBlock {
  final String type;
  final Map<String, dynamic> data;

  const ArticleBlock({required this.type, required this.data});

  factory ArticleBlock.fromJson(Map<String, dynamic> j) => ArticleBlock(
    type: j['type'] as String? ?? 'rich_text',
    data: (j['data'] as Map?)?.cast<String, dynamic>() ?? const {},
  );

  String? get string0 => data['html'] as String? ?? data['text'] as String?;
}

class ArticleTag {
  final int id;
  final String slug;
  final String name;
  final String type;
  const ArticleTag({required this.id, required this.slug, required this.name, required this.type});

  factory ArticleTag.fromJson(Map<String, dynamic> j) => ArticleTag(
    id: j['id'] as int,
    slug: j['slug'] as String? ?? '',
    name: j['name'] as String? ?? '',
    type: j['type'] as String? ?? 'general',
  );
}

/// A related-content item; kept loose (a map) so each group renders differently.
class RelatedItem {
  final String group; // articles | mcqs | pyqs | current_affairs
  final Map<String, dynamic> data;
  const RelatedItem({required this.group, required this.data});

  int get id => data['id'] as int? ?? 0;
  String get title => (data['title'] ?? data['question'] ?? '').toString();
  String? get slug => data['slug'] as String?;
  String? get url => data['url'] as String?;
}

class Article {
  final ArticleCard card;
  final List<ArticleBlock> body;
  final List<String> keywords;
  final String? prelimsRelevance;
  final String? mainsRelevance;
  final String? optionalRelevance;
  final String? source;
  final String? sourceUrl;
  final String? subtopicName;
  final List<ArticleTag> tags;
  final Map<String, List<RelatedItem>> related;

  const Article({
    required this.card,
    this.body = const [],
    this.keywords = const [],
    this.prelimsRelevance,
    this.mainsRelevance,
    this.optionalRelevance,
    this.source,
    this.sourceUrl,
    this.subtopicName,
    this.tags = const [],
    this.related = const {},
  });

  // Convenience passthroughs.
  int get id => card.id;
  String get slug => card.slug;
  String get title => card.title;

  factory Article.fromResponse(Map<String, dynamic> j) {
    final a = (j['article'] as Map).cast<String, dynamic>();
    final relatedRaw = (j['related'] as Map?)?.cast<String, dynamic>() ?? const {};
    final related = <String, List<RelatedItem>>{};
    relatedRaw.forEach((group, items) {
      related[group] = ((items as List?) ?? const [])
          .map((e) => RelatedItem(group: group, data: (e as Map).cast<String, dynamic>()))
          .toList();
    });

    return Article(
      card: ArticleCard.fromJson(a),
      body: ((a['body'] as List?) ?? const [])
          .map((e) => ArticleBlock.fromJson((e as Map).cast<String, dynamic>()))
          .toList(),
      keywords: ((a['keywords'] as List?) ?? const []).map((e) => e.toString()).toList(),
      prelimsRelevance: a['prelims_relevance'] as String?,
      mainsRelevance: a['mains_relevance'] as String?,
      optionalRelevance: a['optional_relevance'] as String?,
      source: a['source'] as String?,
      sourceUrl: a['source_url'] as String?,
      subtopicName: (a['subtopic'] as Map?)?['name'] as String?,
      tags: ((a['tags'] as List?) ?? const [])
          .map((e) => ArticleTag.fromJson((e as Map).cast<String, dynamic>()))
          .toList(),
      related: related,
    );
  }
}
