import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/providers/subscription_provider.dart';
import '../../../shared/widgets/app_widgets.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).user;
    final subs = ref.watch(subscriptionStatusProvider);

    if (user == null) return const LoadingWidget();

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            backgroundColor: const Color(0xFF4F46E5),
            title: const Text('Profile', style: TextStyle(color: Colors.white)),
            actions: [
              IconButton(
                icon: const Icon(Icons.edit_outlined, color: Colors.white),
                onPressed: () => context.push('/profile/edit'),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF4F46E5), Color(0xFF7C3AED)],
                  ),
                ),
                child: SafeArea(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 40),
                      CircleAvatar(
                        radius: 42,
                        backgroundColor: Colors.white.withValues(alpha: 0.2),
                        backgroundImage: user.avatar != null
                            ? NetworkImage(user.avatar!)
                            : null,
                        child: user.avatar == null
                            ? Text(
                                user.name.isNotEmpty
                                    ? user.name[0].toUpperCase()
                                    : 'U',
                                style: const TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 28,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                ),
                              )
                            : null,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        user.name,
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        user.email,
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          color: Colors.white70,
                          fontSize: 12,
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
                children: [
                  // Subscription card
                  subs.when(
                    data: (s) => GestureDetector(
                      onTap: () => context.push('/profile/plans'),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          gradient: s.isSubscribed
                              ? const LinearGradient(
                                  colors: [
                                    Color(0xFF10B981),
                                    Color(0xFF059669),
                                  ],
                                )
                              : const LinearGradient(
                                  colors: [
                                    Color(0xFF4F46E5),
                                    Color(0xFF7C3AED),
                                  ],
                                ),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              s.isSubscribed
                                  ? Icons.verified
                                  : Icons.star_outline,
                              color: Colors.white,
                              size: 32,
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    s.isSubscribed
                                        ? 'Premium Active'
                                        : 'Upgrade to Premium',
                                    style: const TextStyle(
                                      fontFamily: 'Poppins',
                                      color: Colors.white,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 15,
                                    ),
                                  ),
                                  Text(
                                    s.isSubscribed
                                        ? 'Valid till ${s.subscription?.endDate ?? ""}'
                                        : 'Unlock all content & exams',
                                    style: const TextStyle(
                                      fontFamily: 'Poppins',
                                      color: Colors.white70,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(
                              Icons.chevron_right,
                              color: Colors.white,
                            ),
                          ],
                        ),
                      ),
                    ),
                    loading: () => const ShimmerCard(height: 80),
                    error: (_, _) => const SizedBox.shrink(),
                  ),
                  const SizedBox(height: 24),

                  _Section(
                    title: 'Learning',
                    tiles: [
                      _Tile(
                        icon: Icons.bookmarks_outlined,
                        label: 'Revision Hub',
                        onTap: () => context.push('/revision'),
                      ),
                      _Tile(
                        icon: Icons.insights_outlined,
                        label: 'My Progress',
                        onTap: () => context.push('/progress'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  _Section(
                    title: 'Account',
                    tiles: [
                      _Tile(
                        icon: Icons.person_outline,
                        label: 'Edit Profile',
                        onTap: () => context.push('/profile/edit'),
                      ),
                      _Tile(
                        icon: Icons.card_giftcard_outlined,
                        label: 'Referral & Rewards',
                        onTap: () => context.push('/profile/referral'),
                        badge: user.referralCode,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  _Section(
                    title: 'App',
                    tiles: [
                      _Tile(
                        icon: Icons.notifications_outlined,
                        label: 'Notifications',
                        onTap: () => context.push('/notifications'),
                      ),
                      _Tile(
                        icon: Icons.help_outline,
                        label: 'Help & Support',
                        onTap: () {},
                      ),
                      _Tile(
                        icon: Icons.info_outline,
                        label: 'About',
                        onTap: () {},
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  _Section(
                    title: 'Account',
                    tiles: [
                      _Tile(
                        icon: Icons.logout,
                        label: 'Sign Out',
                        color: Colors.red,
                        onTap: () => _confirmLogout(context, ref),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _confirmLogout(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text(
          'Sign Out?',
          style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700),
        ),
        content: const Text(
          'You will be logged out from this device.',
          style: TextStyle(fontFamily: 'Poppins'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              ref.read(authProvider.notifier).logout();
            },
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final List<_Tile> tiles;
  const _Section({required this.title, required this.tiles});

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Padding(
        padding: const EdgeInsets.only(left: 4, bottom: 8),
        child: Text(
          title,
          style: const TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w600,
            fontSize: 13,
            color: Colors.black45,
            letterSpacing: 0.5,
          ),
        ),
      ),
      Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: tiles
              .asMap()
              .entries
              .map(
                (e) => Column(
                  children: [
                    e.value,
                    if (e.key < tiles.length - 1)
                      const Divider(height: 1, indent: 56, endIndent: 16),
                  ],
                ),
              )
              .toList(),
        ),
      ),
    ],
  );
}

class _Tile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? badge;
  final Color? color;
  final VoidCallback onTap;

  const _Tile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.badge,
    this.color,
  });

  @override
  Widget build(BuildContext context) => ListTile(
    leading: Icon(icon, color: color ?? const Color(0xFF4F46E5)),
    title: Text(
      label,
      style: TextStyle(
        fontFamily: 'Poppins',
        color: color ?? Colors.black87,
        fontWeight: FontWeight.w500,
      ),
    ),
    trailing: badge != null
        ? Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: const Color(0xFFEEF2FF),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              badge!,
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 11,
                color: Color(0xFF4F46E5),
                fontWeight: FontWeight.w600,
              ),
            ),
          )
        : const Icon(Icons.chevron_right, color: Colors.black38),
    onTap: onTap,
  );
}
