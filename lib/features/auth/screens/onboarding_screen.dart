import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/services/startup_service.dart';

class _Page {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final String? imageUrl;
  const _Page(this.title, this.subtitle, this.icon, this.color, {this.imageUrl});
}

/// Built-in slides used when the admin hasn't configured any.
const _fallbackPages = [
  _Page('Study Smarter', 'Access video lessons, notes and PDFs organized by subject and chapter — all in one place.', Icons.play_circle_outline, Color(0xFF4F46E5)),
  _Page('Practice Exams', 'Take unlimited practice tests with shuffled questions, negative marking and instant analytics.', Icons.quiz_outlined, Color(0xFF7C3AED)),
  _Page('Track Progress', 'Detailed subject-wise breakdowns and history to know exactly where you stand.', Icons.bar_chart, Color(0xFF0EA5E9)),
];

IconData _iconFor(String? name) => switch (name) {
      'play_circle' => Icons.play_circle_outline,
      'quiz' => Icons.quiz_outlined,
      'bar_chart' => Icons.bar_chart,
      'menu_book' => Icons.menu_book,
      'bolt' => Icons.bolt,
      'emoji_events' => Icons.emoji_events_outlined,
      'rocket_launch' => Icons.rocket_launch_outlined,
      _ => Icons.auto_awesome,
    };

Color _colorFor(String? hex) {
  if (hex == null || hex.isEmpty) return const Color(0xFF4F46E5);
  final v = hex.replaceFirst('#', '');
  final parsed = int.tryParse(v.length == 6 ? 'FF$v' : v, radix: 16);
  return parsed == null ? const Color(0xFF4F46E5) : Color(parsed);
}

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  int _current = 0;
  final _controller = PageController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final slides = ref.watch(onboardingSlidesProvider);
    final pages = slides.isEmpty
        ? _fallbackPages
        : slides
            .map((s) => _Page(s.title, s.subtitle, _iconFor(s.icon), _colorFor(s.color), imageUrl: s.imageUrl))
            .toList();

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: _controller,
                onPageChanged: (i) => setState(() => _current = i),
                itemCount: pages.length,
                itemBuilder: (_, i) {
                  final p = pages[i];
                  return Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: p.imageUrl != null ? EdgeInsets.zero : const EdgeInsets.all(32),
                          decoration: BoxDecoration(
                            color: p.imageUrl != null ? null : p.color.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(40),
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: p.imageUrl != null
                              ? Image.network(p.imageUrl!, width: 200, height: 200, fit: BoxFit.cover,
                                  errorBuilder: (_, _, _) => Icon(p.icon, size: 96, color: p.color))
                              : Icon(p.icon, size: 96, color: p.color),
                        ),
                        const SizedBox(height: 40),
                        Text(
                          p.title,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 26,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          p.subtitle,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 15,
                            color: Colors.black54,
                            height: 1.6,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                pages.length,
                (i) => AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: _current == i ? 20 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: _current == i
                        ? const Color(0xFF4F46E5)
                        : Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 32),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () {
                        if (_current < pages.length - 1) {
                          _controller.nextPage(
                            duration: const Duration(milliseconds: 350),
                            curve: Curves.easeInOut,
                          );
                        } else {
                          context.go('/register');
                        }
                      },
                      child: Text(
                        _current == pages.length - 1 ? 'Get Started' : 'Next',
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: () => context.go('/login'),
                    child: const Text(
                      'Already have an account? Sign In',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        color: Color(0xFF4F46E5),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
