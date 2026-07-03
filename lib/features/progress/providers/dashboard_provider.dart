import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/api_endpoints.dart';

class SubjectPerf {
  final String subject;
  final int attempted;
  final int correct;
  final double accuracy;
  const SubjectPerf({required this.subject, required this.attempted, required this.correct, required this.accuracy});

  factory SubjectPerf.fromJson(Map<String, dynamic> j) => SubjectPerf(
    subject: j['subject'] as String? ?? '',
    attempted: j['attempted'] as int? ?? 0,
    correct: j['correct'] as int? ?? 0,
    accuracy: (j['accuracy'] as num?)?.toDouble() ?? 0,
  );
}

class DashboardData {
  final int articlesRead;
  final int articlesCompleted;
  final int readingMinutes;
  final int testsTaken;
  final int questionsAttempted;
  final int correct;
  final double accuracy;
  final int streakCurrent;
  final int streakLongest;
  final int xp;
  final List<SubjectPerf> subjects;
  final List<SubjectPerf> weakAreas;

  const DashboardData({
    this.articlesRead = 0,
    this.articlesCompleted = 0,
    this.readingMinutes = 0,
    this.testsTaken = 0,
    this.questionsAttempted = 0,
    this.correct = 0,
    this.accuracy = 0,
    this.streakCurrent = 0,
    this.streakLongest = 0,
    this.xp = 0,
    this.subjects = const [],
    this.weakAreas = const [],
  });

  bool get hasActivity => articlesRead > 0 || testsTaken > 0;

  factory DashboardData.fromJson(Map<String, dynamic> j) {
    final r = (j['reading'] as Map?)?.cast<String, dynamic>() ?? const {};
    final p = (j['practice'] as Map?)?.cast<String, dynamic>() ?? const {};
    final s = (j['streak'] as Map?)?.cast<String, dynamic>() ?? const {};
    List<SubjectPerf> parse(String key) => ((j[key] as List?) ?? const [])
        .map((e) => SubjectPerf.fromJson((e as Map).cast<String, dynamic>()))
        .toList();

    return DashboardData(
      articlesRead: r['articles_read'] as int? ?? 0,
      articlesCompleted: r['articles_completed'] as int? ?? 0,
      readingMinutes: r['minutes'] as int? ?? 0,
      testsTaken: p['tests_taken'] as int? ?? 0,
      questionsAttempted: p['questions_attempted'] as int? ?? 0,
      correct: p['correct'] as int? ?? 0,
      accuracy: (p['accuracy'] as num?)?.toDouble() ?? 0,
      streakCurrent: s['current'] as int? ?? 0,
      streakLongest: s['longest'] as int? ?? 0,
      xp: j['xp'] as int? ?? 0,
      subjects: parse('subjects'),
      weakAreas: parse('weak_areas'),
    );
  }
}

final dashboardProvider = FutureProvider.autoDispose<DashboardData>((ref) async {
  final res = await ApiClient.instance.get(ApiEndpoints.dashboard);
  return DashboardData.fromJson((res.data as Map).cast<String, dynamic>());
});
