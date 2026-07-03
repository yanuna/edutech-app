import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/models/article.dart';
import '../../core/providers/article_provider.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/providers/exam_provider.dart';
import '../../core/providers/gamification_provider.dart';
import '../../core/providers/subscription_provider.dart';
import '../../core/services/startup_service.dart';
import '../../shared/widgets/app_widgets.dart';
import '../../shared/widgets/ad_banner_widget.dart';

/// The Home dashboard — a personalised study cockpit: exam countdown, continue
/// reading, streak, today's articles, quick actions, and (preserved) the
/// resume-exam / subscription / ad surfaces.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  // TODO: make configurable via admin settings. Next UPSC CSE Prelims.
  static final DateTime _prelimsDate = DateTime(2027, 5, 23);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).user;
    final subs = ref.watch(subscriptionStatusProvider);
    final mods = ref.watch(enabledModulesProvider);
    final activeExam = ref.watch(activeExamProvider);

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(continueReadingProvider);
          ref.invalidate(gamificationProfileProvider);
          ref.invalidate(articleListProvider(const ArticleQuery(featured: true)));
        },
        child: CustomScrollView(
          slivers: [
            _header(context, user?.name.split(' ').first ?? 'there'),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Resume an in-progress exam after a crash/restart (preserved).
                    activeExam.maybeWhen(
                      data: (sessionId) => sessionId == null
                          ? const SizedBox.shrink()
                          : Padding(padding: const EdgeInsets.only(bottom: 16), child: _ResumeExamBanner(sessionId: sessionId)),
                      orElse: () => const SizedBox.shrink(),
                    ),

                    _CountdownCard(examDate: _prelimsDate),
                    const SizedBox(height: 20),

                    _StreakRow(),
                    const SizedBox(height: 4),

                    const _ContinueReading(),
                    const _TodaysArticles(),

                    // Subscription status / paywall (preserved monetisation).
                    subs.when(
                      data: (s) => !s.isSubscribed
                          ? PaywallWidget(onSubscribe: () => context.push('/profile/plans'))
                          : _SubscribedBanner(expiryDate: s.subscription?.endDate),
                      loading: () => const ShimmerCard(height: 90),
                      error: (_, _) => const SizedBox.shrink(),
                    ),
                    const SizedBox(height: 20),

                    const _SectionTitle('Quick Actions'),
                    const SizedBox(height: 12),
                    _QuickActions(mods: mods),
                    const SizedBox(height: 20),

                    const Center(child: AdBannerWidget()),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _header(BuildContext context, String firstName) {
    return SliverAppBar(
      expandedHeight: 172,
      pinned: true,
      backgroundColor: const Color(0xFF4F46E5),
      actions: [
        IconButton(icon: const Icon(Icons.notifications_outlined, color: Colors.white), onPressed: () {}),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(gradient: LinearGradient(colors: [Color(0xFF4F46E5), Color(0xFF7C3AED)])),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text('Hello, $firstName 👋', style: const TextStyle(fontFamily: 'Poppins', color: Colors.white, fontSize: 22, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 12),
                  // Tappable search bar → universal search.
                  GestureDetector(
                    onTap: () => context.push('/search'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(color: Colors.white.withValues(alpha: .18), borderRadius: BorderRadius.circular(12)),
                      child: Row(children: const [
                        Icon(Icons.search, color: Colors.white70, size: 20),
                        SizedBox(width: 10),
                        Text('Search articles, MCQs, PYQs…', style: TextStyle(color: Colors.white70, fontSize: 13.5)),
                      ]),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Exam countdown ──────────────────────────────────────────────────────────
class _CountdownCard extends StatelessWidget {
  final DateTime examDate;
  const _CountdownCard({required this.examDate});

  @override
  Widget build(BuildContext context) {
    final days = examDate.difference(DateTime.now()).inDays;
    if (days < 0) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFF0F172A), Color(0xFF334155)]),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('UPSC Prelims 2027', style: TextStyle(color: Colors.white70, fontSize: 12.5, fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              Text('$days days to go', style: const TextStyle(fontFamily: 'Poppins', color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800)),
            ],
          ),
          const Spacer(),
          const Icon(Icons.flag_circle_outlined, color: Colors.white24, size: 54),
        ],
      ),
    );
  }
}

// ── Streak + XP tiles ───────────────────────────────────────────────────────
class _StreakRow extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(gamificationProfileProvider);
    return async.maybeWhen(
      data: (p) => Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Row(
          children: [
            _StatTile(icon: Icons.local_fire_department_rounded, color: const Color(0xFFF97316), value: '${p.streak.current}', label: p.streak.current == 1 ? 'day streak' : 'day streak'),
            const SizedBox(width: 12),
            _StatTile(icon: Icons.bolt_rounded, color: const Color(0xFF6366F1), value: '${p.totalXp}', label: 'XP earned'),
          ],
        ),
      ),
      orElse: () => const SizedBox.shrink(),
    );
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
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(color: color.withValues(alpha: .10), borderRadius: BorderRadius.circular(14)),
        child: Row(children: [
          Icon(icon, color: color, size: 26),
          const SizedBox(width: 10),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(value, style: TextStyle(fontFamily: 'Poppins', fontSize: 18, fontWeight: FontWeight.w800, color: color)),
            Text(label, style: TextStyle(fontSize: 11.5, color: Colors.grey.shade600)),
          ]),
        ]),
      ),
    );
  }
}

