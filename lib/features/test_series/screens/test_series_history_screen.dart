import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/models/test_series.dart';
import '../../../core/providers/test_series_provider.dart';
import '../../../shared/widgets/app_widgets.dart';
import '../../../core/api/api_client.dart';

class TestSeriesHistoryScreen extends ConsumerWidget {
  const TestSeriesHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final history = ref.watch(testSeriesHistoryProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('My Test Series')),
      body: history.when(
        data: (list) => list.isEmpty
            ? const _Empty()
            : RefreshIndicator(
                onRefresh: () => ref.refresh(testSeriesHistoryProvider.future),
                child: ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: list.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (_, i) => _HistoryTile(item: list[i]),
                ),
              ),
        loading: () => ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: 6,
          itemBuilder: (_, _) => const ShimmerCard(height: 84),
        ),
        error: (e, _) => ErrorRetryWidget(
          message: apiErrorMessage(e),
          onRetry: () => ref.invalidate(testSeriesHistoryProvider),
        ),
      ),
    );
  }
}

class _HistoryTile extends StatelessWidget {
  final TestSeriesHistoryItem item;
  const _HistoryTile({required this.item});

  @override
  Widget build(BuildContext context) {
    final date = DateFormat(
      'dd MMM yyyy, hh:mm a',
    ).format(item.attemptDate.toLocal());

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => context.push('/exam/${item.sessionId}/result'),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFEEF2FF),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  item.type == 'full'
                      ? Icons.workspace_premium
                      : Icons.menu_book,
                  color: const Color(0xFF4F46E5),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.examName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      date,
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 12,
                        color: Colors.black54,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      item.isRanked
                          ? (item.rank != null
                                ? 'Rank #${item.rank}'
                                : 'Rank pending')
                          : 'Not ranked (late attempt)',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: item.isRanked
                            ? const Color(0xFF4F46E5)
                            : Colors.black45,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    item.marks.toStringAsFixed(1),
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w700,
                      fontSize: 18,
                      color: Color(0xFF10B981),
                    ),
                  ),
                  const Text(
                    'marks',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 10,
                      color: Colors.black45,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty();

  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: const [
        Icon(Icons.history_edu, size: 64, color: Color(0xFF4F46E5)),
        SizedBox(height: 12),
        Text(
          'No attempts yet',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        SizedBox(height: 6),
        Text(
          'Your Test Series results will appear here.',
          style: TextStyle(fontFamily: 'Poppins', color: Colors.black54),
        ),
      ],
    ),
  );
}
