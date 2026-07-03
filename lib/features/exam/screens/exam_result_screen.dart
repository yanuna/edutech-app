import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import '../../../core/providers/exam_provider.dart';
import '../../../core/models/exam.dart';
import '../../../shared/widgets/app_widgets.dart';
import '../../../shared/widgets/ad_banner_widget.dart';
import '../../../shared/widgets/rich_content_view.dart';

class ExamResultScreen extends ConsumerWidget {
  final int sessionId;
  const ExamResultScreen({super.key, required this.sessionId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final result = ref.watch(examResultProvider(sessionId));

    return Scaffold(
      body: result.when(
        data: (r) => _ResultBody(result: r),
        loading: () => const LoadingWidget(message: 'Loading results...'),
        error: (e, _) => ErrorRetryWidget(
          message: e.toString(),
          onRetry: () => ref.invalidate(examResultProvider(sessionId)),
        ),
      ),
    );
  }
}

class _ResultBody extends StatelessWidget {
  final ExamResultSummary result;
  const _ResultBody({required this.result});

  Color get _scoreColor {
    if (result.accuracyPercentage >= 80) return const Color(0xFF10B981);
    if (result.accuracyPercentage >= 60) return const Color(0xFFF59E0B);
    return const Color(0xFFEF4444);
  }

