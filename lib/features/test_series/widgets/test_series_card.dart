import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/models/test_series.dart';
import '../../../core/providers/test_series_provider.dart';

class TestSeriesCard extends ConsumerStatefulWidget {
  final TestSeriesExam exam;
  const TestSeriesCard({super.key, required this.exam});

  @override
  ConsumerState<TestSeriesCard> createState() => _TestSeriesCardState();
}

class _TestSeriesCardState extends ConsumerState<TestSeriesCard> {
  bool _busy = false;

  TestSeriesExam get exam => widget.exam;

  ({String label, Color color}) get _badge {
    if (exam.isLive) return (label: 'Live', color: const Color(0xFF10B981));
    if (exam.isUpcoming) {
      return (label: 'Upcoming', color: const Color(0xFFF59E0B));
    }
    return (label: 'Expired', color: Colors.grey);
  }

  Future<void> _onAction() async {
    final attempt = exam.attempt;

    // Already completed → straight to the result screen.
    if (attempt.isCompleted && attempt.sessionId != null) {
      context.push('/exam/${attempt.sessionId}/result');
      return;
    }

    setState(() => _busy = true);
    final ctrl = ref.read(testSeriesControllerProvider);
    final res = await ctrl.start(exam.id);
    if (!mounted) return;
    setState(() => _busy = false);

    switch (res.kind) {
      case StartKind.started:
        context.push('/exam/${res.sessionId}/take');
      case StartKind.resume:
        if (res.sessionId != null && await ctrl.loadForResume(res.sessionId!)) {
          if (mounted) context.push('/exam/${res.sessionId}/take');
        }
      case StartKind.attempted:
        if (res.sessionId != null) {
          context.push('/exam/${res.sessionId}/result');
        }
      case StartKind.error:
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(res.message ?? 'Could not start the test.')),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final badge = _badge;
    final attempt = exam.attempt;
    final df = DateFormat('dd MMM, hh:mm a');

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Status badge + rank chip (if completed & ranked)
          Row(
            children: [
              _Pill(text: badge.label, color: badge.color),
              const Spacer(),
              if (attempt.isCompleted && attempt.rank != null)
                _Pill(text: '#${attempt.rank}', color: const Color(0xFF4F46E5)),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            exam.name,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w700,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 8),
          _MetaRow(
            icon: Icons.help_outline,
            text: '${exam.totalQuestions} questions',
          ),
          _MetaRow(
            icon: Icons.timer_outlined,
            text: '${exam.durationMinutes} min',
          ),
          _MetaRow(
            icon: Icons.event_outlined,
            text: df.format(exam.startAt.toLocal()),
          ),
          _MetaRow(
            icon: Icons.event_busy_outlined,
            text: df.format(exam.endAt.toLocal()),
          ),
          const Spacer(),
          if (attempt.isCompleted && attempt.marks != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Text(
                'Your marks: ${attempt.marks!.toStringAsFixed(1)}',
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF10B981),
                ),
              ),
            ),
          _ActionButton(
            busy: _busy,
            exam: exam,
            onPressed: exam.isUpcoming ? null : _onAction,
          ),
          Center(
            child: TextButton(
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 2),
                minimumSize: const Size(0, 28),
              ),
              onPressed: () =>
                  context.push('/exam/test-series/${exam.id}/leaderboard'),
              child: const Text(
                'Leaderboard',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 12,
                  color: Color(0xFF4F46E5),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final bool busy;
  final TestSeriesExam exam;
  final VoidCallback? onPressed;
  const _ActionButton({required this.busy, required this.exam, this.onPressed});

  @override
  Widget build(BuildContext context) {
    final attempt = exam.attempt;

    String label;
    if (exam.isUpcoming) {
      label = 'Not Started Yet';
    } else if (attempt.isCompleted) {
      label = 'View Result';
    } else if (attempt.isInProgress) {
      label = 'Resume';
    } else if (exam.isExpired) {
      label = 'Attempt (Expired)';
    } else {
      label = 'Start Test';
    }

    return SizedBox(
      width: double.infinity,
      height: 36,
      child: FilledButton(
        onPressed: busy ? null : onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: exam.isUpcoming ? Colors.grey.shade300 : null,
          padding: EdgeInsets.zero,
        ),
        child: busy
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Text(
                label,
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  final String text;
  final Color color;
  const _Pill({required this.text, required this.color});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Text(
      text,
      style: TextStyle(
        fontFamily: 'Poppins',
        fontSize: 11,
        fontWeight: FontWeight.w700,
        color: color,
      ),
    ),
  );
}

class _MetaRow extends StatelessWidget {
  final IconData icon;
  final String text;
  const _MetaRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 3),
    child: Row(
      children: [
        Icon(icon, size: 13, color: Colors.black45),
        const SizedBox(width: 5),
        Expanded(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 11,
              color: Colors.black54,
            ),
          ),
        ),
      ],
    ),
  );
}
