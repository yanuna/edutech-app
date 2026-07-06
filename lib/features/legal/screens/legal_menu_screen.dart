import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/providers/branding_provider.dart';
import '../../../core/providers/legal_provider.dart';

/// "Legal & Policies" hub — lists the admin-managed policy documents and a quick
/// contact action. Reached from Profile.
class LegalMenuScreen extends ConsumerWidget {
  const LegalMenuScreen({super.key});

  static const _icons = {
    'privacy': Icons.privacy_tip_outlined,
    'terms': Icons.description_outlined,
    'refund': Icons.receipt_long_outlined,
    'pricing': Icons.sell_outlined,
    'contact': Icons.support_agent_outlined,
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final email = ref.watch(brandingProvider).supportEmail;
    final pages = ref.watch(legalPagesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Legal & Policies')),
      body: pages.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => _Retry(onRetry: () => ref.invalidate(legalPagesProvider)),
        data: (list) => RefreshIndicator(
          onRefresh: () async => ref.invalidate(legalPagesProvider),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              for (final p in list)
                Card(
                  elevation: 0,
                  margin: const EdgeInsets.only(bottom: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14), side: BorderSide(color: Theme.of(context).dividerColor.withValues(alpha: .5))),
                  child: ListTile(
                    leading: Icon(_icons[p.slug] ?? Icons.article_outlined, color: Theme.of(context).colorScheme.primary),
                    title: Text(p.title, style: const TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: (p.subtitle != null && p.subtitle!.isNotEmpty)
                        ? Text(p.subtitle!, maxLines: 2, overflow: TextOverflow.ellipsis)
                        : null,
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () => context.push('/legal/${p.slug}'),
                  ),
                ),
              if (email.isNotEmpty) ...[
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: () => launchUrl(Uri.parse('mailto:$email'), mode: LaunchMode.externalApplication),
                  icon: const Icon(Icons.email_outlined),
                  label: Text('Email support ($email)'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _Retry extends StatelessWidget {
  final VoidCallback onRetry;
  const _Retry({required this.onRetry});
  @override
  Widget build(BuildContext context) => Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.wifi_off_rounded, size: 44, color: Colors.grey.shade400),
          const SizedBox(height: 12),
          Text('Could not load policies', style: TextStyle(color: Colors.grey.shade600)),
          const SizedBox(height: 12),
          FilledButton.tonal(onPressed: onRetry, child: const Text('Retry')),
        ]),
      );
}
