import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/providers/exam_provider.dart';
import '../../../core/models/exam.dart';
import '../../../shared/widgets/app_widgets.dart';

class ExamHistoryScreen extends ConsumerWidget {
  const ExamHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final history = ref.watch(examHistoryProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('My Exams')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/exam/setup'),
        icon: const Icon(Icons.add),
        label: const Text(
          'Generate Test',
          style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600),
        ),
      ),
      body: history.when(
        data: (list) => RefreshIndicator(
          onRefresh: () => ref.refresh(examHistoryProvider.future),
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              const _TestSeriesBanner(),
              const SizedBox(height: 20),
              const Text(
                'Recent Attempts',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
              if (list.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Center(
                    child: Text(
                      'No attempts yet — generate your first test!',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        color: Colors.black54,
                      ),
                    ),
                  ),
                )
              else
                ...list.map(
                  (item) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _HistoryTile(item: item),
                  ),
                ),
            ],
          ),
        ),
        loading: () => ListView.builder(
          padding: const EdgeInsets.all(20),
          itemCount: 5,
          itemBuilder: (_, _) => const ShimmerCard(height: 80),
        ),
        error: (e, _) => ErrorRetryWidget(
          message: e.toString(),
          onRetry: () => ref.invalidate(examHistoryProvider),
        ),
      ),
    );
  }
}

/// Entry point to the admin-created Test Series, shown above the user's own
/// generated-exam history (the two options from the spec).
class _TestSeriesBanner extends StatelessWidget {
  const _TestSeriesBanner();

  @override
  Widget build(BuildContext context) => InkWell(
    borderRadius: BorderRadius.circular(18),
    onTap: () => context.push('/exam/test-series'),
    child: Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF4F46E5), Color(0xFF7C3AED)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          const Icon(Icons.emoji_events, color: Colors.white, size: 34),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Test Series',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Part & Full mock tests with live rankings',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.arrow_forward_ios, color: Colors.white, size: 16),
        ],
      ),
    ),
  );
}

class _HistoryTile extends StatelessWidget {
  final ExamHistoryItem item;
  const _HistoryTile({required this.item});

  @override
  Widget build(BuildContext context) {
    final dt = DateTime.tryParse(item.startTime);
    final dateStr = dt != null
        ? DateFormat('dd MMM yyyy, hh:mm a').format(dt.toLocal())
        : item.startTime;

    Color statusColor;
    IconData statusIcon;
    switch (item.status) {
      case 'completed':
        statusColor = const Color(0xFF10B981);
        statusIcon = Icons.check_circle;
        break;
      case 'in_progress':
        statusColor = const Color(0xFFF59E0B);
        statusIcon = Icons.pending;
        break;
      default:
        statusColor = Colors.grey;
        statusIcon = Icons.info_outline;
    }

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => item.status == 'completed'
            ? context.push('/exam/${item.id}/result')
            : context.push('/exam/${item.id}/take'),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: statusColor.withValues(alpha: 0.1),
                child: Icon(statusIcon, color: statusColor),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Exam #${item.id}',
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      dateStr,
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 12,
                        color: Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),
              if (item.totalScore != null)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      item.totalScore!.toStringAsFixed(1),
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w700,
                        fontSize: 18,
                        color: statusColor,
                      ),
                    ),
                    Text(
                      '${item.totalCorrect ?? 0} correct',
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 10,
                      ),
                    ),
                  ],
                )
              else
                const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}
