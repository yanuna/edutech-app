import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/providers/branding_provider.dart';
import '../legal_content.dart';

/// "Legal & Policies" hub — lists all policy documents and a quick contact
/// action. Reached from Profile.
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

    return Scaffold(
      appBar: AppBar(title: const Text('Legal & Policies')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          for (final doc in kLegalDocs)
            Card(
              elevation: 0,
              margin: const EdgeInsets.only(bottom: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14), side: BorderSide(color: Theme.of(context).dividerColor.withValues(alpha: .5))),
              child: ListTile(
                leading: Icon(_icons[doc.slug] ?? Icons.article_outlined, color: Theme.of(context).colorScheme.primary),
                title: Text(doc.title, style: const TextStyle(fontWeight: FontWeight.w600)),
                subtitle: Text(doc.subtitle, maxLines: 2, overflow: TextOverflow.ellipsis),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () => context.push('/legal/${doc.slug}'),
              ),
            ),
          if (email.isNotEmpty) ...[
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: () async {
                final uri = Uri.parse('mailto:$email');
                await launchUrl(uri, mode: LaunchMode.externalApplication);
              },
              icon: const Icon(Icons.email_outlined),
              label: Text('Email support ($email)'),
            ),
          ],
        ],
      ),
    );
  }
}
