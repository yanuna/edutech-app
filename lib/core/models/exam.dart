class ExamQuestion {
  final int questionId;
  final String questionText;
  final String option1;
  final String option2;
  final String option3;
  final String option4;
  final String? hint;
  int? selectedOption; // shuffled position (1-4)
  String status; // unattempted | answered | marked_for_review

  ExamQuestion({
    required this.questionId,
    required this.questionText,
    required this.option1,
    required this.option2,
    required this.option3,
    required this.option4,
    this.hint,
    this.selectedOption,
    this.status = 'unattempted',
  });

  bool get hasHint => hint != null && hint!.trim().isNotEmpty;

  factory ExamQuestion.fromJson(Map<String, dynamic> j) => ExamQuestion(
    questionId: j['question_id'] as int,
    questionText: j['question_text'] as String,
    option1: j['option_1'] as String,
    option2: j['option_2'] as String,
    option3: j['option_3'] as String,
    option4: j['option_4'] as String,
    hint: j['hint'] as String?,
    selectedOption: j['already_answered_shuffled'] as int?,
    status: j['status'] as String? ?? 'unattempted',
  );

  String optionText(int pos) {
    return switch (pos) {
      1 => option1,
      2 => option2,
      3 => option3,
      4 => option4,
      _ => '',
    };
  }

  // Round-trips with [fromJson] for local crash-recovery persistence.
  Map<String, dynamic> toJson() => {
    'question_id': questionId,
    'question_text': questionText,
    'option_1': option1,
    'option_2': option2,
    'option_3': option3,
    'option_4': option4,
    'hint': hint,
    'already_answered_shuffled': selectedOption,
    'status': status,
  };
}

class ExamSession {
  final int sessionId;
  final String endTimeDeadline;
  final int requested;
  final int delivered;
  final String? shortageNotice;
  final List<ExamQuestion> questions;

  const ExamSession({
    required this.sessionId,
    required this.endTimeDeadline,
    required this.requested,
    required this.delivered,
    this.shortageNotice,
    required this.questions,
  });

  factory ExamSession.fromJson(Map<String, dynamic> j) => ExamSession(
    sessionId: j['session_id'] as int,
    endTimeDeadline: j['end_time_deadline'] as String,
    requested: j['requested'] as int? ?? 100,
    delivered: j['delivered'] as int? ?? 0,
    shortageNotice: j['shortage_notice'] as String?,
    questions: (j['questions'] as List)
        .map((q) => ExamQuestion.fromJson(q as Map<String, dynamic>))
        .toList(),
  );

  // Round-trips with [fromJson] for local crash-recovery persistence.
  Map<String, dynamic> toJson() => {
    'session_id': sessionId,
    'end_time_deadline': endTimeDeadline,
    'requested': requested,
    'delivered': delivered,
    'shortage_notice': shortageNotice,
    'questions': questions.map((q) => q.toJson()).toList(),
  };
}

class ExamResultSummary {
  final int sessionId;
  final String status;
  final double totalScore;
  final int totalCorrect;
  final int totalIncorrect;
  final int totalUnattempted;
  final double accuracyPercentage;
  final List<SubjectBreakdown> subjectBreakdown;
  final List<QuestionDetail> questions;

  // Present only for Test Series attempts.
  final String? examName;
  final bool examIsRanked;
  final int? examRank;
  final double? examPercentile;
  final bool examRankingPending;

  const ExamResultSummary({
    required this.sessionId,
    required this.status,
    required this.totalScore,
    required this.totalCorrect,
    required this.totalIncorrect,
    required this.totalUnattempted,
    required this.accuracyPercentage,
    required this.subjectBreakdown,
    required this.questions,
    this.examName,
    this.examIsRanked = false,
    this.examRank,
    this.examPercentile,
    this.examRankingPending = false,
  });

  bool get isTestSeries => examName != null;

