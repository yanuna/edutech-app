import 'dart:async';

import 'package:dio/dio.dart';
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

  // ─── Answer sync ─────────────────────────────────────────────────────────
  //
  // This used to resend EVERY answered question on every single tap, chunked at
  // 20 per request. On a 100-question paper that meant 5 POSTs per tap once the
  // student had answered ~80 — and /exam/{id}/sync is throttled at 30/min, so
  // after six taps every further sync came back 429. The failure was swallowed
  // by `catch (_) {}`, nothing showed on screen, and because scoring reads
  // ExamSessionQuestion.selected_option (which only sync writes), every
  // unsynced answer scored ZERO. The student got a wrong result and no warning.
  //
  // Now: only questions that actually changed are sent, coalesced by a short
  // debounce, with backoff on 429 and a hard flush before submission.

  final Set<int> _dirty = <int>{};
  Timer? _syncDebounce;
  bool _syncing = false;

  /// Times the app has been sent to the background during this attempt.
  /// The server auto-submits past 3 — it used to be hardcoded to 0 here, so the
  /// anti-cheat rule could never fire.
  int appBackgroundCount = 0;

  /// True when the last sync attempt failed and changes are still unsent.
  bool get hasUnsyncedAnswers => _dirty.isNotEmpty;

  void _markDirty(int questionId) {
    _dirty.add(questionId);
  }

  /// Queue a sync of the changed answers. Safe to call on every tap.
  void scheduleSync(int sessionId, {Duration delay = const Duration(seconds: 2)}) {
    _syncDebounce?.cancel();
    _syncDebounce = Timer(delay, () => _pushDirty(sessionId));
  }

  /// Send everything outstanding and report whether the server has it all.
  /// Awaited before submitting, so an exam can never be graded on a partial set.
  Future<bool> flushAnswers(int sessionId) async {
    _syncDebounce?.cancel();
    return _pushDirty(sessionId, attempts: 4);
  }

  Future<bool> _pushDirty(int sessionId, {int attempts = 2}) async {
    final session = state.valueOrNull;
    if (session == null) return true;
    if (_dirty.isEmpty) return true;
    if (_syncing) return false;

    _syncing = true;
    try {
      // Snapshot the dirty set; anything answered while this request is in
      // flight stays marked and goes out on the next pass.
      final pending = _dirty.toList();
      final byId = {for (final q in session.questions) q.questionId: q};

      final payload = <Map<String, dynamic>>[];
      for (final id in pending) {
        final q = byId[id];
        if (q == null) continue;
        payload.add({
          'question_id': q.questionId,
          'selected_option': q.selectedOption,
          // Include marked-for-review questions even with no selection —
          // otherwise review marks were lost on a crash-and-resume.
          'status': q.status,
        });
      }

      if (payload.isEmpty) {
        _dirty.removeAll(pending);
        return true;
      }

      var ok = true;
      for (var i = 0; i < payload.length; i += 20) {
        final end = (i + 20) < payload.length ? i + 20 : payload.length;
        final chunk = payload.sublist(i, end);

        final sent = await _postChunk(sessionId, chunk, attempts);
        if (sent) {
          for (final a in chunk) {
            _dirty.remove(a['question_id'] as int);
          }
        } else {
          ok = false;
          break; // keep the rest dirty; a later flush retries in order
        }
      }
      return ok;
    } finally {
      _syncing = false;
    }
  }

  Future<bool> _postChunk(
    int sessionId,
    List<Map<String, dynamic>> chunk,
    int attempts,
  ) async {
    for (var attempt = 0; attempt < attempts; attempt++) {
      try {
        await ApiClient.instance.post(
          ApiEndpoints.syncExam(sessionId),
          data: {
            'answers': chunk,
            'app_background_count': appBackgroundCount,
          },
        );
        return true;
      } on DioException catch (e) {
        final status = e.response?.statusCode;

        // 422 means the server rejected the shape — retrying cannot help.
        if (status == 422) return false;

        final isLast = attempt == attempts - 1;
        if (isLast) return false;

        // Back off on rate limiting and transient network errors.
        await Future<void>.delayed(Duration(milliseconds: 600 * (1 << attempt)));
      } catch (_) {
        if (attempt == attempts - 1) return false;
        await Future<void>.delayed(Duration(milliseconds: 600 * (1 << attempt)));
      }
    }
    return false;
  }

  /// Kept for callers that still pass an explicit list (e.g. resume flows).
  Future<void> syncAnswers(
    int sessionId,
    List<Map<String, dynamic>> answers,
  ) async {
    if (state.valueOrNull == null || answers.isEmpty) return;
    for (final a in answers) {
      final id = a['question_id'];
      if (id is int) _dirty.add(id);
    }
    await _pushDirty(sessionId);
  }

  @override
  void dispose() {
    _syncDebounce?.cancel();
    super.dispose();
  }

  void answerQuestion(int questionIndex, int shuffledOption) {
    final session = state.value;
    if (session == null) return;
    final q = session.questions[questionIndex];
    q.selectedOption = shuffledOption;
    q.status = 'answered';
    _markDirty(q.questionId);
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
    _markDirty(session.questions[questionIndex].questionId);
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
  void setSession(ExamSession session) {
    _dirty.clear();
    appBackgroundCount = 0;
    state = AsyncValue.data(session);
  }

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

  void clear() {
    _syncDebounce?.cancel();
    _dirty.clear();
    appBackgroundCount = 0;
    state = const AsyncValue.data(null);
  }
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