// ── Continue reading ────────────────────────────────────────────────────────
class _ContinueReading extends ConsumerWidget {
  const _ContinueReading();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(continueReadingProvider);
    return async.maybeWhen(
      data: (items) => items.isEmpty
          ? const SizedBox.shrink()
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _SectionTitle('Continue Reading'),
                const SizedBox(height: 10),
                SizedBox(
                  height: 96,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: items.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 12),
                    itemBuilder: (_, i) => _ContinueCard(card: items[i]),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
      orElse: () => const SizedBox.shrink(),
    );
  }
}

class _ContinueCard extends StatelessWidget {
  final ArticleCard card;
  const _ContinueCard({required this.card});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 280,
      child: InkWell(
        onTap: () => context.push('/learn/article/${card.slug}'),
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(14), border: Border.all(color: Theme.of(context).dividerColor.withValues(alpha: .5))),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(card.title, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
              Row(children: [
                Expanded(child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: 0.4, // visual hint; exact resume percent lives server-side
                    minHeight: 5,
                    backgroundColor: Colors.grey.shade200,
                    valueColor: const AlwaysStoppedAnimation(Color(0xFF6366F1)),
                  ),
                )),
                const SizedBox(width: 8),
                Text(card.subjectName ?? '', style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
              ]),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Today's (featured) articles ─────────────────────────────────────────────
class _TodaysArticles extends ConsumerWidget {
  const _TodaysArticles();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(articleListProvider(const ArticleQuery(featured: true)));
    return async.maybeWhen(
      data: (items) => items.isEmpty
          ? const SizedBox.shrink()
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  const _SectionTitle("Today's Articles"),
                  TextButton(onPressed: () => context.go('/learn'), child: const Text('See all')),
                ]),
                const SizedBox(height: 6),
                SizedBox(
                  height: 200,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: items.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 12),
                    itemBuilder: (_, i) => _ArticlePreview(card: items[i]),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
      orElse: () => const SizedBox.shrink(),
    );
  }
}

