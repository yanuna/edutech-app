import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/api_endpoints.dart';
import '../../../core/providers/catalog_provider.dart' show contentLanguageProvider;

/// A self-contained MCQ for review (question + options + correct answer +
/// explanation). Powers the Wrong-Questions bank and Bookmarked MCQs.
class ReviewQuestion {
  final int id;
  final String question;
  final List<String> options;
  final int correctOption; // 1-based
  final String? explanation;
  final String difficulty;

  const ReviewQuestion({
    required this.id,
    required this.question,
    required this.options,
    required this.correctOption,
    this.explanation,
    this.difficulty = 'medium',
  });

  factory ReviewQuestion.fromJson(Map<String, dynamic> j) => ReviewQuestion(
    id: j['id'] as int,
    question: j['question'] as String? ?? '',
    options: ((j['options'] as List?) ?? const []).map((e) => e.toString()).toList(),
    correctOption: j['correct_option'] as int? ?? 0,
    explanation: j['explanation'] as String?,
    difficulty: j['difficulty'] as String? ?? 'medium',
  );
}

Future<List<ReviewQuestion>> _fetch(Ref ref, String path) async {
  final lang = ref.watch(contentLanguageProvider);
  final res = await ApiClient.instance.get(path, params: {'lang': lang});
  return ((res.data['questions'] as List?) ?? const [])
      .map((e) => ReviewQuestion.fromJson((e as Map).cast<String, dynamic>()))
      .toList();
}

final wrongQuestionsProvider = FutureProvider.autoDispose<List<ReviewQuestion>>(
  (ref) => _fetch(ref, ApiEndpoints.wrongQuestions),
);

final bookmarkedQuestionsProvider = FutureProvider.autoDispose<List<ReviewQuestion>>(
  (ref) => _fetch(ref, ApiEndpoints.bookmarkedQuestions),
);
