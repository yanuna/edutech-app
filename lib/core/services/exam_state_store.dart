import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/exam.dart';

/// Persists the active exam attempt on-device so it survives an app crash,
/// kill, force-close, or offline period and can be resumed exactly where the
/// user left off — current question, selected answers, question statuses and
/// the deadline (which yields the remaining time).
///
/// Answers are also synced to the server after every change; this local copy
/// is what makes resume work instantly and even fully offline.
class ExamStateStore {
  ExamStateStore._();
  static final ExamStateStore instance = ExamStateStore._();

  static const _key = 'active_exam_state';

  /// Saves the full attempt state. Called on every answer / mark / navigation.
  Future<void> save(ExamSession session, int currentIndex) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _key,
      jsonEncode({
        'session': session.toJson(),
        'current_index': currentIndex,
        'saved_at': DateTime.now().toIso8601String(),
      }),
    );
  }

  /// Returns the saved attempt if one exists and its window hasn't closed.
  /// Expired/corrupt state is cleared and treated as absent.
  Future<({ExamSession session, int currentIndex})?> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return null;
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      final session = ExamSession.fromJson(
        map['session'] as Map<String, dynamic>,
      );
      final deadline = DateTime.tryParse(session.endTimeDeadline);
      if (deadline != null && DateTime.now().isAfter(deadline)) {
        await clear();
        return null;
      }
      final idx = (map['current_index'] as int? ?? 0)
          .clamp(0, session.questions.length - 1);
      return (session: session, currentIndex: idx);
    } catch (_) {
      await clear();
      return null;
    }
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}
