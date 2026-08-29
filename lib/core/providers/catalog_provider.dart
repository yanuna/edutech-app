import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../api/api_client.dart';
import '../api/api_endpoints.dart';
import '../models/catalog.dart';

// ─── Study-material language (English / Hindi), persisted ───────────────────
class ContentLanguageNotifier extends StateNotifier<String> {
  ContentLanguageNotifier() : super('en') {
    SharedPreferences.getInstance().then(
      (p) => state = p.getString('content_lang') ?? 'en',
    );
  }

  Future<void> set(String lang) async {
    state = lang;
    final p = await SharedPreferences.getInstance();
    await p.setString('content_lang', lang);
  }
}

final contentLanguageProvider =
    StateNotifierProvider<ContentLanguageNotifier, String>(
      (ref) => ContentLanguageNotifier(),
    );

// ─── Subjects ──────────────────────────────────────────────────────────────

final subjectsProvider = FutureProvider<List<Subject>>((ref) async {
  final res = await ApiClient.instance.get(ApiEndpoints.subjects);
  return (res.data['subjects'] as List)
      .map((e) => Subject.fromJson(e as Map<String, dynamic>))
      .toList();
});

// ─── Chapters for a subject ────────────────────────────────────────────────

final chaptersProvider = FutureProvider.family<List<Chapter>, int>((
  ref,
  subjectId,
) async {
  final res = await ApiClient.instance.get(ApiEndpoints.chapters(subjectId));
  return (res.data['chapters'] as List)
      .map((e) => Chapter.fromJson(e as Map<String, dynamic>))
      .toList();
});

// ─── Topics for a chapter ──────────────────────────────────────────────────

final topicsProvider = FutureProvider.family<List<Topic>, int>((
  ref,
  chapterId,
) async {
  final res = await ApiClient.instance.get(ApiEndpoints.topics(chapterId));
  return (res.data['topics'] as List)
      .map((e) => Topic.fromJson(e as Map<String, dynamic>))
      .toList();
});

// ─── Content for a topic ──────────────────────────────────────────────────

final topicContentProvider =
    FutureProvider.family<TopicContentBundle, int>((ref, topicId) async {
  final lang = ref.watch(
    contentLanguageProvider,
  ); // re-fetches on language change
  final res = await ApiClient.instance.get(
    ApiEndpoints.topicContent(topicId),
    params: {'lang': lang},
  );
  // The whole response is kept, not just `contents` — `topic.is_paid` is what
  // decides whether the paywall belongs on screen.
  return TopicContentBundle.fromJson(Map<String, dynamic>.from(res.data as Map));
});