  void _shareResult(ExamResultSummary r) {
    final emoji = r.accuracyPercentage >= 80
        ? '🏆'
        : r.accuracyPercentage >= 60
        ? '👍'
        : '💪';
    SharePlus.instance.share(
      ShareParams(
        text:
            '$emoji I just scored ${r.totalScore.toStringAsFixed(0)} points '
            'with ${r.accuracyPercentage.toStringAsFixed(1)}% accuracy on EduTech!\n\n'
            '✅ Correct: ${r.totalCorrect}  ❌ Wrong: ${r.totalIncorrect}  ⏭ Skipped: ${r.totalUnattempted}\n\n'
            'Challenge yourself on EduTech — Learn · Practice · Excel',
        subject: 'My EduTech Exam Result',
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverAppBar(
          expandedHeight: 280,
          pinned: true,
          leading: IconButton(
            icon: const Icon(Icons.home, color: Colors.white),
            onPressed: () => context.go('/exam'),
          ),
          title: const Text('Result', style: TextStyle(color: Colors.white)),
          flexibleSpace: FlexibleSpaceBar(
            background: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [_scoreColor, _scoreColor.withValues(alpha: 0.7)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: SafeArea(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 40),
                    Text(
                      result.totalScore.toStringAsFixed(2),
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        color: Colors.white,
                        fontSize: 56,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const Text(
                      'Total Score',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${result.accuracyPercentage.toStringAsFixed(1)}% Accuracy',
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),

        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Summary row
                Row(
                  children: [
                    _StatBox(
                      label: 'Correct',
                      value: '${result.totalCorrect}',
                      color: const Color(0xFF10B981),
                    ),
                    const SizedBox(width: 12),
                    _StatBox(
                      label: 'Wrong',
                      value: '${result.totalIncorrect}',
                      color: const Color(0xFFEF4444),
                    ),
                    const SizedBox(width: 12),
                    _StatBox(
                      label: 'Skipped',
                      value: '${result.totalUnattempted}',
                      color: Colors.grey,
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Test Series ranking banner (only for Test Series attempts)
                if (result.isTestSeries) ...[
                  _RankBanner(result: result),
                  const SizedBox(height: 16),
                ],

                const AdBannerWidget(),
                const SizedBox(height: 16),

                // Subject breakdown
                if (result.subjectBreakdown.isNotEmpty) ...[
                  const Text(
                    'Subject-wise Breakdown',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...result.subjectBreakdown.map(
                    (s) => _SubjectRow(breakdown: s),
                  ),
                  const SizedBox(height: 24),
                ],

                // Question review
                const Text(
                  'Question Review',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        ),

        // Question review — built lazily so each question's WebView
        // (RichContentView) is created only as it scrolls into view. Building
        // them all at once spawned one native WebView per question and hung the
        // screen on exams with many questions.
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          sliver: SliverList.builder(
            itemCount: result.questions.length,
            itemBuilder: (_, i) => _QuestionReview(q: result.questions[i]),
          ),
        ),

        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
            child: Column(
              children: [
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () => context.go('/exam/setup'),
                    icon: const Icon(Icons.refresh),
                    label: const Text('Take Another Exam'),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => _shareResult(result),
                    icon: const Icon(Icons.share_outlined),
                    label: const Text('Share Results'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _StatBox extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _StatBox({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) => Expanded(
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w800,
              fontSize: 24,
              color: color,
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 12,
              color: Colors.black54,
            ),
          ),
        ],
      ),
    ),
  );
}

class _SubjectRow extends StatelessWidget {
  final SubjectBreakdown breakdown;
  const _SubjectRow({required this.breakdown});

  @override
  Widget build(BuildContext context) {
    final pct = breakdown.accuracyPct / 100;
    Color color;
    if (breakdown.accuracyPct >= 80) {
      color = const Color(0xFF10B981);
    } else if (breakdown.accuracyPct >= 60) {
      color = const Color(0xFFF59E0B);
    } else {
      color = const Color(0xFFEF4444);
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  breakdown.subjectName,
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  '${breakdown.accuracyPct.toStringAsFixed(0)}%',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: pct,
                backgroundColor: color.withValues(alpha: 0.15),
                valueColor: AlwaysStoppedAnimation(color),
                minHeight: 8,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '${breakdown.correct} correct · ${breakdown.incorrect} wrong · ${breakdown.unattempted} skipped',
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 11,
                color: Colors.black45,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuestionReview extends StatelessWidget {
  final QuestionDetail q;
  const _QuestionReview({required this.q});

  static const _green = Color(0xFF10B981);
  static const _red = Color(0xFFEF4444);

  Widget _tag(String label, Color color) => Container(
    margin: const EdgeInsets.only(left: 6),
    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.15),
      borderRadius: BorderRadius.circular(6),
    ),
    child: Text(
      label,
      style: TextStyle(
        fontFamily: 'Poppins',
        fontSize: 10,
        fontWeight: FontWeight.w700,
        color: color,
      ),
    ),
  );

  // Each option, with the correct answer (green) and the user's pick (red if
  // wrong) clearly marked — matches the web review.
  List<Widget> _optionTiles() {
    const letters = ['A', 'B', 'C', 'D'];
    return [1, 2, 3, 4]
        .where((p) => q.shuffledOptions['$p'] != null)
        .map((pos) {
          final text = q.shuffledOptions['$pos']!;
          final isUser = q.userSelectedShuffled == pos;
          final isCorrect = q.correctShuffledOption == pos;
          Color border = Colors.grey.shade300;
          Color? bg;
          if (isCorrect) {
            border = _green;
            bg = _green.withValues(alpha: 0.08);
          } else if (isUser) {
            border = _red;
            bg = _red.withValues(alpha: 0.08);
          }
          return Container(
            margin: const EdgeInsets.only(bottom: 6),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: border),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${letters[pos - 1]}. ',
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
                Expanded(child: RichContentView(html: text, fontSize: 12)),
                if (isCorrect) _tag('Correct', _green),
                if (isUser && !isCorrect) _tag('Your answer', _red),
                if (isUser && isCorrect) _tag('You', _green),
              ],
            ),
          );
        })
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    Color borderColor;
    IconData icon;
    if (q.isCorrect == true) {
      borderColor = const Color(0xFF10B981);
      icon = Icons.check_circle;
    } else if (q.isCorrect == false) {
      borderColor = const Color(0xFFEF4444);
      icon = Icons.cancel;
    } else {
      borderColor = Colors.grey;
      icon = Icons.remove_circle_outline;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: borderColor.withValues(alpha: 0.5)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: borderColor, size: 20),
                const SizedBox(width: 8),
                Text(
                  q.isCorrect == true
                      ? 'Correct +${q.marksAwarded}'
                      : q.isCorrect == false
                      ? 'Wrong ${q.marksAwarded}'
                      : 'Skipped',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    color: borderColor,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            RichContentView(html: q.questionText, fontSize: 13),
            const SizedBox(height: 10),
            ..._optionTiles(),
            if (q.explanation != null && q.explanation!.trim().isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0FDF4),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.lightbulb_outline,
                      size: 16,
                      color: Color(0xFF10B981),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: RichContentView(
                        html: q.explanation!,
                        fontSize: 12,
                        color: const Color(0xFF065F46),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Shows rank/percentile for a Test Series attempt — or why there's no rank
/// (late attempt) or that ranking is still pending (exam not ended yet).
class _RankBanner extends StatelessWidget {
  final ExamResultSummary result;
  const _RankBanner({required this.result});

  @override
  Widget build(BuildContext context) {
    final String title;
    final String subtitle;
    final IconData icon;
    final Color color;

    if (!result.examIsRanked) {
      title = 'Not Ranked';
      subtitle =
          'You attempted this after the exam ended, so it isn\'t ranked.';
      icon = Icons.timer_off_outlined;
      color = Colors.grey;
    } else if (result.examRank != null) {
      title = 'Rank #${result.examRank}';
      subtitle = result.examPercentile != null
          ? '${result.examPercentile!.toStringAsFixed(1)} percentile'
          : 'Great work!';
      icon = Icons.emoji_events;
      color = const Color(0xFF4F46E5);
    } else {
      title = 'Rank Pending';
      subtitle = 'Rankings are generated after the exam ends. Check back soon.';
      icon = Icons.hourglass_top;
      color = const Color(0xFFF59E0B);
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 30),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                    color: color,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 12,
                    color: Colors.black54,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
