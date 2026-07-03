import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/api_endpoints.dart';
import '../../../core/providers/catalog_provider.dart' show contentLanguageProvider;

class PyqQuestion {
  final int id;
  final int year;
  final String question;
  final List<String> options;
  final int correctOption;
  final String? explanation;
  final String difficulty;

  const PyqQuestion({
    required this.id,
    required this.year,
    required this.question,
    required this.options,
    required this.correctOption,
    this.explanation,
    this.difficulty = 'medium',
  });

  factory PyqQuestion.fromJson(Map<String, dynamic> j) => PyqQuestion(
    id: j['id'] as int,
    year: j['year'] as int? ?? 0,
    question: j['question'] as String? ?? '',
    options: ((j['options'] as List?) ?? const []).map((e) => e.toString()).toList(),
    correctOption: j['correct_option'] as int? ?? 0,
    explanation: j['explanation'] as String?,
    difficulty: j['difficulty'] as String? ?? 'medium',
  );
}

/// Immutable, value-equal filter for the PYQ question bank.
class PyqFilter {
  final int? year;
  final int? subjectId;
  const PyqFilter({this.year, this.subjectId});

  Map<String, dynamic> toParams(String lang) => {
    'lang': lang,
    if (year != null) 'year': year,
    if (subjectId != null) 'subject_id': subjectId,
  };

  @override
  bool operator ==(Object other) => other is PyqFilter && other.year == year && other.subjectId == subjectId;
  @override
  int get hashCode => Object.hash(year, subjectId);
}

final pyqQuestionsProvider = FutureProvider.family<List<PyqQuestion>, PyqFilter>((ref, filter) async {
  final lang = ref.watch(contentLanguageProvider);
  final res = await ApiClient.instance.get(ApiEndpoints.pyqQuestions, params: filter.toParams(lang));
  return ((res.data['questions'] as List?) ?? const [])
      .map((e) => PyqQuestion.fromJson((e as Map).cast<String, dynamic>()))
      .toList();
});

class PyqFilters {
  final List<int> years;
  final List<({int id, String name})> subjects;
  const PyqFilters({this.years = const [], this.subjects = const []});
}

final pyqFiltersProvider = FutureProvider<PyqFilters>((ref) async {
  final res = await ApiClient.instance.get(ApiEndpoints.pyqFilters);
  return PyqFilters(
    years: ((res.data['years'] as List?) ?? const []).map((e) => e as int).toList(),
    subjects: ((res.data['subjects'] as List?) ?? const [])
        .map((e) => (id: (e as Map)['id'] as int, name: e['name'] as String))
        .toList(),
  );
});

class PyqTrends {
  final List<({int year, int count})> byYear;
  final List<({String subject, int count})> bySubject;
  final int total;
  const PyqTrends({this.byYear = const [], this.bySubject = const [], this.total = 0});
}

final pyqTrendsProvider = FutureProvider<PyqTrends>((ref) async {
  final res = await ApiClient.instance.get(ApiEndpoints.pyqTrends);
  return PyqTrends(
    total: res.data['total'] as int? ?? 0,
    byYear: ((res.data['by_year'] as List?) ?? const [])
        .map((e) => (year: (e as Map)['year'] as int, count: e['count'] as int))
        .toList(),
    bySubject: ((res.data['by_subject'] as List?) ?? const [])
        .map((e) => (subject: (e as Map)['subject'] as String, count: e['count'] as int))
        .toList(),
  );
});
