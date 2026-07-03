import 'package:edutech_app/core/models/exam.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ExamQuestion', () {
    ExamQuestion build() => ExamQuestion.fromJson({
      'question_id': 1,
      'question_text': 'Capital of France?',
      'option_1': 'Paris',
      'option_2': 'Rome',
      'option_3': 'Berlin',
      'option_4': 'Madrid',
      'hint': '  City of lights  ',
    });

    test('optionText maps positions to the right option', () {
      final q = build();
      expect(q.optionText(1), 'Paris');
      expect(q.optionText(2), 'Rome');
      expect(q.optionText(3), 'Berlin');
      expect(q.optionText(4), 'Madrid');
      expect(q.optionText(0), '');
      expect(q.optionText(99), '');
    });

    test('hasHint is true only for non-blank hints', () {
      expect(build().hasHint, isTrue);
      final noHint = ExamQuestion.fromJson({
        'question_id': 2,
        'question_text': 'Q',
        'option_1': 'a',
        'option_2': 'b',
        'option_3': 'c',
        'option_4': 'd',
        'hint': '   ',
      });
      expect(noHint.hasHint, isFalse);
    });

    test('defaults status to unattempted and reads prior answer', () {
      final q = ExamQuestion.fromJson({
        'question_id': 3,
        'question_text': 'Q',
        'option_1': 'a',
        'option_2': 'b',
        'option_3': 'c',
        'option_4': 'd',
        'already_answered_shuffled': 2,
      });
      expect(q.status, 'unattempted');
      expect(q.selectedOption, 2);
    });
  });

  group('ExamResultSummary', () {
    Map<String, dynamic> base() => {
      'session_id': 100,
      'status': 'completed',
      'summary': {
        'total_score': 75.5,
        'total_correct': 30,
        'total_incorrect': 10,
        'total_unattempted': 10,
        'accuracy_percentage': 75.0,
      },
      'subject_breakdown': [
        {
          'subject_id': 1,
          'subject_name': 'Maths',
          'total_questions': 50,
          'correct': 30,
          'incorrect': 10,
          'unattempted': 10,
          'score': 75.5,
          'accuracy_pct': 75.0,
        },
      ],
      'questions': [
        {
          'question_id': 1,
          'question_text': 'Q',
          'shuffled_options': {'1': 'a', '2': 'b'},
          'user_selected_shuffled': 1,
          'correct_shuffled_option': 1,
          'is_correct': true,
          'marks_awarded': 2.0,
          'status': 'answered',
        },
      ],
    };

    test('parses a regular (non test-series) result', () {
      final r = ExamResultSummary.fromJson(base());
      expect(r.sessionId, 100);
      expect(r.totalScore, 75.5);
      expect(r.totalCorrect, 30);
      expect(r.subjectBreakdown, hasLength(1));
      expect(r.subjectBreakdown.first.subjectName, 'Maths');
      expect(r.questions, hasLength(1));
      expect(r.questions.first.shuffledOptions['2'], 'b');
      expect(r.isTestSeries, isFalse);
    });

    test('isTestSeries is true when an exam block is present', () {
      final json = base()
        ..['exam'] = {
          'exam_name': 'Mock 1',
          'is_ranked': true,
          'rank': 4,
          'percentile': 88.0,
          'ranking_pending': false,
        };
      final r = ExamResultSummary.fromJson(json);
      expect(r.isTestSeries, isTrue);
      expect(r.examName, 'Mock 1');
      expect(r.examIsRanked, isTrue);
      expect(r.examRank, 4);
      expect(r.examPercentile, 88.0);
    });
  });

  group('ExamHistoryItem', () {
    test('flattens nested result fields and tolerates a null result', () {
      final withResult = ExamHistoryItem.fromJson({
        'id': 1,
        'status': 'completed',
        'start_time': '2026-06-01T10:00:00Z',
        'result': {'total_score': 60, 'total_correct': 20},
      });
      expect(withResult.totalScore, 60.0);
      expect(withResult.totalCorrect, 20);

      final noResult = ExamHistoryItem.fromJson({
        'id': 2,
        'status': 'in_progress',
        'start_time': '2026-06-01T10:00:00Z',
      });
      expect(noResult.totalScore, isNull);
      expect(noResult.totalCorrect, isNull);
    });
  });
}
