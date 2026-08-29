import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/providers/catalog_provider.dart';
import '../../../core/providers/exam_provider.dart';
import '../../../shared/widgets/app_widgets.dart';
import '../../../core/api/api_client.dart';

class ExamSetupScreen extends ConsumerStatefulWidget {
  const ExamSetupScreen({super.key});

  @override
  ConsumerState<ExamSetupScreen> createState() => _ExamSetupScreenState();
}

class _ExamSetupScreenState extends ConsumerState<ExamSetupScreen> {
  final Set<int> _selectedSubjects = {};
  final Set<int> _selectedChapters = {};
  int _count = 100;
  bool _loading = false;

  // Duration scales with the question count: 100 questions = 120 minutes.
  int get _durationMins => (_count * 1.2).round();

  String get _durationLabel {
    final h = _durationMins ~/ 60;
    final m = _durationMins % 60;
    if (h > 0) return m > 0 ? '${h}h ${m}m' : '${h}h';
    return '${m}m';
  }

  Future<void> _start() async {
    // Prefer chapter-level selection; else all chapters of the chosen subjects;
    // else every subject. (Backend needs at least one subject/chapter.)
    List<int>? subjectIds;
    List<int>? chapterIds;
    if (_selectedChapters.isNotEmpty) {
      chapterIds = _selectedChapters.toList();
    } else if (_selectedSubjects.isNotEmpty) {
      subjectIds = _selectedSubjects.toList();
    } else {
      subjectIds = ref
          .read(subjectsProvider)
          .valueOrNull
          ?.map((s) => s.id)
          .toList();
    }

    if ((subjectIds == null || subjectIds.isEmpty) &&
        (chapterIds == null || chapterIds.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No subjects available to generate a test.')),
      );
      return;
    }

    setState(() => _loading = true);
    await ref
        .read(examSessionProvider.notifier)
        .generateExam(
          subjectIds: subjectIds,
          chapterIds: chapterIds,
          count: _count,
        );
    if (mounted) {
      setState(() => _loading = false);
      final session = ref.read(examSessionProvider).valueOrNull;
      if (session != null) {
        context.pushReplacement('/exam/${session.sessionId}/take');
      } else {
        final err = ref.read(examSessionProvider).error;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(err?.toString() ?? 'Failed to generate exam'),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final subjects = ref.watch(subjectsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Generate Test')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionTitle('Number of Questions'),
            const SizedBox(height: 12),
            Row(
              children: [25, 50, 100, 150].map((n) {
                final selected = _count == n;
                return Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _count = n),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: selected
                            ? const Color(0xFF4F46E5)
                            : const Color(0xFFEEF2FF),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Text(
                          '$n',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontWeight: FontWeight.w700,
                            color: selected
                                ? Colors.white
                                : const Color(0xFF4F46E5),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 12),
            // Live duration so the user sees the time limit before starting.
            Row(
              children: [
                const Icon(Icons.timer_outlined, size: 18, color: Color(0xFF4F46E5)),
                const SizedBox(width: 6),
                Text(
                  'Duration: $_durationLabel  ($_count questions)',
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 13,
                    color: Colors.black54,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 28),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _sectionTitle('Subjects'),
                if (_selectedSubjects.isNotEmpty || _selectedChapters.isNotEmpty)
                  TextButton(
                    onPressed: () => setState(() {
                      _selectedSubjects.clear();
                      _selectedChapters.clear();
                    }),
                    child: const Text(
                      'Clear',
                      style: TextStyle(fontFamily: 'Poppins', color: Color(0xFF4F46E5)),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            subjects.when(
              data: (list) => Wrap(
                spacing: 8,
                runSpacing: 8,
                children: list.map((s) {
                  final sel = _selectedSubjects.contains(s.id);
                  return FilterChip(
                    label: Text(
                      s.name,
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 12,
                        color: sel ? Colors.white : const Color(0xFF4F46E5),
                      ),
                    ),
                    selected: sel,
                    onSelected: (_) => setState(() {
                      if (sel) {
                        _selectedSubjects.remove(s.id);
                        // Drop any chapters that belonged to this subject.
                        final chs = ref
                            .read(chaptersProvider(s.id))
                            .valueOrNull;
                        if (chs != null) {
                          _selectedChapters.removeAll(chs.map((c) => c.id));
                        }
                      } else {
                        _selectedSubjects.add(s.id);
                      }
                    }),
                    selectedColor: const Color(0xFF4F46E5),
                    backgroundColor: const Color(0xFFEEF2FF),
                    checkmarkColor: Colors.white,
                  );
                }).toList(),
              ),
              loading: () => const ShimmerCard(height: 60),
              error: (e, _) => ErrorRetryWidget(
                message: apiErrorMessage(e),
                onRetry: () => ref.invalidate(subjectsProvider),
              ),
            ),

            // Chapters for each selected subject (optional, narrows the test).
            if (_selectedSubjects.isNotEmpty) ...[
              const SizedBox(height: 28),
              _sectionTitle('Chapters (optional)'),
              const SizedBox(height: 4),
              const Text(
                'Leave empty to include all chapters of the selected subjects.',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 12,
                  color: Colors.black45,
                ),
              ),
              const SizedBox(height: 8),
              for (final sid in _selectedSubjects)
                _ChapterGroup(
                  subjectId: sid,
                  selected: _selectedChapters,
                  onToggle: (chapterId, isSel) => setState(() {
                    if (isSel) {
                      _selectedChapters.remove(chapterId);
                    } else {
                      _selectedChapters.add(chapterId);
                    }
                  }),
                ),
            ],
            const SizedBox(height: 40),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : FilledButton.icon(
                  onPressed: _start,
                  icon: const Icon(Icons.play_arrow),
                  label: Text('Start Test · $_durationLabel'),
                ),
        ),
      ),
    );
  }

  Widget _sectionTitle(String text) => Text(
    text,
    style: const TextStyle(
      fontFamily: 'Poppins',
      fontWeight: FontWeight.w600,
      fontSize: 16,
    ),
  );
}

/// Chapter multi-select for one selected subject.
class _ChapterGroup extends ConsumerWidget {
  final int subjectId;
  final Set<int> selected;
  final void Function(int chapterId, bool isCurrentlySelected) onToggle;
  const _ChapterGroup({
    required this.subjectId,
    required this.selected,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final chapters = ref.watch(chaptersProvider(subjectId));
    return chapters.when(
      data: (list) {
        if (list.isEmpty) return const SizedBox.shrink();
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: list.map((c) {
              final sel = selected.contains(c.id);
              return FilterChip(
                label: Text(
                  c.name,
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 11,
                    color: sel ? Colors.white : const Color(0xFF7C3AED),
                  ),
                ),
                selected: sel,
                onSelected: (_) => onToggle(c.id, sel),
                selectedColor: const Color(0xFF7C3AED),
                backgroundColor: const Color(0xFFF3E8FF),
                checkmarkColor: Colors.white,
                visualDensity: VisualDensity.compact,
              );
            }).toList(),
          ),
        );
      },
      loading: () => const Padding(
        padding: EdgeInsets.only(bottom: 12),
        child: ShimmerCard(height: 40),
      ),
      error: (_, _) => const SizedBox.shrink(),
    );
  }
}
