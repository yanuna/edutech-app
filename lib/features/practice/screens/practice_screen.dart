import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/services/startup_service.dart' show enabledModulesProvider;

/// Practice hub (bottom-nav "Practice"). Surfaces the existing exam engine and
/// test series today; the daily/weekly quizzes, wrong-questions bank and
/// bookmarks are wired in by Module 6.
class PracticeScreen extends ConsumerWidget {
  const PracticeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mods = ref.watch(enabledModulesProvider);
    final actions = <_PracticeAction>[
      _PracticeAction('Start Practice', 'Custom MCQ test by subject & topic', Icons.play_circle_outline, const Color(0xFF6366F1), () => context.push('/exam/setup')),
      if (mods.contains('test_series'))
        _PracticeAction('Test Series', 'Full & sectional mock exams with ranking', Icons.emoji_events_outlined, const Color(0xFFF59E0B), () => context.push('/exam/test-series')),
      _PracticeAction('Wrong Questions', 'Revise every question you got wrong', Icons.rule_rounded, const Color(0xFFEF4444), () => context.push('/practice/review/wrong')),
      _PracticeAction('Bookmarked MCQs', 'Questions you saved for later', Icons.bookmark_added_outlined, const Color(0xFF0EA5E9), () => context.push('/practice/review/bookmarked')),
      _PracticeAction('My Attempts', 'Review your past tests & scores', Icons.history_rounded, const Color(0xFF10B981), () => context.push('/exam')),
      _PracticeAction('My Progress', 'Accuracy, reading time & weak areas', Icons.insights_rounded, const Color(0xFF0F766E), () => context.push('/progress')),
      _PracticeAction('Leaderboard', 'See where you rank', Icons.leaderboard_outlined, const Color(0xFF7C3AED), () => context.push('/profile/leaderboard')),
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Practice')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          for (final a in actions)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _ActionCard(action: a),
            ),
        ],
      ),
    );
  }
}

class _PracticeAction {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _PracticeAction(this.title, this.subtitle, this.icon, this.color, this.onTap);
}

class _ActionCard extends StatelessWidget {
  final _PracticeAction action;
  const _ActionCard({required this.action});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: action.onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Theme.of(context).dividerColor.withValues(alpha: .5)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: action.color.withValues(alpha: .12), borderRadius: BorderRadius.circular(12)),
              child: Icon(action.icon, color: action.color, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(action.title, style: const TextStyle(fontSize: 15.5, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 2),
                  Text(action.subtitle, style: TextStyle(fontSize: 12.5, color: Colors.grey.shade600)),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: Colors.grey.shade400),
          ],
        ),
      ),
    );
  }
}
