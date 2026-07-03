import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../shared/widgets/rich_content_view.dart';
import '../../practice/providers/review_provider.dart';

/// Flashcards built from the user's bookmarked MCQs: front shows the question,
/// tap to flip and reveal the correct answer + explanation; swipe for the next.
class FlashcardsScreen extends ConsumerWidget {
  const FlashcardsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(bookmarkedQuestionsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Flashcards')),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Text('Could not load flashcards'),
            const SizedBox(height: 12),
            FilledButton.tonal(onPressed: () => ref.invalidate(bookmarkedQuestionsProvider), child: const Text('Retry')),
          ]),
        ),
        data: (cards) => cards.isEmpty ? const _Empty() : _Deck(cards: cards),
      ),
    );
  }
}

class _Deck extends StatefulWidget {
  final List<ReviewQuestion> cards;
  const _Deck({required this.cards});

  @override
  State<_Deck> createState() => _DeckState();
}

class _DeckState extends State<_Deck> {
  final _pageController = PageController();
  int _index = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
          child: Row(children: [
            Text('Card ${_index + 1} of ${widget.cards.length}', style: TextStyle(fontWeight: FontWeight.w600, color: Colors.grey.shade700)),
            const Spacer(),
            const Text('Tap card to flip', style: TextStyle(fontSize: 12, color: Colors.grey)),
          ]),
        ),
        Expanded(
          child: PageView.builder(
            controller: _pageController,
            itemCount: widget.cards.length,
            onPageChanged: (i) => setState(() => _index = i),
            itemBuilder: (_, i) => Padding(
              padding: const EdgeInsets.all(20),
              child: _FlipCard(key: ValueKey(widget.cards[i].id), card: widget.cards[i]),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TextButton.icon(
                onPressed: _index == 0 ? null : () => _pageController.previousPage(duration: const Duration(milliseconds: 300), curve: Curves.easeOut),
                icon: const Icon(Icons.chevron_left_rounded),
                label: const Text('Prev'),
              ),
              TextButton.icon(
                onPressed: _index == widget.cards.length - 1 ? null : () => _pageController.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeOut),
                icon: const Icon(Icons.chevron_right_rounded),
                label: const Text('Next'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _FlipCard extends StatefulWidget {
  final ReviewQuestion card;
  const _FlipCard({super.key, required this.card});

  @override
  State<_FlipCard> createState() => _FlipCardState();
}

class _FlipCardState extends State<_FlipCard> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 400));
  bool _showBack = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _flip() {
    _showBack = !_showBack;
    _showBack ? _controller.forward() : _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _flip,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          final angle = _controller.value * math.pi;
          final isBack = angle > math.pi / 2;
          return Transform(
            alignment: Alignment.center,
            transform: Matrix4.identity()..setEntry(3, 2, 0.001)..rotateY(angle),
            child: isBack
                ? Transform(alignment: Alignment.center, transform: Matrix4.identity()..rotateY(math.pi), child: _back())
                : _front(),
          );
        },
      ),
    );
  }

  Widget _shell({required Widget child, required Color bg, required Color border}) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20), border: Border.all(color: border)),
    child: Center(child: SingleChildScrollView(child: child)),
  );

  Widget _front() => _shell(
    bg: Colors.white,
    border: Theme.of(context).dividerColor.withValues(alpha: .5),
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      const Icon(Icons.help_outline_rounded, color: Color(0xFF6366F1), size: 30),
      const SizedBox(height: 16),
      RichContentView(html: widget.card.question, fontSize: 16),
      const SizedBox(height: 20),
      Text('Tap to reveal answer', style: TextStyle(fontSize: 12.5, color: Colors.grey.shade500)),
    ]),
  );

  Widget _back() {
    final c = widget.card;
    final answer = (c.correctOption >= 1 && c.correctOption <= c.options.length) ? c.options[c.correctOption - 1] : '';
    return _shell(
      bg: const Color(0xFFF0FDF4),
      border: const Color(0xFF10B981).withValues(alpha: .4),
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: const [Icon(Icons.check_circle, color: Color(0xFF10B981)), SizedBox(width: 8), Text('Answer', style: TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF065F46)))]),
        const SizedBox(height: 10),
        RichContentView(html: answer, fontSize: 15.5),
        if (c.explanation != null && c.explanation!.isNotEmpty) ...[
          const SizedBox(height: 16),
          Text('Explanation', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5, color: Colors.grey.shade700)),
          const SizedBox(height: 4),
          RichContentView(html: c.explanation!, fontSize: 14),
        ],
      ]),
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty();
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.style_outlined, size: 46, color: Colors.grey.shade400),
          const SizedBox(height: 14),
          const Text('No flashcards yet', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          Text('Bookmark MCQs during a test to build your flashcard deck.', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey.shade600)),
          const SizedBox(height: 16),
          FilledButton.tonal(onPressed: () => context.go('/practice'), child: const Text('Go to Practice')),
        ]),
      ),
    );
  }
}
