import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/dashboard_provider.dart';

/// Progress Dashboard — reading time, practice accuracy, streak, per-subject
/// performance and weak areas, aggregated from the user's activity.
class ProgressDashboardScreen extends ConsumerWidget {
  const ProgressDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(dashboardProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('My Progress')),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => _Retry(onRetry: () => ref.invalidate(dashboardProvider)),
        data: (d) => !d.hasActivity
            ? const _EmptyState()
            : RefreshIndicator(
                onRefresh: () async => ref.invalidate(dashboardProvider),
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    GridView.count(
                      crossAxisCount: 2,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: 2.1,
                      children: [
                        _StatTile(icon: Icons.local_fire_department_rounded, color: const Color(0xFFF97316), value: '${d.streakCurrent}', label: 'Day streak'),
                        _StatTile(icon: Icons.bolt_rounded, color: const Color(0xFF6366F1), value: '${d.xp}', label: 'XP earned'),
                        _StatTile(icon: Icons.track_changes_rounded, color: _accuracyColor(d.accuracy), value: '${d.accuracy.toStringAsFixed(0)}%', label: 'Accuracy'),
                        _StatTile(icon: Icons.schedule_rounded, color: const Color(0xFF10B981), value: _time(d.readingMinutes), label: 'Read time'),
                      ],
                    ),
                    const SizedBox(height: 20),

                    _PracticeSummary(d: d),
                    const SizedBox(height: 20),

                    if (d.weakAreas.isNotEmpty) ...[
                      const _SectionTitle('Focus Areas'),
                      const SizedBox(height: 4),
                      Text('Lowest accuracy — worth revising.', style: TextStyle(fontSize: 12.5, color: Colors.grey.shade600)),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8, runSpacing: 8,
                        children: [for (final w in d.weakAreas) _WeakChip(perf: w)],
                      ),
                      const SizedBox(height: 20),
                    ],

                    if (d.subjects.isNotEmpty) ...[
                      const _SectionTitle('Subject Performance'),
                      const SizedBox(height: 12),
                      for (final s in d.subjects) _SubjectBar(perf: s),
                    ],
                    const SizedBox(height: 24),
                  ],
                ),
              ),
      ),
    );
  }

  static Color _accuracyColor(double acc) =>
      acc >= 75 ? const Color(0xFF10B981) : (acc >= 50 ? const Color(0xFFF59E0B) : const Color(0xFFEF4444));

  static String _time(int minutes) {
    if (minutes < 60) return '${minutes}m';
    final h = minutes ~/ 60;
    final m = minutes % 60;
    return m == 0 ? '${h}h' : '${h}h ${m}m';
  }
}

class _StatTile extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String value;
  final String label;
  const _StatTile({required this.icon, required this.color, required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(color: color.withValues(alpha: .10), borderRadius: BorderRadius.circular(14)),
      child: Row(children: [
        Icon(icon, color: color, size: 26),
        const SizedBox(width: 10),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
            Text(value, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontFamily: 'Poppins', fontSize: 18, fontWeight: FontWeight.w800, color: color)),
            Text(label, style: TextStyle(fontSize: 11.5, color: Colors.grey.shade600)),
          ]),
        ),
      ]),
    );
  }
}

class _PracticeSummary extends StatelessWidget {
  final DashboardData d;
  const _PracticeSummary({required this.d});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(14), border: Border.all(color: Theme.of(context).dividerColor.withValues(alpha: .5))),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _metric('${d.testsTaken}', 'Tests'),
          _divider(),
          _metric('${d.questionsAttempted}', 'Questions'),
          _divider(),
          _metric('${d.correct}', 'Correct'),
          _divider(),
          _metric('${d.articlesCompleted}', 'Articles'),
        ],
      ),
    );
  }

  Widget _metric(String v, String l) => Column(children: [
    Text(v, style: const TextStyle(fontFamily: 'Poppins', fontSize: 18, fontWeight: FontWeight.w800)),
    Text(l, style: TextStyle(fontSize: 11.5, color: Colors.grey.shade600)),
  ]);

  Widget _divider() => Container(width: 1, height: 32, color: Colors.grey.withValues(alpha: .2));
}

class _SubjectBar extends StatelessWidget {
  final SubjectPerf perf;
  const _SubjectBar({required this.perf});

  Color get _color => perf.accuracy >= 75 ? const Color(0xFF10B981) : (perf.accuracy >= 50 ? const Color(0xFFF59E0B) : const Color(0xFFEF4444));

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Expanded(child: Text(perf.subject, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14))),
            Text('${perf.correct}/${perf.attempted} · ${perf.accuracy.toStringAsFixed(0)}%', style: TextStyle(fontSize: 12, color: Colors.grey.shade700, fontWeight: FontWeight.w600)),
          ]),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: (perf.accuracy / 100).clamp(0, 1),
              minHeight: 8,
              backgroundColor: Colors.grey.withValues(alpha: .15),
              valueColor: AlwaysStoppedAnimation(_color),
            ),
          ),
        ],
      ),
    );
  }
}

class _WeakChip extends StatelessWidget {
  final SubjectPerf perf;
  const _WeakChip({required this.perf});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(color: const Color(0xFFEF4444).withValues(alpha: .10), borderRadius: BorderRadius.circular(10)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        const Icon(Icons.trending_down_rounded, size: 16, color: Color(0xFFEF4444)),
        const SizedBox(width: 6),
        Text('${perf.subject} · ${perf.accuracy.toStringAsFixed(0)}%', style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: Color(0xFFB91C1C))),
      ]),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);
  @override
  Widget build(BuildContext context) => Text(text, style: const TextStyle(fontFamily: 'Poppins', fontSize: 17, fontWeight: FontWeight.w700));
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.insights_rounded, size: 46, color: Colors.grey.shade400),
          const SizedBox(height: 14),
          const Text('No progress yet', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          Text('Read articles and take practice tests — your stats will appear here.', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey.shade600)),
          const SizedBox(height: 16),
          FilledButton.tonal(onPressed: () => context.go('/learn'), child: const Text('Start learning')),
        ]),
      ),
    );
  }
}

class _Retry extends StatelessWidget {
  final VoidCallback onRetry;
  const _Retry({required this.onRetry});
  @override
  Widget build(BuildContext context) => Center(
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      Icon(Icons.wifi_off_rounded, size: 44, color: Colors.grey.shade400),
      const SizedBox(height: 12),
      const Text('Could not load your progress'),
      const SizedBox(height: 12),
      FilledButton.tonal(onPressed: onRetry, child: const Text('Retry')),
    ]),
  );
}
