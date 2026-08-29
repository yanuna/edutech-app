import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/models/exam.dart';
import '../../../core/providers/exam_provider.dart';
import '../../../core/services/exam_state_store.dart';
import '../../../shared/widgets/app_widgets.dart';
import '../../../shared/widgets/rich_content_view.dart';

class ExamScreen extends ConsumerStatefulWidget {
  final int sessionId;
  const ExamScreen({super.key, required this.sessionId});

  @override
  ConsumerState<ExamScreen> createState() => _ExamScreenState();
}

class _ExamScreenState extends ConsumerState<ExamScreen>
    with WidgetsBindingObserver {
  int _currentIndex = 0;
  Timer? _timer;
  Duration _remaining = Duration.zero;
  bool _submitting = false;

  final PageController _pageCtrl = PageController();

  @override
  void initState() {
    super.initState();
    // The server auto-submits an attempt after 3 background switches, but the
    // app always sent 0 — nothing ever counted them, so the rule never fired.
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _bootstrap());
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      final notifier = ref.read(examSessionProvider.notifier);
      notifier.appBackgroundCount++;
      // Leaving the app is exactly when unsent answers are most at risk.
      notifier.scheduleSync(widget.sessionId, delay: Duration.zero);
    }
  }

  /// Loads the attempt (restoring after a crash/restart when there's no
  /// in-memory session), then starts the countdown and saves a checkpoint.
  Future<void> _bootstrap() async {
    final notifier = ref.read(examSessionProvider.notifier);
    final current = ref.read(examSessionProvider).valueOrNull;

    if (current == null || current.sessionId != widget.sessionId) {
      // Resuming with no in-memory state. Prefer the local copy (instant and
      // works offline); fall back to the server when there's no local copy.
      final saved = await ExamStateStore.instance.load();
      if (saved != null && saved.session.sessionId == widget.sessionId) {
        notifier.setSession(saved.session);
        if (mounted) setState(() => _currentIndex = saved.currentIndex);
      } else {
        await notifier.loadResume(widget.sessionId);
      }
    }
    if (!mounted) return;
    _startTimer();
    _persist();
  }

  /// Persists the full attempt (answers, statuses, current question, deadline)
  /// after every change so a crash/kill never loses progress.
  void _persist() {
    final s = ref.read(examSessionProvider).valueOrNull;
    if (s != null) ExamStateStore.instance.save(s, _currentIndex);
  }

  /// Jumps to a question and checkpoints — used by prev/next and the palette.
  void _goToQuestion(int index) {
    if (index < 0) return;
    setState(() => _currentIndex = index);
    _persist();
  }

  /// Opens the question palette (grid of all questions with their status) so
  /// the user can jump directly to any question.
  void _openPalette() {
    final session = ref.read(examSessionProvider).valueOrNull;
    if (session == null) return;
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (sheetCtx) => _QuestionPalette(
        questions: session.questions,
        currentIndex: _currentIndex,
        onSelect: (i) {
          Navigator.pop(sheetCtx);
          _goToQuestion(i);
        },
        onSubmit: () {
          Navigator.pop(sheetCtx);
          _confirmSubmit();
        },
      ),
    );
  }

  void _startTimer() {
    final session = ref.read(examSessionProvider).valueOrNull;
    if (session == null) return;
    final deadline = DateTime.parse(session.endTimeDeadline).toLocal();
    _remaining = deadline.difference(DateTime.now());
    if (_remaining.isNegative) {
      _autoSubmit();
      return;
    }

    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      final now = deadline.difference(DateTime.now());
      if (now.isNegative) {
        _timer?.cancel();
        _autoSubmit();
        return;
      }
      setState(() => _remaining = now);
    });
  }

  String get _timerText {
    final h = _remaining.inHours;
    final m = _remaining.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = _remaining.inSeconds.remainder(60).toString().padLeft(2, '0');
    return h > 0 ? '$h:$m:$s' : '$m:$s';
  }

  Color get _timerColor {
    if (_remaining.inMinutes < 5) return Colors.red;
    if (_remaining.inMinutes < 15) return Colors.orange;
    return const Color(0xFF4F46E5);
  }

  Future<void> _autoSubmit() => _submit(auto: true);

  Future<void> _submit({bool auto = false}) async {
    if (_submitting) return;
    _timer?.cancel();
    setState(() => _submitting = true);

    final notifier = ref.read(examSessionProvider.notifier);

    // Block on the final flush. Scoring reads what the SERVER holds, so
    // submitting with answers still unsent silently grades them as zero.
    final synced = await notifier.flushAnswers(widget.sessionId);

    if (!synced && !auto) {
      // A manual submit stops here so the student can retry rather than
      // unknowingly submitting an incomplete paper.
      if (mounted) {
        setState(() => _submitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Some answers have not reached the server yet. '
              'Check your connection and tap Submit again.',
            ),
            duration: Duration(seconds: 5),
          ),
        );
      }
      return;
    }

    final result = await notifier.submitExam(widget.sessionId);
    if (mounted) {
      if (result != null) {
        ExamStateStore.instance.clear(); // attempt finished — drop local state
        ref.invalidate(activeExamProvider); // hide the Home "resume" banner
        context.pushReplacement('/exam/${widget.sessionId}/result');
      } else {
        setState(() => _submitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Submission failed. Try again.')),
        );
      }
    }
  }

  void _confirmSubmit() {
    showDialog(
      context: context,
      builder: (dialogContext) {
        final session = ref.read(examSessionProvider).valueOrNull;
        final answered =
            session?.questions.where((q) => q.status == 'answered').length ?? 0;
        final total = session?.questions.length ?? 0;

        return AlertDialog(
          title: const Text(
            'Submit Exam?',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w700,
            ),
          ),
          content: Text(
            '$answered of $total questions answered.\nUnattempted questions will be scored 0.',
            style: const TextStyle(fontFamily: 'Poppins'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(dialogContext);
                _submit();
              },
              child: const Text('Submit'),
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    _pageCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sessionAsync = ref.watch(examSessionProvider);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _confirmSubmit();
      },
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.close),
            onPressed: _confirmSubmit,
          ),
          title: sessionAsync.when(
            data: (s) => Text(
              'Q ${_currentIndex + 1} / ${s?.questions.length ?? 0}',
              style: const TextStyle(fontFamily: 'Poppins', fontSize: 16),
            ),
            loading: () => const SizedBox.shrink(),
            error: (_, _) => const SizedBox.shrink(),
          ),
          actions: [
            IconButton(
              tooltip: 'All questions',
              icon: const Icon(Icons.grid_view_rounded),
              onPressed: _openPalette,
            ),
            Container(
              margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: _timerColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: _timerColor.withValues(alpha: 0.3)),
              ),
              child: Text(
                _timerText,
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w700,
                  color: _timerColor,
                ),
              ),
            ),
          ],
        ),
        body: sessionAsync.when(
          data: (session) {
            if (session == null) return const LoadingWidget();
            final q = session.questions[_currentIndex];

            return Column(
              children: [
                // Progress bar
                LinearProgressIndicator(
                  value: (_currentIndex + 1) / session.questions.length,
                  backgroundColor: Colors.grey.shade200,
                  valueColor: const AlwaysStoppedAnimation(Color(0xFF4F46E5)),
                  minHeight: 4,
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Question text
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.05),
                                blurRadius: 8,
                              ),
                            ],
                          ),
                          child: RichContentView(
                            html: q.questionText,
                            fontSize: 15,
                          ),
                        ),
                        if (q.hasHint) ...[
                          const SizedBox(height: 10),
                          _HintTile(hint: q.hint!),
                        ],
                        const SizedBox(height: 20),

                        // Options
                        ...List.generate(4, (i) {
                          final pos = i + 1;
                          final selected = q.selectedOption == pos;
                          return _OptionTile(
                            index: pos,
                            text: q.optionText(pos),
                            selected: selected,
                            onTap: () {
                              final notifier =
                                  ref.read(examSessionProvider.notifier);
                              notifier.answerQuestion(_currentIndex, pos);
                              _persist(); // local crash-recovery checkpoint
                              // Only the changed answer is queued, and taps are
                              // coalesced. The old code rebuilt and resent the
                              // ENTIRE answered set on every tap — 5 POSTs per tap
                              // late in a 100-question paper — which tripped the
                              // 30/min throttle and silently lost answers.
                              notifier.scheduleSync(widget.sessionId);
                            },
                          );
                        }),

                        const SizedBox(height: 16),
                        // Mark for review
                        OutlinedButton.icon(
                          onPressed: () {
                            final notifier =
                                ref.read(examSessionProvider.notifier);
                            notifier.markForReview(_currentIndex);
                            _persist();
                            // Review marks were never synced, so resuming after a
                            // crash lost every one of them.
                            notifier.scheduleSync(widget.sessionId);
                          },
                          icon: Icon(
                            q.status == 'marked_for_review'
                                ? Icons.bookmark
                                : Icons.bookmark_border,
                            size: 18,
                          ),
                          label: Text(
                            q.status == 'marked_for_review'
                                ? 'Marked for Review'
                                : 'Mark for Review',
                            style: const TextStyle(fontFamily: 'Poppins'),
                          ),
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size(double.infinity, 44),
                          ),
                        ),
                        const SizedBox(height: 80),
                      ],
                    ),
                  ),
                ),

                // Bottom nav
                Container(
                  padding: const EdgeInsets.all(16),
                  color: Colors.white,
                  child: Row(
                    children: [
                      if (_currentIndex > 0)
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => _goToQuestion(_currentIndex - 1),
                            child: const Text(
                              'Previous',
                              style: TextStyle(fontFamily: 'Poppins'),
                            ),
                          ),
                        ),
                      if (_currentIndex > 0) const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: _currentIndex < session.questions.length - 1
                            ? FilledButton(
                                onPressed: () => _goToQuestion(_currentIndex + 1),
                                child: const Text(
                                  'Next',
                                  style: TextStyle(fontFamily: 'Poppins'),
                                ),
                              )
                            : FilledButton(
                                onPressed: _submitting ? null : _confirmSubmit,
                                style: FilledButton.styleFrom(
                                  backgroundColor: const Color(0xFF10B981),
                                ),
                                child: _submitting
                                    ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      )
                                    : const Text(
                                        'Submit',
                                        style: TextStyle(fontFamily: 'Poppins'),
                                      ),
                              ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
          loading: () => const LoadingWidget(message: 'Loading exam...'),
          error: (e, _) => Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.error_outline,
                    size: 48,
                    color: Color(0xFFEF4444),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    "This exam can't be opened.",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'It may already be submitted or no longer available.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      color: Colors.black54,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 18),
                  FilledButton.icon(
                    onPressed: () => context.go('/exam'),
                    icon: const Icon(Icons.arrow_back),
                    label: const Text('Back to Exams'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Question palette ───────────────────────────────────────────────────────

class _QuestionPalette extends StatelessWidget {
  final List<ExamQuestion> questions;
  final int currentIndex;
  final void Function(int) onSelect;
  final VoidCallback onSubmit;
  const _QuestionPalette({
    required this.questions,
    required this.currentIndex,
    required this.onSelect,
    required this.onSubmit,
  });

  static const _answered = Color(0xFF10B981);
  static const _marked = Color(0xFFF59E0B);
  static final _unattempted = Colors.grey.shade300;

  @override
  Widget build(BuildContext context) {
    final answered = questions.where((q) => q.status == 'answered').length;
    final marked = questions
        .where((q) => q.status == 'marked_for_review')
        .length;
    final unattempted = questions.length - answered - marked;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Questions',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w700,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 16,
              runSpacing: 6,
              children: [
                _Legend(color: _answered, label: 'Answered ($answered)'),
                _Legend(color: _marked, label: 'Marked ($marked)'),
                _Legend(color: _unattempted, label: 'Unattempted ($unattempted)'),
              ],
            ),
            const SizedBox(height: 14),
            Flexible(
              child: GridView.builder(
                shrinkWrap: true,
                itemCount: questions.length,
                gridDelegate:
                    const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 6,
                      mainAxisSpacing: 10,
                      crossAxisSpacing: 10,
                      childAspectRatio: 1,
                    ),
                itemBuilder: (_, i) {
                  final q = questions[i];
                  final isCurrent = i == currentIndex;
                  final filled =
                      q.status == 'answered' || q.status == 'marked_for_review';
                  final bg = switch (q.status) {
                    'answered' => _answered,
                    'marked_for_review' => _marked,
                    _ => _unattempted,
                  };
                  return InkWell(
                    onTap: () => onSelect(i),
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      decoration: BoxDecoration(
                        color: bg,
                        borderRadius: BorderRadius.circular(8),
                        border: isCurrent
                            ? Border.all(
                                color: const Color(0xFF4F46E5),
                                width: 2.5,
                              )
                            : null,
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        '${i + 1}',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.w600,
                          color: filled ? Colors.white : Colors.black87,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: onSubmit,
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF10B981),
                ),
                icon: const Icon(Icons.check_circle_outline),
                label: const Text(
                  'Submit Test',
                  style: TextStyle(fontFamily: 'Poppins'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  final Color color;
  final String label;
  const _Legend({required this.color, required this.label});

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        width: 12,
        height: 12,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(3),
        ),
      ),
      const SizedBox(width: 6),
      Text(
        label,
        style: const TextStyle(fontFamily: 'Poppins', fontSize: 12),
      ),
    ],
  );
}

class _OptionTile extends StatelessWidget {
  final int index;
  final String text;
  final bool selected;
  final VoidCallback onTap;
  const _OptionTile({
    required this.index,
    required this.text,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final labels = ['A', 'B', 'C', 'D'];
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFEEF2FF) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? const Color(0xFF4F46E5) : Colors.grey.shade200,
            width: selected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: selected
                  ? const Color(0xFF4F46E5)
                  : const Color(0xFFEEF2FF),
              child: Text(
                labels[index - 1],
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                  color: selected ? Colors.white : const Color(0xFF4F46E5),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Stack(
                children: [
                  RichContentView(
                    html: text,
                    fontSize: 14,
                    color: selected
                        ? const Color(0xFF1E1B4B)
                        : Colors.black87,
                  ),
                  // Math/HTML options render in a WebView that swallows taps in
                  // its centre, so only the edges reached the tile's handler.
                  // This transparent layer makes the whole option selectable.
                  Positioned.fill(
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: onTap,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Collapsible hint shown under a question when the author provided one.
class _HintTile extends StatefulWidget {
  final String hint;
  const _HintTile({required this.hint});

  @override
  State<_HintTile> createState() => _HintTileState();
}

class _HintTileState extends State<_HintTile> {
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFDE68A)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: () => setState(() => _open = !_open),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(
                children: [
                  const Icon(
                    Icons.lightbulb_outline,
                    size: 18,
                    color: Color(0xFFD97706),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Hint',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w600,
                      color: Color(0xFFD97706),
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    _open ? Icons.expand_less : Icons.expand_more,
                    color: const Color(0xFFD97706),
                  ),
                ],
              ),
            ),
          ),
          if (_open)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
              child: RichContentView(
                html: widget.hint,
                fontSize: 13,
                color: const Color(0xFF92400E),
              ),
            ),
        ],
      ),
    );
  }
}
