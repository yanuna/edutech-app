import 'package:edutech_app/core/models/test_series.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('TestSeriesAttempt', () {
    test('parses a completed attempt', () {
      final a = TestSeriesAttempt.fromJson({
        'state': 'completed',
        'session_id': 42,
        'marks': 87.5,
        'is_ranked': true,
        'rank': 3,
        'percentile': 95.2,
      });
      expect(a.state, 'completed');
      expect(a.sessionId, 42);
      expect(a.marks, 87.5);
      expect(a.isRanked, isTrue);
      expect(a.rank, 3);
      expect(a.percentile, 95.2);
      expect(a.isCompleted, isTrue);
      expect(a.isInProgress, isFalse);
    });

    test('defaults to not_attempted on empty json', () {
      final a = TestSeriesAttempt.fromJson(const {});
      expect(a.state, 'not_attempted');
      expect(a.sessionId, isNull);
      expect(a.marks, isNull);
      expect(a.isRanked, isFalse);
      expect(a.isCompleted, isFalse);
      expect(a.isInProgress, isFalse);
    });

    test('reads integer marks as double', () {
      final a = TestSeriesAttempt.fromJson({'state': 'completed', 'marks': 40});
      expect(a.marks, 40.0);
      expect(a.marks, isA<double>());
    });
  });

  group('TestSeriesExam', () {
    Map<String, dynamic> baseJson() => {
      'id': 7,
      'name': 'Full Mock 1',
      'type': 'full',
      'total_questions': 100,
      'duration_minutes': 120,
      'start_at': '2026-06-01T10:00:00Z',
      'end_at': '2026-06-01T12:00:00Z',
      'status': 'live',
      'attempt': {'state': 'in_progress', 'session_id': 9},
    };

    test('parses a full exam with nested attempt', () {
      final e = TestSeriesExam.fromJson(baseJson());
      expect(e.id, 7);
      expect(e.name, 'Full Mock 1');
      expect(e.type, 'full');
      expect(e.totalQuestions, 100);
      expect(e.durationMinutes, 120);
      expect(e.startAt, DateTime.parse('2026-06-01T10:00:00Z'));
      expect(e.endAt, DateTime.parse('2026-06-01T12:00:00Z'));
      expect(e.attempt.sessionId, 9);
      expect(e.attempt.isInProgress, isTrue);
    });

    test('status getters are mutually exclusive', () {
      final live = TestSeriesExam.fromJson(baseJson()..['status'] = 'live');
      expect(live.isLive, isTrue);
      expect(live.isUpcoming, isFalse);
      expect(live.isExpired, isFalse);

      final upcoming = TestSeriesExam.fromJson(
        baseJson()..['status'] = 'upcoming',
      );
      expect(upcoming.isUpcoming, isTrue);
      expect(upcoming.isLive, isFalse);

      final expired = TestSeriesExam.fromJson(
        baseJson()..['status'] = 'expired',
      );
      expect(expired.isExpired, isTrue);
      expect(expired.isLive, isFalse);
    });

    test('falls back to defaults for missing optional fields', () {
      final e = TestSeriesExam.fromJson({
        'id': 1,
        'name': 'X',
        'type': 'part',
        'start_at': '2026-06-01T10:00:00Z',
        'end_at': '2026-06-01T12:00:00Z',
      });
      expect(e.totalQuestions, 0);
      expect(e.durationMinutes, 0);
      expect(e.status, 'upcoming');
      expect(e.attempt.state, 'not_attempted');
    });
  });

  group('ExamLeaderboard', () {
    test('parses entries and flags', () {
      final lb = ExamLeaderboard.fromJson({
        'exam_id': 5,
        'exam_name': 'Weekly',
        'rankings_generated': true,
        'leaderboard': [
          {'rank': 1, 'name': 'Asha', 'marks': 98, 'percentile': 99.9},
          {'rank': 2, 'name': 'Ravi', 'marks': 95},
        ],
      });
      expect(lb.examId, 5);
      expect(lb.rankingsGenerated, isTrue);
      expect(lb.entries, hasLength(2));
      expect(lb.entries.first.name, 'Asha');
      expect(lb.entries.first.percentile, 99.9);
      expect(lb.entries[1].percentile, isNull);
    });

    test('handles a missing leaderboard list', () {
      final lb = ExamLeaderboard.fromJson({'exam_id': 5});
      expect(lb.entries, isEmpty);
      expect(lb.examName, '');
      expect(lb.rankingsGenerated, isFalse);
    });

    test('LeaderboardEntry defaults an absent name to Student', () {
      final e = LeaderboardEntry.fromJson({'rank': 4});
      expect(e.name, 'Student');
      expect(e.marks, 0);
    });
  });
}
