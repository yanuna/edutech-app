import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/providers/catalog_provider.dart';
import '../../core/providers/exam_provider.dart';
import '../../core/providers/subscription_provider.dart';
import '../../core/services/startup_service.dart';
import '../../core/models/catalog.dart';
import '../../shared/widgets/app_widgets.dart';
import '../../shared/widgets/ad_banner_widget.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).user;
    final subs = ref.watch(subscriptionStatusProvider);
    final subjects = ref.watch(subjectsProvider);
    final mods = ref.watch(enabledModulesProvider);
    final activeExam = ref.watch(activeExamProvider);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 160,
            floating: false,
            pinned: true,
            backgroundColor: const Color(0xFF4F46E5),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF4F46E5), Color(0xFF7C3AED)],
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          'Hello, ${user?.name.split(' ').first ?? 'there'} 👋',
                          style: const TextStyle(
                            fontFamily: 'Poppins',
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'What would you like to learn today?',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            color: Colors.white70,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(
                  Icons.notifications_outlined,
                  color: Colors.white,
                ),
                onPressed: () {},
              ),
            ],
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Resume an in-progress exam after a crash/restart.
                  activeExam.maybeWhen(
                    data: (sessionId) => sessionId == null
                        ? const SizedBox.shrink()
                        : Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: _ResumeExamBanner(sessionId: sessionId),
                          ),
                    orElse: () => const SizedBox.shrink(),
                  ),
                  // Subscription banner
                  subs.when(
                    data: (s) => !s.isSubscribed
                        ? PaywallWidget(
                            onSubscribe: () => context.push('/profile/plans'),
                          )
                        : _SubscribedBanner(
                            expiryDate: s.subscription?.endDate,
                          ),
                    loading: () => const ShimmerCard(height: 100),
                    error: (_, _) => const SizedBox.shrink(),
                  ),
                  const SizedBox(height: 16),
                  // Ad banner between subscription status and quick actions
                  // (hidden for subscribed users at the AdService level)
                  const Center(child: AdBannerWidget()),
                  const SizedBox(height: 20),

                  // Quick actions (shown only for enabled modules)
                  Row(
                    children: [
                      if (mods.contains('study_material')) ...[
                        _QuickAction(
                          icon: Icons.library_books,
                          label: 'Study',
                          color: const Color(0xFF4F46E5),
                          onTap: () => context.go('/subjects'),
                        ),
                        const SizedBox(width: 12),
                      ],
                      // PYQs — free & login-gated, always available.
                      _QuickAction(
                        icon: Icons.picture_as_pdf_outlined,
                        label: 'PYQs',
                        color: const Color(0xFFEF4444),
                        onTap: () => context.push('/pyqs'),
                      ),
                      const SizedBox(width: 12),
                      if (mods.contains('exam')) ...[
                        _QuickAction(
                          icon: Icons.quiz,
                          label: 'Exam',
                          color: const Color(0xFF7C3AED),
                          onTap: () => context.go('/exam'),
                        ),
                        const SizedBox(width: 12),
                      ],
                      if (mods.contains('gamification')) ...[
                        _QuickAction(
                          icon: Icons.leaderboard_outlined,
                          label: 'Rank',
                          color: const Color(0xFFF59E0B),
                          onTap: () => context.push('/profile/leaderboard'),
                        ),
                        const SizedBox(width: 12),
                      ],
                      if (mods.contains('govt_jobs'))
                        _QuickAction(
                          icon: Icons.work_outline,
                          label: 'Jobs',
                          color: const Color(0xFF10B981),
                          onTap: () => context.push('/govt-jobs'),
                        ),
                    ],
                  ),
                  const SizedBox(height: 28),

                  // Subjects
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Subjects',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      TextButton(
                        onPressed: () => context.go('/subjects'),
                        child: const Text(
                          'See all',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            color: Color(0xFF4F46E5),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          subjects.when(
            data: (list) => SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              sliver: SliverGrid(
                delegate: SliverChildBuilderDelegate(
                  (_, i) => _SubjectCard(subject: list[i]),
                  childCount: list.length > 6 ? 6 : list.length,
                ),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.3,
                ),
              ),
            ),
            loading: () => SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (_, _) => const ShimmerCard(height: 100),
                  childCount: 4,
                ),
              ),
            ),
            error: (e, _) => SliverToBoxAdapter(
              child: ErrorRetryWidget(
                message: e.toString(),
                onRetry: () => ref.invalidate(subjectsProvider),
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 24)),
        ],
      ),
    );
  }
}

class _SubscribedBanner extends StatelessWidget {
  final String? expiryDate;
  const _SubscribedBanner({this.expiryDate});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    decoration: BoxDecoration(
      color: const Color(0xFFECFDF5),
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.3)),
    ),
    child: Row(
      children: [
        const Icon(Icons.verified, color: Color(0xFF10B981)),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Premium Active',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w600,
                color: Color(0xFF065F46),
              ),
            ),
            if (expiryDate != null)
              Text(
                'Valid until $expiryDate',
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 11,
                  color: Color(0xFF6EE7B7),
                ),
              ),
          ],
        ),
      ],
    ),
  );
}

class _ResumeExamBanner extends StatelessWidget {
  final int sessionId;
  const _ResumeExamBanner({required this.sessionId});

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: () => context.push('/exam/$sessionId/take'),
    borderRadius: BorderRadius.circular(14),
    child: Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF3C7),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFFF59E0B).withValues(alpha: 0.4),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.play_circle_fill,
            color: Color(0xFFD97706),
            size: 30,
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Resume your exam',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF92400E),
                  ),
                ),
                Text(
                  'You have an attempt in progress. Tap to continue.',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 12,
                    color: Color(0xFFB45309),
                  ),
                ),
              ],
            ),
          ),
          const Icon(
            Icons.arrow_forward_ios,
            size: 14,
            color: Color(0xFFD97706),
          ),
        ],
      ),
    ),
  );
}

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _QuickAction({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => Expanded(
    child: GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 26),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _SubjectCard extends StatelessWidget {
  final Subject subject;
  const _SubjectCard({required this.subject});

  @override
  Widget build(BuildContext context) {
    final colors = [
      const Color(0xFF4F46E5),
      const Color(0xFF7C3AED),
      const Color(0xFF0EA5E9),
      const Color(0xFF10B981),
      const Color(0xFFF59E0B),
      const Color(0xFFEF4444),
    ];
    final color = colors[subject.id % colors.length];

    return GestureDetector(
      onTap: () => context.push(
        '/subjects/${subject.id}/chapters?name=${Uri.encodeComponent(subject.name)}',
      ),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [color, color.withValues(alpha: 0.75)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Stack(
          children: [
            Positioned(
              right: -20,
              bottom: -20,
              child: Icon(
                Icons.circle,
                size: 100,
                color: Colors.white.withValues(alpha: 0.08),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (subject.isPaid)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.amber,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        'PRO',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          color: Colors.black,
                        ),
                      ),
                    ),
                  const Spacer(),
                  Text(
                    subject.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
