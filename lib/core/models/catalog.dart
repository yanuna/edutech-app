class Subject {
  final int id;
  final String name;
  final String? thumbnailImage;
  final bool isPaid;
  final int order;

  const Subject({
    required this.id,
    required this.name,
    this.thumbnailImage,
    required this.isPaid,
    required this.order,
  });

  factory Subject.fromJson(Map<String, dynamic> j) => Subject(
    id: j['id'] as int,
    name: j['name'] as String,
    thumbnailImage: j['thumbnail_image'] as String?,
    isPaid: j['is_paid'] as bool? ?? false,
    order: j['order'] as int? ?? 0,
  );
}

class Chapter {
  final int id;
  final int subjectId;
  final String name;
  final String? thumbnailImage;
  final bool isPaid;
  final int order;

  const Chapter({
    required this.id,
    required this.subjectId,
    required this.name,
    this.thumbnailImage,
    required this.isPaid,
    required this.order,
  });

  factory Chapter.fromJson(Map<String, dynamic> j) => Chapter(
    id: j['id'] as int,
    subjectId: j['subject_id'] as int,
    name: j['name'] as String,
    thumbnailImage: j['thumbnail_image'] as String?,
    isPaid: j['is_paid'] as bool? ?? false,
    order: j['order'] as int? ?? 0,
  );
}

class Topic {
  final int id;
  final int chapterId;
  final String name;
  final String? thumbnailImage;
  final bool isPaid;
  final int order;

  const Topic({
    required this.id,
    required this.chapterId,
    required this.name,
    this.thumbnailImage,
    required this.isPaid,
    required this.order,
  });

  factory Topic.fromJson(Map<String, dynamic> j) => Topic(
    id: j['id'] as int,
    chapterId: j['chapter_id'] as int,
    name: j['name'] as String,
    thumbnailImage: j['thumbnail_image'] as String?,
    isPaid: j['is_paid'] as bool? ?? false,
    order: j['order'] as int? ?? 0,
  );
}

class TopicContent {
  final int id;
  final String contentType;
  final String? title;
  final String? youtubeVideoId;
  final String? htmlContent;
  // Backend returns `file_urls`: a JSON array of signed URLs (one per file).
  final List<String> fileUrls;
  final int order;

  const TopicContent({
    required this.id,
    required this.contentType,
    this.title,
    this.youtubeVideoId,
    this.htmlContent,
    this.fileUrls = const [],
    required this.order,
  });

  // Convenience: first file URL, or null when there are none.
  String? get fileUrl => fileUrls.isNotEmpty ? fileUrls.first : null;

  factory TopicContent.fromJson(Map<String, dynamic> j) => TopicContent(
    id: j['id'] as int,
    contentType: j['content_type'] as String,
    title: j['title'] as String?,
    youtubeVideoId: j['youtube_video_id'] as String?,
    htmlContent: j['html_content'] as String?,
    fileUrls:
        (j['file_urls'] as List?)?.map((e) => e.toString()).toList() ??
        const [],
    order: j['order'] as int? ?? 0,
  );
}