class _ArticlePreview extends StatelessWidget {
  final ArticleCard card;
  const _ArticlePreview({required this.card});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 250,
      child: Card(
        elevation: 0,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: Theme.of(context).dividerColor.withValues(alpha: .5))),
        child: InkWell(
          onTap: () => context.push('/learn/article/${card.slug}'),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: card.heroImage != null
                    ? Image.network(card.heroImage!, width: double.infinity, fit: BoxFit.cover, errorBuilder: (_, _, _) => _grad(context))
                    : _grad(context),
              ),
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(card.title, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5, height: 1.25)),
                    const SizedBox(height: 4),
                    Text('${card.subjectName ?? ''}${card.readingTime != null ? ' · ${card.readingTime} min' : ''}', style: TextStyle(fontSize: 11.5, color: Colors.grey.shade600)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _grad(BuildContext context) => Container(
    decoration: BoxDecoration(gradient: LinearGradient(colors: [Theme.of(context).colorScheme.primary, Theme.of(context).colorScheme.secondary])),
    child: const Center(child: Icon(Icons.article, color: Colors.white54, size: 36)),
  );
}

// ── Quick actions ───────────────────────────────────────────────────────────
class _QuickActions extends StatelessWidget {
  final Set<String> mods;
  const _QuickActions({required this.mods});

  @override
  Widget build(BuildContext context) {
    final actions = <({IconData icon, String label, Color color, VoidCallback onTap})>[
      if (mods.contains('study_material')) (icon: Icons.menu_book, label: 'Learn', color: const Color(0xFF4F46E5), onTap: () => context.go('/learn')),
      if (mods.contains('exam')) (icon: Icons.edit_note, label: 'Practice', color: const Color(0xFF7C3AED), onTap: () => context.go('/practice')),
      (icon: Icons.history_edu, label: 'PYQs', color: const Color(0xFFEF4444), onTap: () => context.push('/pyqs')),
      (icon: Icons.bookmark, label: 'Saved', color: const Color(0xFF10B981), onTap: () => context.push('/learn/saved')),
    ];
    return Row(
      children: [
        for (var i = 0; i < actions.length; i++) ...[
          if (i > 0) const SizedBox(width: 12),
          _QuickAction(icon: actions[i].icon, label: actions[i].label, color: actions[i].color, onTap: actions[i].onTap),
        ],
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);
  @override
  Widget build(BuildContext context) => Text(text, style: const TextStyle(fontFamily: 'Poppins', fontSize: 18, fontWeight: FontWeight.w700));
}

// ── Preserved widgets ───────────────────────────────────────────────────────
class _SubscribedBanner extends StatelessWidget {
  final String? expiryDate;
  const _SubscribedBanner({this.expiryDate});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    decoration: BoxDecoration(color: const Color(0xFFECFDF5), borderRadius: BorderRadius.circular(14), border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.3))),
    child: Row(children: [
      const Icon(Icons.verified, color: Color(0xFF10B981)),
      const SizedBox(width: 10),
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Premium Active', style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600, color: Color(0xFF065F46))),
        if (expiryDate != null) Text('Valid until $expiryDate', style: const TextStyle(fontFamily: 'Poppins', fontSize: 11, color: Color(0xFF34D399))),
      ]),
    ]),
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
      decoration: BoxDecoration(color: const Color(0xFFFEF3C7), borderRadius: BorderRadius.circular(14), border: Border.all(color: const Color(0xFFF59E0B).withValues(alpha: 0.4))),
      child: Row(children: [
        const Icon(Icons.play_circle_fill, color: Color(0xFFD97706), size: 30),
        const SizedBox(width: 12),
        const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Resume your exam', style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700, color: Color(0xFF92400E))),
          Text('You have an attempt in progress. Tap to continue.', style: TextStyle(fontFamily: 'Poppins', fontSize: 12, color: Color(0xFFB45309))),
        ])),
        const Icon(Icons.arrow_forward_ios, size: 14, color: Color(0xFFD97706)),
      ]),
    ),
  );
}

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _QuickAction({required this.icon, required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) => Expanded(
    child: GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(color: color.withValues(alpha: .10), borderRadius: BorderRadius.circular(14)),
        child: Column(children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 6),
          Text(label, style: TextStyle(fontFamily: 'Poppins', fontSize: 11, fontWeight: FontWeight.w600, color: color)),
        ]),
      ),
    ),
  );
}
