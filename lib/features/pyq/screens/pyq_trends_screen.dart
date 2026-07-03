import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/pyq_question_provider.dart';

/// PYQ trend analysis — how many previous-year questions came from each year
/// and each subject. Simple accessible bars (no chart dependency).
class PyqTrendsScreen extends ConsumerWidget {
  const PyqTrendsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(pyqTrendsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('PYQ Trends')),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Text('Could not load trends'),
          const SizedBox(height: 12),
          FilledButton.tonal(onPressed: () => ref.invalidate(pyqTrendsProvider), child: const Text('Retry')),
        ])),
        data: (t) => t.total == 0
            ? const Center(child: Padding(padding: EdgeInsets.all(32), child: Text('No PYQ data yet.', textAlign: TextAlign.center)))
            : ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _Total(total: t.total),
                  const SizedBox(height: 24),
                  const _Title('Questions by Year'),
                  const SizedBox(height: 12),
                  _Bars(
                    color: const Color(0xFF6366F1),
                    rows: [for (final y in t.byYear) (label: '${y.year}', value: y.count)],
                  ),
                  const SizedBox(height: 28),
                  const _Title('Questions by Subject'),
                  const SizedBox(height: 12),
                  _Bars(
                    color: const Color(0xFF0EA5E9),
                    rows: [for (final s in t.bySubject) (label: s.subject, value: s.count)],
                  ),
                ],
              ),
      ),
    );
  }
}

class _Total extends StatelessWidget {
  final int total;
  const _Total({required this.total});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFF4F46E5), Color(0xFF7C3AED)]),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(children: [
        const Icon(Icons.history_edu_rounded, color: Colors.white70, size: 40),
        const SizedBox(width: 14),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('$total', style: const TextStyle(fontFamily: 'Poppins', color: Colors.white, fontSize: 26, fontWeight: FontWeight.w800)),
          const Text('Previous-year questions', style: TextStyle(color: Colors.white70, fontSize: 12.5)),
        ]),
      ]),
    );
  }
}

class _Bars extends StatelessWidget {
  final Color color;
  final List<({String label, int value})> rows;
  const _Bars({required this.color, required this.rows});

  @override
  Widget build(BuildContext context) {
    if (rows.isEmpty) return Text('No data', style: TextStyle(color: Colors.grey.shade600));
    final max = rows.map((r) => r.value).fold(1, (a, b) => a > b ? a : b);
    return Column(
      children: [
        for (final r in rows)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              children: [
                SizedBox(width: 96, child: Text(r.label, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600))),
                const SizedBox(width: 10),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: (r.value / max).clamp(0.05, 1),
                      minHeight: 18,
                      backgroundColor: color.withValues(alpha: .10),
                      valueColor: AlwaysStoppedAnimation(color),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(width: 32, child: Text('${r.value}', textAlign: TextAlign.right, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700))),
              ],
            ),
          ),
      ],
    );
  }
}

class _Title extends StatelessWidget {
  final String text;
  const _Title(this.text);
  @override
  Widget build(BuildContext context) => Text(text, style: const TextStyle(fontFamily: 'Poppins', fontSize: 17, fontWeight: FontWeight.w700));
}
