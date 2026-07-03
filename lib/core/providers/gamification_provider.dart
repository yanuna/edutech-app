import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../api/api_client.dart';

class StreakInfo {
  final int current;
  final int longest;
  final bool active;

  const StreakInfo({
    required this.current,
    required this.longest,
    required this.active,
  });

  factory StreakInfo.fromJson(Map<String, dynamic> j) => StreakInfo(
    current: (j['current'] as int?) ?? 0,
    longest: (j['longest'] as int?) ?? 0,
    active: (j['active'] as bool?) ?? false,
  );
}

class AchievementItem {
  final int id;
  final String slug;
  final String name;
  final String description;
  final String iconEmoji;
  final String badgeColor;
  final String unlockedAt;

  const AchievementItem({
    required this.id,
    required this.slug,
    required this.name,
    required this.description,
    required this.iconEmoji,
    required this.badgeColor,
    required this.unlockedAt,
  });

  factory AchievementItem.fromJson(Map<String, dynamic> j) => AchievementItem(
    id: (j['id'] as int?) ?? 0,
    slug: j['slug'] as String? ?? '',
    name: j['name'] as String? ?? '',
    description: j['description'] as String? ?? '',
    iconEmoji: j['icon_emoji'] as String? ?? '🏆',
    badgeColor: j['badge_color'] as String? ?? '#4F46E5',
    unlockedAt: j['unlocked_at'] as String? ?? '',
  );
}

class GamificationProfile {
  final int totalXp;
  final StreakInfo streak;
  final List<AchievementItem> achievements;

  const GamificationProfile({
    required this.totalXp,
    required this.streak,
    required this.achievements,
  });

  factory GamificationProfile.fromJson(Map<String, dynamic> j) =>
      GamificationProfile(
        totalXp: (j['total_xp'] as int?) ?? 0,
        streak: StreakInfo.fromJson(j['streak'] as Map<String, dynamic>? ?? {}),
        achievements: (j['achievements'] as List<dynamic>? ?? [])
            .map((e) => AchievementItem.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

class LeaderboardEntry {
  final int rank;
  final int userId;
  final String name;
  final String? avatar;
  final int score;
  final int examsTaken;
  final int xp;

  const LeaderboardEntry({
    required this.rank,
    required this.userId,
    required this.name,
    this.avatar,
    required this.score,
    required this.examsTaken,
    required this.xp,
  });

  factory LeaderboardEntry.fromJson(Map<String, dynamic> j) => LeaderboardEntry(
    rank: (j['rank'] as int?) ?? 0,
    userId: (j['user_id'] as int?) ?? 0,
    name: (j['name'] as String?) ?? '',
    avatar: j['avatar'] as String?,
    score: (j['score'] as int?) ?? 0,
    examsTaken: (j['exams_taken'] as int?) ?? 0,
    xp: (j['xp'] as int?) ?? 0,
  );
}

class LeaderboardData {
  final String period;
  final List<LeaderboardEntry> top;
  final int? myRank;
  final int? myScore;

  const LeaderboardData({
    required this.period,
    required this.top,
    this.myRank,
    this.myScore,
  });

  factory LeaderboardData.fromJson(Map<String, dynamic> j) => LeaderboardData(
    period: (j['period'] as String?) ?? 'weekly',
    top: (j['top'] as List<dynamic>? ?? [])
        .map((e) => LeaderboardEntry.fromJson(e as Map<String, dynamic>))
        .toList(),
    myRank: j['my_rank'] as int?,
    myScore: j['my_score'] as int?,
  );
}

// ── Providers ─────────────────────────────────────────────────────────────────

final gamificationProfileProvider = FutureProvider<GamificationProfile>((
  ref,
) async {
  final res = await ApiClient.instance.get('/gamification/profile');
  return GamificationProfile.fromJson(res.data as Map<String, dynamic>);
});

final leaderboardProvider = FutureProvider.family<LeaderboardData, String>((
  ref,
  period,
) async {
  final res = await ApiClient.instance.get(
    '/gamification/leaderboard',
    params: {'period': period},
  );
  return LeaderboardData.fromJson(res.data as Map<String, dynamic>);
});
