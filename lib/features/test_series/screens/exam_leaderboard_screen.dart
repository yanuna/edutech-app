import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/test_series.dart';
import '../../../core/providers/test_series_provider.dart';
import '../../../shared/widgets/app_widgets.dart';
import '../../../core/api/api_client.dart';

class ExamLeaderboardScreen extends ConsumerWidget {
  final int examId;
  const ExamLeaderboardScreen({super.key, required this.examId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final board = ref.watch(examLeaderboardProvider(examId));

    return Scaffold(
      appBar: AppBar(title: const Text('Leaderboard')),
      body: board.when(
        data: (data) => RefreshIndicator(
          onRefresh: () => ref.refresh(examLeaderboardProvider(examId).future),
          child: !data.rankingsGenerated
              ? _Pending(name: data.examName)
              : data.entries.isEmpty
              ? const _NoParticipants()
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: data.entries.length + 1,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (_, i) {
                    if (i == 0) {
                      return Text(
                        data.examName,
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      );
                    }
                    return _RankTile(entry: data.entries[i - 1]);
                  },
                ),
        ),
        loading: () => ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: 8,
          itemBuilder: (_, _) => const ShimmerCard(height: 64),
        ),
        error: (e, _) => ErrorRetryWidget(
          message: apiErrorMessage(e),
          onRetry: () => ref.invalidate(examLeaderboardProvider(examId)),
        ),
      ),
    );
  }
}

class _RankTile extends StatelessWidget {
  final LeaderboardEntry entry;
  const _RankTile({required this.entry});

  Color get _color => switch (entry.rank) {
    1 => const Color(0xFFF59E0B),
    2 => Colors.blueGrey,
    3 => const Color(0xFFB45309),
    _ => const Color(0xFF4F46E5),
  };

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: _color.withValues(alpha: 0.15),
            child: entry.rank <= 3
                ? Icon(Icons.emoji_events, color: _color, size: 20)
                : Text(
                    '${entry.rank}',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w700,
                      color: _color,
                    ),
                  ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              entry.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                entry.marks.toStringAsFixed(1),
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
              ),
              if (entry.percentile != null)
                Text(
                  '${entry.percentile!.toStringAsFixed(1)} pct',
                  style: const TextStyle(
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
  );
}

class _Pending extends StatelessWidget {
  final String name;
  const _Pending({required this.name});

  @override
  Widget build(BuildContext context) => ListView(
    children: [
      const SizedBox(height: 120),
      const Icon(Icons.hourglass_top, size: 64, color: Color(0xFFF59E0B)),
      const SizedBox(height: 16),
      Center(
        child: Text(
          name,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontFamily: 'Poppins',
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      const SizedBox(height: 8),
      const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 32),
          child: Text(
            'Rankings will be generated once the exam ends. Check back then!',
            textAlign: TextAlign.center,
            style: TextStyle(fontFamily: 'Poppins', color: Colors.black54),
          ),
        ),
      ),
    ],
  );
}

class _NoParticipants extends StatelessWidget {
  const _NoParticipants();

  @override
  Widget build(BuildContext context) => ListView(
    children: const [
      SizedBox(height: 140),
      Icon(Icons.groups_outlined, size: 64, color: Colors.black26),
      SizedBox(height: 12),
      Center(
        child: Text(
          'No ranked participants',
          style: TextStyle(fontFamily: 'Poppins', color: Colors.black54),
        ),
      ),
    ],
  );
}
