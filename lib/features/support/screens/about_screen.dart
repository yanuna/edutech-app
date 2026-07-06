import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/providers/branding_provider.dart';

/// About — app identity (name, tagline, admin-authored blurb) and legal links,
/// all driven by admin branding settings.
class AboutScreen extends ConsumerWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final b = ref.watch(brandingProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('About')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const SizedBox(height: 12),
          Center(
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(gradient: LinearGradient(colors: [b.primaryColor, b.secondaryColor]), borderRadius: BorderRadius.circular(24)),
              child: const Icon(Icons.school_rounded, color: Colors.white, size: 56),
            ),
          ),
          const SizedBox(height: 16),
          Center(child: Text(b.appName, style: const TextStyle(fontFamily: 'Poppins', fontSize: 22, fontWeight: FontWeight.w800))),
          const SizedBox(height: 4),
          Center(child: Text(b.tagline, style: TextStyle(color: Colors.grey.shade600))),
          const SizedBox(height: 24),
          if (b.aboutText.isNotEmpty) ...[
            Text(b.aboutText, style: const TextStyle(fontSize: 14.5, height: 1.6)),
            const SizedBox(height: 24),
          ],
          const Divider(),
          if (b.privacyUrl.isNotEmpty)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.privacy_tip_outlined),
              title: const Text('Privacy Policy'),
              trailing: const Icon(Icons.open_in_new, size: 18),
              onTap: () => _launch(b.privacyUrl),
            ),
          if (b.termsUrl.isNotEmpty)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.description_outlined),
              title: const Text('Terms of Service'),
              trailing: const Icon(Icons.open_in_new, size: 18),
              onTap: () => _launch(b.termsUrl),
            ),
          if (b.supportEmail.isNotEmpty)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.email_outlined),
              title: const Text('Contact support'),
              subtitle: Text(b.supportEmail),
              onTap: () => _launch('mailto:${b.supportEmail}'),
            ),
          const SizedBox(height: 24),
          Center(child: Text('Version 1.0.0', style: TextStyle(color: Colors.grey.shade500, fontSize: 12.5))),
          const SizedBox(height: 8),
          Center(child: Text('© ${DateTime.now().year} ${b.appName}', style: TextStyle(color: Colors.grey.shade500, fontSize: 12.5))),
        ],
      ),
    );
  }

  Future<void> _launch(String url) async {
    final uri = Uri.tryParse(url);
    if (uri != null) await launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}