  factory ExamResultSummary.fromJson(Map<String, dynamic> j) {
    final summary = j['summary'] as Map<String, dynamic>;
    final exam = j['exam'] as Map<String, dynamic>?;
    return ExamResultSummary(
      sessionId: j['session_id'] as int,
      status: j['status'] as String,
      totalScore: (summary['total_score'] as num).toDouble(),
      totalCorrect: summary['total_correct'] as int,
      totalIncorrect: summary['total_incorrect'] as int,
      totalUnattempted: summary['total_unattempted'] as int,
      accuracyPercentage: (summary['accuracy_percentage'] as num).toDouble(),
      subjectBreakdown: (j['subject_breakdown'] as List)
          .map((s) => SubjectBreakdown.fromJson(s as Map<String, dynamic>))
          .toList(),
      questions: (j['questions'] as List)
          .map((q) => QuestionDetail.fromJson(q as Map<String, dynamic>))
          .toList(),
      examName: exam?['exam_name'] as String?,
      examIsRanked: exam?['is_ranked'] as bool? ?? false,
      examRank: exam?['rank'] as int?,
      examPercentile: (exam?['percentile'] as num?)?.toDouble(),
      examRankingPending: exam?['ranking_pending'] as bool? ?? false,
    );
  }
}

class SubjectBreakdown {
  final int subjectId;
  final String subjectName;
  final int totalQuestions;
  final int correct;
  final int incorrect;
  final int unattempted;
  final double score;
  final double accuracyPct;

  const SubjectBreakdown({
    required this.subjectId,
    required this.subjectName,
    required this.totalQuestions,
    required this.correct,
    required this.incorrect,
    required this.unattempted,
    required this.score,
    required this.accuracyPct,
  });

  factory SubjectBreakdown.fromJson(Map<String, dynamic> j) => SubjectBreakdown(
    subjectId: j['subject_id'] as int,
    subjectName: j['subject_name'] as String,
    totalQuestions: j['total_questions'] as int,
    correct: j['correct'] as int,
    incorrect: j['incorrect'] as int,
    unattempted: j['unattempted'] as int,
    score: (j['score'] as num).toDouble(),
    accuracyPct: (j['accuracy_pct'] as num).toDouble(),
  );
}

class QuestionDetail {
  final int questionId;
  final String questionText;
  final Map<String, String> shuffledOptions;
  final int? userSelectedShuffled;
  final int? correctShuffledOption;
  final bool? isCorrect;
  final double marksAwarded;
  final String status;
  final String? explanation;

  const QuestionDetail({
    required this.questionId,
    required this.questionText,
    required this.shuffledOptions,
    this.userSelectedShuffled,
    this.correctShuffledOption,
    this.isCorrect,
    required this.marksAwarded,
    required this.status,
    this.explanation,
  });

  factory QuestionDetail.fromJson(Map<String, dynamic> j) {
    final opts = (j['shuffled_options'] as Map<String, dynamic>?) ?? {};
    return QuestionDetail(
      questionId: j['question_id'] as int,
      questionText: j['question_text'] as String,
      shuffledOptions: opts.map((k, v) => MapEntry(k, v.toString())),
      userSelectedShuffled: j['user_selected_shuffled'] as int?,
      correctShuffledOption: j['correct_shuffled_option'] as int?,
      isCorrect: j['is_correct'] as bool?,
      marksAwarded: (j['marks_awarded'] as num?)?.toDouble() ?? 0,
      status: j['status'] as String? ?? 'unattempted',
      explanation: j['explanation'] as String?,
    );
  }
}

class ExamHistoryItem {
  final int id;
  final String status;
  final String startTime;
  final double? totalScore;
  final int? totalCorrect;

  const ExamHistoryItem({
    required this.id,
    required this.status,
    required this.startTime,
    this.totalScore,
    this.totalCorrect,
  });

  factory ExamHistoryItem.fromJson(Map<String, dynamic> j) {
    final result = j['result'] as Map<String, dynamic>?;
    return ExamHistoryItem(
      id: j['id'] as int,
      status: j['status'] as String,
      startTime: j['start_time'] as String,
      totalScore: (result?['total_score'] as num?)?.toDouble(),
      totalCorrect: result?['total_correct'] as int?,
    );
  }
}
