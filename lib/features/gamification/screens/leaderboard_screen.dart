import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/providers/gamification_provider.dart';
import '../../../shared/widgets/app_widgets.dart';

class LeaderboardScreen extends ConsumerStatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  ConsumerState<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends ConsumerState<LeaderboardScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;
  final _periods = ['weekly', 'monthly', 'all_time'];
  final _labels = ['This Week', 'This Month', 'All Time'];

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final me = ref.watch(authProvider).user;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Leaderboard'),
        bottom: TabBar(
          controller: _tabs,
          tabs: _labels.map((l) => Tab(text: l)).toList(),
          indicatorColor: Theme.of(context).colorScheme.primary,
          labelColor: Theme.of(context).colorScheme.primary,
          unselectedLabelColor: Colors.grey,
        ),
      ),
      body: TabBarView(
        controller: _tabs,
        children: _periods.map((period) {
          final data = ref.watch(leaderboardProvider(period));
          return data.when(
            loading: () => const LoadingWidget(message: 'Loading leaderboard…'),
            error: (e, _) => ErrorRetryWidget(
              message: e.toString(),
              onRetry: () => ref.invalidate(leaderboardProvider(period)),
            ),
            data: (lb) => _Board(lb: lb, myUserId: me?.id),
          );
        }).toList(),
      ),
    );
  }
}

class _Board extends StatelessWidget {
  final LeaderboardData lb;
  final int? myUserId;

  const _Board({required this.lb, this.myUserId});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // My rank banner
        if (lb.myRank != null)
          Container(
            margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF4F46E5), Color(0xFF7C3AED)],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.emoji_events, color: Colors.amber, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Your Rank: #${lb.myRank}  ·  Score: ${lb.myScore}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: lb.top.length,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (ctx, i) {
              final entry = lb.top[i];
              final isMe = entry.userId == myUserId;
              return _EntryTile(entry: entry, isMe: isMe);
            },
          ),
        ),
      ],
    );
  }
}

class _EntryTile extends StatelessWidget {
  final LeaderboardEntry entry;
  final bool isMe;

  const _EntryTile({required this.entry, required this.isMe});

  Widget _rankWidget() {
    if (entry.rank == 1) {
      return const Text('🥇', style: TextStyle(fontSize: 22));
    }
    if (entry.rank == 2) {
      return const Text('🥈', style: TextStyle(fontSize: 22));
    }
    if (entry.rank == 3) {
      return const Text('🥉', style: TextStyle(fontSize: 22));
    }
    return Container(
      width: 32,
      height: 32,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        shape: BoxShape.circle,
      ),
      child: Text(
        '${entry.rank}',
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: isMe ? const Color(0xFFEEF2FF) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isMe ? const Color(0xFF4F46E5) : Colors.grey.shade100,
          width: isMe ? 1.5 : 1,
        ),
      ),
      child: Row(
        children: [
          _rankWidget(),
          const SizedBox(width: 12),
          CircleAvatar(
            radius: 18,
            backgroundColor: const Color(0xFF4F46E5).withValues(alpha: 0.15),
            backgroundImage: entry.avatar != null
                ? NetworkImage(entry.avatar!)
                : null,
            child: entry.avatar == null
                ? Text(
                    entry.name.isNotEmpty ? entry.name[0].toUpperCase() : '?',
                    style: const TextStyle(
                      color: Color(0xFF4F46E5),
                      fontWeight: FontWeight.w700,
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.name + (isMe ? ' (You)' : ''),
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    color: isMe
                        ? const Color(0xFF4F46E5)
                        : const Color(0xFF1F2937),
                  ),
                ),
                Text(
                  '${entry.examsTaken} exams · ${entry.xp} XP',
                  style: const TextStyle(
                    fontSize: 11,
                    color: Colors.grey,
                    fontFamily: 'Poppins',
                  ),
                ),
              ],
            ),
          ),
          Text(
            '${entry.score}',
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w700,
              fontSize: 15,
              color: Color(0xFF4F46E5),
            ),
          ),
        ],
      ),
    );
  }
}
