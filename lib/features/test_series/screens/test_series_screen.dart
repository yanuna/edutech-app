import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/providers/subscription_provider.dart';
import '../../../core/providers/test_series_provider.dart';
import '../../../shared/widgets/app_widgets.dart';
import '../widgets/test_series_card.dart';
import '../../../core/api/api_client.dart';

class TestSeriesScreen extends ConsumerWidget {
  const TestSeriesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Test Series is a premium feature — gate it behind an active subscription.
    // The backend also enforces this on /test-series/{exam}/start (403); this
    // just gives non-subscribers a paywall instead of a list they can't use.
    final subStatus = ref.watch(subscriptionStatusProvider);
    final isLocked = subStatus.whenOrNull(data: (s) => !s.hasAccess) ?? false;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Test Series'),
          actions: [
            IconButton(
              tooltip: 'My attempts',
              icon: const Icon(Icons.history),
              onPressed: () => context.push('/exam/test-series/history'),
            ),
          ],
          bottom: isLocked
              ? null
              : const TabBar(
                  labelStyle: TextStyle(
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w600,
                  ),
                  tabs: [
                    Tab(text: 'Part Tests'),
                    Tab(text: 'Full Tests'),
                  ],
                ),
        ),
        body: isLocked
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: PaywallWidget(
                    onSubscribe: () => context.push('/profile/plans'),
                  ),
                ),
              )
            : const TabBarView(
                children: [
                  _ExamGrid(type: 'part'),
                  _ExamGrid(type: 'full'),
                ],
              ),
      ),
    );
  }
}

class _ExamGrid extends ConsumerWidget {
  final String type;
  const _ExamGrid({required this.type});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final exams = ref.watch(testSeriesListProvider(type));

    return exams.when(
      data: (list) => list.isEmpty
          ? _Empty(type: type)
          : RefreshIndicator(
              onRefresh: () => ref.refresh(testSeriesListProvider(type).future),
              child: GridView.builder(
                padding: const EdgeInsets.all(16),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 14,
                  crossAxisSpacing: 14,
                  // Absolute cell height so the tallest card variant (completed
                  // attempt with a "Your marks" line) fits regardless of screen
                  // width — a fixed aspect ratio overflowed on narrower phones.
                  mainAxisExtent: 294,
                ),
                itemCount: list.length,
                itemBuilder: (_, i) => TestSeriesCard(exam: list[i]),
              ),
            ),
      loading: () => GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 14,
          crossAxisSpacing: 14,
          childAspectRatio: 0.74,
        ),
        itemCount: 4,
        itemBuilder: (_, _) => const ShimmerCard(height: 220),
      ),
      error: (e, _) => ErrorRetryWidget(
        message: apiErrorMessage(e),
        onRetry: () => ref.invalidate(testSeriesListProvider(type)),
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  final String type;
  const _Empty({required this.type});

  @override
  Widget build(BuildContext context) => ListView(
    children: [
      const SizedBox(height: 120),
      Icon(
        Icons.fact_check_outlined,
        size: 64,
        color: const Color(0xFF4F46E5).withValues(alpha: 0.6),
      ),
      const SizedBox(height: 16),
      Center(
        child: Text(
          'No ${type == 'part' ? 'Part' : 'Full'} Tests yet',
          style: const TextStyle(
            fontFamily: 'Poppins',
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      const SizedBox(height: 8),
      const Center(
        child: Text(
          'Check back soon — new tests are added regularly.',
          style: TextStyle(fontFamily: 'Poppins', color: Colors.black54),
        ),
      ),
    ],
  );
}
