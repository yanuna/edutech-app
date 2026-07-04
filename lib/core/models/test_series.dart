/// Models for the Test Series feature (admin-created Part/Full exams).
library;

/// Tolerant date parse: falls back to `now` for a null/missing/malformed value
/// so a bad payload can't crash list rendering. Display-only — the exam's
/// live/upcoming/expired state comes from the separate `status` field.
DateTime _parseDate(dynamic value) {
  if (value == null) return DateTime.now();
  return DateTime.tryParse(value.toString()) ?? DateTime.now();
}

class TestSeriesAttempt {
  final String state; // not_attempted | in_progress | completed
  final int? sessionId;
  final double? marks;
  final bool isRanked;
  final int? rank;
  final double? percentile;

  const TestSeriesAttempt({
    required this.state,
    this.sessionId,
    this.marks,
    this.isRanked = false,
    this.rank,
    this.percentile,
  });

  bool get isCompleted => state == 'completed';
  bool get isInProgress => state == 'in_progress';

  factory TestSeriesAttempt.fromJson(Map<String, dynamic> j) =>
      TestSeriesAttempt(
        state: j['state'] as String? ?? 'not_attempted',
        sessionId: j['session_id'] as int?,
        marks: (j['marks'] as num?)?.toDouble(),
        isRanked: j['is_ranked'] as bool? ?? false,
        rank: j['rank'] as int?,
        percentile: (j['percentile'] as num?)?.toDouble(),
      );
}

class TestSeriesExam {
  final int id;
  final String name;
  final String type; // part | full
  final int totalQuestions;
  final int durationMinutes;
  final DateTime startAt;
  final DateTime endAt;
  final String status; // upcoming | live | expired
  final TestSeriesAttempt attempt;

  const TestSeriesExam({
    required this.id,
    required this.name,
    required this.type,
    required this.totalQuestions,
    required this.durationMinutes,
    required this.startAt,
    required this.endAt,
    required this.status,
    required this.attempt,
  });

  bool get isUpcoming => status == 'upcoming';
  bool get isLive => status == 'live';
  bool get isExpired => status == 'expired';

  factory TestSeriesExam.fromJson(Map<String, dynamic> j) => TestSeriesExam(
    id: j['id'] as int,
    name: j['name'] as String,
    type: j['type'] as String,
    totalQuestions: j['total_questions'] as int? ?? 0,
    durationMinutes: j['duration_minutes'] as int? ?? 0,
    startAt: _parseDate(j['start_at']),
    endAt: _parseDate(j['end_at']),
    status: j['status'] as String? ?? 'upcoming',
    attempt: TestSeriesAttempt.fromJson(
      (j['attempt'] as Map<String, dynamic>?) ?? const {},
    ),
  );
}

class LeaderboardEntry {
  final int rank;
  final String name;
  final double marks;
  final double? percentile;

  const LeaderboardEntry({
    required this.rank,
    required this.name,
    required this.marks,
    this.percentile,
  });

  factory LeaderboardEntry.fromJson(Map<String, dynamic> j) => LeaderboardEntry(
    rank: j['rank'] as int,
    name: j['name'] as String? ?? 'Student',
    marks: (j['marks'] as num?)?.toDouble() ?? 0,
    percentile: (j['percentile'] as num?)?.toDouble(),
  );
}

class ExamLeaderboard {
  final int examId;
  final String examName;
  final bool rankingsGenerated;
  final List<LeaderboardEntry> entries;

  const ExamLeaderboard({
    required this.examId,
    required this.examName,
    required this.rankingsGenerated,
    required this.entries,
  });

  factory ExamLeaderboard.fromJson(Map<String, dynamic> j) => ExamLeaderboard(
    examId: j['exam_id'] as int,
    examName: j['exam_name'] as String? ?? '',
    rankingsGenerated: j['rankings_generated'] as bool? ?? false,
    entries: (j['leaderboard'] as List? ?? [])
        .map((e) => LeaderboardEntry.fromJson(e as Map<String, dynamic>))
        .toList(),
  );
}

class TestSeriesHistoryItem {
  final int sessionId;
  final int examId;
  final String examName;
  final String type;
  final DateTime attemptDate;
  final double marks;
  final int? rank;
  final bool isRanked;
  final double? percentile;
  final String status; // expired | completed

  const TestSeriesHistoryItem({
    required this.sessionId,
    required this.examId,
    required this.examName,
    required this.type,
    required this.attemptDate,
    required this.marks,
    this.rank,
    required this.isRanked,
    this.percentile,
    required this.status,
  });

  factory TestSeriesHistoryItem.fromJson(Map<String, dynamic> j) =>
      TestSeriesHistoryItem(
        sessionId: j['session_id'] as int,
        examId: j['exam_id'] as int,
        examName: j['exam_name'] as String? ?? 'Exam',
        type: j['type'] as String? ?? 'full',
        attemptDate: _parseDate(j['attempt_date']),
        marks: (j['marks'] as num?)?.toDouble() ?? 0,
        rank: j['rank'] as int?,
        isRanked: j['is_ranked'] as bool? ?? false,
        percentile: (j['percentile'] as num?)?.toDouble(),
        status: j['status'] as String? ?? 'completed',
      );
}
