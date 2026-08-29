import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/widgets/rich_content_view.dart';
import '../providers/review_provider.dart';

/// A read-only review of a bank of MCQs (wrong answers or bookmarked), each
/// showing the correct option and its explanation. `mode` selects the source.
class QuestionReviewScreen extends ConsumerWidget {
  final String mode; // 'wrong' | 'bookmarked'
  const QuestionReviewScreen({super.key, required this.mode});

  bool get _wrong => mode == 'wrong';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final provider = _wrong ? wrongQuestionsProvider : bookmarkedQuestionsProvider;
    final async = ref.watch(provider);

    return Scaffold(
      appBar: AppBar(title: Text(_wrong ? 'Wrong Questions' : 'Bookmarked MCQs')),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => _Message(
          icon: Icons.wifi_off_rounded,
          title: 'Could not load',
          subtitle: 'Check your connection and try again.',
          onRetry: () => ref.invalidate(provider),
        ),
        data: (questions) => questions.isEmpty
            ? _Message(
                icon: _wrong ? Icons.check_circle_outline : Icons.bookmark_border_rounded,
                title: _wrong ? 'No wrong answers' : 'No bookmarked MCQs',
                subtitle: _wrong
                    ? 'Questions you answer incorrectly in tests will collect here for revision.'
                    : 'Bookmark questions during a test to revise them here.',
              )
            : RefreshIndicator(
                onRefresh: () async => ref.invalidate(provider),
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: questions.length,
                  itemBuilder: (_, i) => _ReviewCard(index: i + 1, q: questions[i]),
                ),
              ),
      ),
    );
  }
}

class _ReviewCard extends StatelessWidget {
  final int index;
  final ReviewQuestion q;
  const _ReviewCard({required this.index, required this.q});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).dividerColor.withValues(alpha: .5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Q$index. ', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
            Expanded(child: RichContentView(html: q.question, fontSize: 15)),
          ]),
          const SizedBox(height: 12),
          for (var i = 0; i < q.options.length; i++) _option(i + 1, q.options[i]),
          if (q.explanation != null && q.explanation!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: const Color(0xFF6366F1).withValues(alpha: .07), borderRadius: BorderRadius.circular(10), border: const Border(
                left: BorderSide(color: Color(0xFF6366F1), width: 3),
              )),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Explanation', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5, color: Color(0xFF4F46E5))),
                const SizedBox(height: 4),
                RichContentView(html: q.explanation!, fontSize: 14),
              ]),
            ),
          ],
        ],
      ),
    );
  }

  Widget _option(int number, String text) {
    final correct = number == q.correctOption;
    final color = correct ? const Color(0xFF10B981) : Colors.grey;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: correct ? const Color(0xFF10B981).withValues(alpha: .10) : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: correct ? .5 : .25)),
      ),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(correct ? Icons.check_circle : Icons.circle_outlined, size: 18, color: color),
        const SizedBox(width: 10),
        Expanded(child: RichContentView(html: text, fontSize: 14)),
      ]),
    );
  }
}

class _Message extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onRetry;
  const _Message({required this.icon, required this.title, required this.subtitle, this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 46, color: Colors.grey.shade400),
            const SizedBox(height: 14),
            Text(title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            Text(subtitle, textAlign: TextAlign.center, style: TextStyle(color: Colors.grey.shade600)),
            if (onRetry != null) ...[
              const SizedBox(height: 16),
              FilledButton.tonal(onPressed: onRetry, child: const Text('Retry')),
            ],
          ],
        ),
      ),
    );
  }
}
