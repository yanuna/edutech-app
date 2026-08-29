import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import '../../../core/providers/auth_provider.dart';

class ReferralScreen extends ConsumerWidget {
  const ReferralScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).user;
    final code = user?.referralCode ?? '...';

    return Scaffold(
      appBar: AppBar(title: const Text('Referral & Rewards')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF4F46E5), Color(0xFF7C3AED)],
                ),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                children: [
                  const Icon(
                    Icons.card_giftcard,
                    color: Colors.white,
                    size: 52,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Refer & Earn',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Share your code with friends. Both of you get free access when they subscribe!',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      color: Colors.white70,
                      fontSize: 13,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.4),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          code,
                          style: const TextStyle(
                            fontFamily: 'Poppins',
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 4,
                          ),
                        ),
                        const SizedBox(width: 14),
                        IconButton(
                          icon: const Icon(Icons.copy, color: Colors.white),
                          onPressed: () {
                            Clipboard.setData(ClipboardData(text: code));
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Referral code copied!'),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      // This used to call a LOCAL class named `Share`, defined
                      // at the bottom of this file, which only copied to the
                      // clipboard — so the referral loop's main growth action
                      // never opened the OS share sheet at all. share_plus is
                      // already a dependency and is used correctly elsewhere.
                      onPressed: () async {
                        try {
                          await SharePlus.instance.share(
                            ShareParams(
                              text:
                                  'Join EduTech and use my referral code $code '
                                  'to get started! Download now.',
                              subject: 'Join me on EduTech',
                            ),
                          );
                        } catch (_) {
                          await Clipboard.setData(
                            ClipboardData(text: 'Referral code: $code'),
                          );
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Referral code copied.'),
                            ),
                          );
                        }
                      },
                      icon: const Icon(Icons.share, color: Color(0xFF4F46E5)),
                      label: const Text(
                        'Share Code',
                        style: TextStyle(color: Color(0xFF4F46E5)),
                      ),
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            const _HowItWorks(),
          ],
        ),
      ),
    );
  }
}

class _HowItWorks extends StatelessWidget {
  const _HowItWorks();

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text(
        'How it works',
        style: TextStyle(
          fontFamily: 'Poppins',
          fontWeight: FontWeight.w700,
          fontSize: 18,
        ),
      ),
      const SizedBox(height: 16),
      ...[
        _Step(
          number: '1',
          title: 'Share your code',
          desc: 'Share your unique referral code with friends.',
        ),
        _Step(
          number: '2',
          title: 'Friend signs up',
          desc: 'Your friend registers using your referral code.',
        ),
        _Step(
          number: '3',
          title: 'Both get rewarded',
          desc: 'When your friend subscribes, both get extended access.',
        ),
      ],
    ],
  );
}

class _Step extends StatelessWidget {
  final String number;
  final String title;
  final String desc;
  const _Step({required this.number, required this.title, required this.desc});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(
          radius: 20,
          backgroundColor: const Color(0xFFEEF2FF),
          child: Text(
            number,
            style: const TextStyle(
              fontFamily: 'Poppins',
              color: Color(0xFF4F46E5),
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
              ),
              Text(
                desc,
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 13,
                  color: Colors.black54,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}
