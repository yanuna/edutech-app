import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/providers/branding_provider.dart';
import '../../../core/providers/faq_provider.dart';

/// Help & Support — contact options (email / WhatsApp) from admin branding plus
/// an admin-managed FAQ list, and privacy/terms links.
class HelpScreen extends ConsumerWidget {
  const HelpScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final b = ref.watch(brandingProvider);
    final faqs = ref.watch(faqsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Help & Support')),
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(faqsProvider),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (b.hasSupport) ...[
              const _Heading('Contact us'),
              if (b.supportEmail.isNotEmpty)
                _ContactTile(
                  icon: Icons.email_outlined,
                  label: 'Email support',
                  value: b.supportEmail,
                  onTap: () => _launch('mailto:${b.supportEmail}'),
                ),
              if (b.supportWhatsapp.isNotEmpty)
                _ContactTile(
                  icon: Icons.chat_outlined,
                  label: 'WhatsApp',
                  value: b.supportWhatsapp,
                  onTap: () => _launch('https://wa.me/${b.supportWhatsapp.replaceAll(RegExp(r'[^0-9]'), '')}'),
                ),
              const SizedBox(height: 20),
            ],
            const _Heading('Frequently asked questions'),
            faqs.when(
              loading: () => const Padding(padding: EdgeInsets.all(24), child: Center(child: CircularProgressIndicator())),
              error: (_, _) => Padding(
                padding: const EdgeInsets.all(16),
                child: Text('Could not load FAQs.', style: TextStyle(color: Colors.grey.shade600)),
              ),
              data: (list) => list.isEmpty
                  ? Padding(padding: const EdgeInsets.all(16), child: Text('No FAQs yet.', style: TextStyle(color: Colors.grey.shade600)))
                  : Column(
                      children: [
                        for (final f in list)
                          Card(
                            elevation: 0,
                            margin: const EdgeInsets.only(bottom: 8),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Theme.of(context).dividerColor.withValues(alpha: .5))),
                            child: ExpansionTile(
                              shape: const Border(),
                              title: Text(f.question, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14.5)),
                              childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                              expandedCrossAxisAlignment: CrossAxisAlignment.start,
                              children: [Text(f.answer, style: TextStyle(color: Colors.grey.shade700, height: 1.4))],
                            ),
                          ),
                      ],
                    ),
            ),
            const SizedBox(height: 16),
            if (b.privacyUrl.isNotEmpty)
              TextButton(onPressed: () => _launch(b.privacyUrl), child: const Text('Privacy Policy')),
            if (b.termsUrl.isNotEmpty)
              TextButton(onPressed: () => _launch(b.termsUrl), child: const Text('Terms of Service')),
          ],
        ),
      ),
    );
  }

  Future<void> _launch(String url) async {
    final uri = Uri.tryParse(url);
    if (uri != null) await launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}

class _Heading extends StatelessWidget {
  final String text;
  const _Heading(this.text);
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(left: 4, bottom: 10, top: 4),
        child: Text(text, style: const TextStyle(fontFamily: 'Poppins', fontSize: 16, fontWeight: FontWeight.w700)),
      );
}

class _ContactTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final VoidCallback onTap;
  const _ContactTile({required this.icon, required this.label, required this.value, required this.onTap});

  @override
  Widget build(BuildContext context) => Card(
        elevation: 0,
        margin: const EdgeInsets.only(bottom: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Theme.of(context).dividerColor.withValues(alpha: .5))),
        child: ListTile(
          leading: Icon(icon, color: const Color(0xFF4F46E5)),
          title: Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
          subtitle: Text(value),
          trailing: const Icon(Icons.open_in_new, size: 18),
          onTap: onTap,
        ),
      );
}
