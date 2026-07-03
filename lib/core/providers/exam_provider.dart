import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../api/api_client.dart';
import '../api/api_endpoints.dart';
import '../models/exam.dart';
import '../services/exam_state_store.dart';

// ─── Exam history ──────────────────────────────────────────────────────────

final examHistoryProvider = FutureProvider<List<ExamHistoryItem>>((ref) async {
  final res = await ApiClient.instance.get(ApiEndpoints.examHistory);
  return (res.data['data'] as List)
      .map((e) => ExamHistoryItem.fromJson(e as Map<String, dynamic>))
      .toList();
});

// ─── Active exam session (mutable state) ──────────────────────────────────

class ExamSessionNotifier extends StateNotifier<AsyncValue<ExamSession?>> {
  ExamSessionNotifier() : super(const AsyncValue.data(null));

  Future<void> generateExam({
    List<int>? subjectIds,
    List<int>? chapterIds,
    int count = 100,
  }) async {
    state = const AsyncValue.loading();
    try {
      final res = await ApiClient.instance.post(
        ApiEndpoints.generateExam,
        data: {
          'subject_ids': ?subjectIds,
          'chapter_ids': ?chapterIds,
          'count': count,
        },
      );
      state = AsyncValue.data(
        ExamSession.fromJson(res.data as Map<String, dynamic>),
      );
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> syncAnswers(
    int sessionId,
    List<Map<String, dynamic>> answers,
  ) async {
    if (state.valueOrNull == null || answers.isEmpty) return;
    try {
      // The backend caps each sync at 20 answers and requires
      // app_background_count, so send in chunks of 20.
      for (var i = 0; i < answers.length; i += 20) {
        final end = (i + 20) < answers.length ? i + 20 : answers.length;
        await ApiClient.instance.post(
          ApiEndpoints.syncExam(sessionId),
          data: {
            'answers': answers.sublist(i, end),
            'app_background_count': 0,
          },
        );
      }
    } catch (_) {}
  }

  void answerQuestion(int questionIndex, int shuffledOption) {
    final session = state.value;
    if (session == null) return;
    final q = session.questions[questionIndex];
    q.selectedOption = shuffledOption;
    q.status = 'answered';
    state = AsyncValue.data(
      ExamSession(
        sessionId: session.sessionId,
        endTimeDeadline: session.endTimeDeadline,
        requested: session.requested,
        delivered: session.delivered,
        shortageNotice: session.shortageNotice,
        questions: session.questions,
      ),
    );
  }

  void markForReview(int questionIndex) {
    final session = state.value;
    if (session == null) return;
    session.questions[questionIndex].status = 'marked_for_review';
    state = AsyncValue.data(
      ExamSession(
        sessionId: session.sessionId,
        endTimeDeadline: session.endTimeDeadline,
        requested: session.requested,
        delivered: session.delivered,
        shortageNotice: session.shortageNotice,
        questions: session.questions,
      ),
    );
  }

  Future<ExamResultSummary?> submitExam(int sessionId) async {
    try {
      final res = await ApiClient.instance.post(
        ApiEndpoints.submitExam(sessionId),
      );
      return ExamResultSummary.fromJson(res.data as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  /// Inject an already-started session (used by the Test Series flow, which
  /// starts/resumes attempts through its own endpoints but reuses ExamScreen).
  void setSession(ExamSession session) => state = AsyncValue.data(session);

  /// Restores an in-progress attempt from the server (answers, statuses and
  /// deadline) — used when resuming after a crash/restart with no in-memory
  /// state and no usable local copy.
  Future<void> loadResume(int sessionId) async {
    state = const AsyncValue.loading();
    try {
      final res = await ApiClient.instance.get(
        ApiEndpoints.resumeExam(sessionId),
      );
      state = AsyncValue.data(
        ExamSession.fromJson(res.data as Map<String, dynamic>),
      );
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  void clear() => state = const AsyncValue.data(null);
}

final examSessionProvider =
    StateNotifierProvider<ExamSessionNotifier, AsyncValue<ExamSession?>>(
      (_) => ExamSessionNotifier(),
    );

/// Session id of an in-progress attempt saved locally (crash recovery), or null.
/// Drives the "Resume exam" entry point so the user is taken straight back in.
final activeExamProvider = FutureProvider<int?>((ref) async {
  final saved = await ExamStateStore.instance.load();
  return saved?.session.sessionId;
});

// ─── Result provider ───────────────────────────────────────────────────────

final examResultProvider = FutureProvider.family<ExamResultSummary, int>((
  ref,
  sessionId,
) async {
  final res = await ApiClient.instance.get(ApiEndpoints.examResult(sessionId));
  return ExamResultSummary.fromJson(res.data as Map<String, dynamic>);
});
