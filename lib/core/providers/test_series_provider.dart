import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../api/api_client.dart';
import '../api/api_endpoints.dart';
import '../models/exam.dart';
import '../models/test_series.dart';
import 'exam_provider.dart';

// ─── Listings ──────────────────────────────────────────────────────────────

/// Part/Full exam list. [type] is 'part', 'full' or '' (all).
final testSeriesListProvider =
    FutureProvider.family<List<TestSeriesExam>, String>((ref, type) async {
      final url = type.isEmpty
          ? ApiEndpoints.testSeries
          : ApiEndpoints.testSeriesByType(type);
      final res = await ApiClient.instance.get(url);
      return (res.data['data'] as List)
          .map((e) => TestSeriesExam.fromJson(e as Map<String, dynamic>))
          .toList();
    });

final examLeaderboardProvider = FutureProvider.family<ExamLeaderboard, int>((
  ref,
  examId,
) async {
  final res = await ApiClient.instance.get(
    ApiEndpoints.testSeriesLeaderboard(examId),
  );
  return ExamLeaderboard.fromJson(res.data as Map<String, dynamic>);
});

final testSeriesHistoryProvider = FutureProvider<List<TestSeriesHistoryItem>>((
  ref,
) async {
  final res = await ApiClient.instance.get(ApiEndpoints.testSeriesHistory);
  return (res.data['data'] as List)
      .map((e) => TestSeriesHistoryItem.fromJson(e as Map<String, dynamic>))
      .toList();
});

// ─── Starting / resuming an attempt ────────────────────────────────────────

enum StartKind { started, resume, attempted, error }

class StartResult {
  final StartKind kind;
  final int? sessionId;
  final String? message;
  const StartResult(this.kind, {this.sessionId, this.message});
}

/// Starts (or resumes) a Test Series attempt. On success it populates the
/// shared [examSessionProvider] so the existing ExamScreen can take over.
final testSeriesControllerProvider = Provider<TestSeriesController>((ref) {
  return TestSeriesController(ref);
});

class TestSeriesController {
  TestSeriesController(this._ref);
  final Ref _ref;

  Future<StartResult> start(int examId) async {
    try {
      final res = await ApiClient.instance.post(
        ApiEndpoints.startTestSeries(examId),
      );
      final data = res.data as Map<String, dynamic>;

      // 201 → a fresh attempt with the full question payload.
      if (data.containsKey('questions')) {
        _ref
            .read(examSessionProvider.notifier)
            .setSession(ExamSession.fromJson(data));
        return StartResult(
          StartKind.started,
          sessionId: data['session_id'] as int,
        );
      }

      // 200 → an in-progress attempt to resume.
      return StartResult(
        StartKind.resume,
        sessionId: data['session_id'] as int?,
      );
    } on DioException catch (e) {
      final code = e.response?.statusCode;
      final data = e.response?.data;
      if (code == 409) {
        return StartResult(
          StartKind.attempted,
          sessionId: data is Map ? data['session_id'] as int? : null,
        );
      }
      return StartResult(StartKind.error, message: apiErrorMessage(e));
    }
  }

  /// Loads an in-progress session's questions (via /resume) into state so
  /// ExamScreen can continue it.
  Future<bool> loadForResume(int sessionId) async {
    try {
      final res = await ApiClient.instance.get(
        ApiEndpoints.resumeExam(sessionId),
      );
      _ref
          .read(examSessionProvider.notifier)
          .setSession(ExamSession.fromJson(res.data as Map<String, dynamic>));
      return true;
    } catch (_) {
      return false;
    }
  }
}
