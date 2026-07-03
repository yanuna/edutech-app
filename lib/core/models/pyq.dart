/// A single Previous-Year-Question paper (question paper + solution, EN & HI),
/// filed under a year and one of the three UPSC categories.
class PyqPaper {
  final int id;
  final int year;
  final String category; // prelims | mains | optional
  final String categoryLabel;
  final String paperType; // paper_1, paper_a, gs1, optional_1, …
  final String title; // e.g. "Optional Paper 1 — Geography"
  final String? subjectName; // Mains Paper-A language / Optional subject
  final List<String> available; // slot keys that have an uploaded PDF

  const PyqPaper({
    required this.id,
    required this.year,
    required this.category,
    required this.categoryLabel,
    required this.paperType,
    required this.title,
    required this.subjectName,
    required this.available,
  });

  factory PyqPaper.fromJson(Map<String, dynamic> j) => PyqPaper(
    id: j['id'] as int,
    year: j['year'] as int,
    category: j['category'] as String,
    categoryLabel: j['category_label'] as String? ?? '',
    paperType: j['paper_type'] as String? ?? '',
    title: j['title'] as String? ?? '',
    subjectName: j['subject_name'] as String?,
    available: ((j['available'] as List?) ?? const [])
        .map((e) => e as String)
        .toList(),
  );

  bool has(String slot) => available.contains(slot);

  bool get hasAnyQuestionPaper =>
      has('question_paper_en') || has('question_paper_hi');
  bool get hasAnySolution => has('solution_en') || has('solution_hi');
}

/// The four downloadable slots and their human labels (mirror of the backend).
class PyqSlot {
  static const questionPaperEn = 'question_paper_en';
  static const questionPaperHi = 'question_paper_hi';
  static const solutionEn = 'solution_en';
  static const solutionHi = 'solution_hi';

  static const labels = {
    questionPaperEn: 'Question Paper (English)',
    questionPaperHi: 'Question Paper (Hindi)',
    solutionEn: 'Solution (English)',
    solutionHi: 'Solution (Hindi)',
  };
}

/// The whole PYQ index response: available years + the papers for one year.
class PyqIndex {
  final List<int> years;
  final int year;
  final List<PyqPaper> papers;

  const PyqIndex({required this.years, required this.year, required this.papers});

  factory PyqIndex.fromJson(Map<String, dynamic> j) => PyqIndex(
    years: ((j['years'] as List?) ?? const []).map((e) => e as int).toList(),
    year: j['year'] as int? ?? 0,
    papers: ((j['papers'] as List?) ?? const [])
        .map((e) => PyqPaper.fromJson(e as Map<String, dynamic>))
        .toList(),
  );

  List<PyqPaper> get prelims =>
      papers.where((p) => p.category == 'prelims').toList();
  List<PyqPaper> get mains =>
      papers.where((p) => p.category == 'mains').toList();

  /// Optional papers grouped by subject → [{subject: [papers]}].
  Map<String, List<PyqPaper>> get optionalBySubject {
    final map = <String, List<PyqPaper>>{};
    for (final p in papers.where((p) => p.category == 'optional')) {
      map.putIfAbsent(p.subjectName ?? 'Optional Subject', () => []).add(p);
    }
    return map;
  }
}
