import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';

import '../../../core/providers/legal_provider.dart';

/// Renders a single admin-managed legal page (fetched by slug) as HTML in a
/// scrollable, well-typeset page.
class LegalDocumentScreen extends ConsumerWidget {
  final String slug;
  const LegalDocumentScreen({super.key, required this.slug});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final page = ref.watch(legalPageProvider(slug));

    return Scaffold(
      appBar: AppBar(title: Text(page.valueOrNull?.title ?? 'Legal')),
      body: page.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.wifi_off_rounded, size: 44, color: Colors.grey.shade400),
            const SizedBox(height: 12),
            Text('Could not load this page', style: TextStyle(color: Colors.grey.shade600)),
            const SizedBox(height: 12),
            FilledButton.tonal(onPressed: () => ref.invalidate(legalPageProvider(slug)), child: const Text('Retry')),
          ]),
        ),
        data: (doc) => ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
          children: [
            Text(doc.title, style: const TextStyle(fontFamily: 'Poppins', fontSize: 22, fontWeight: FontWeight.w800, height: 1.2)),
            if (doc.subtitle != null && doc.subtitle!.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(doc.subtitle!, style: TextStyle(color: Colors.grey.shade600, fontSize: 13.5)),
            ],
            if (doc.updatedAt != null) ...[
              const SizedBox(height: 4),
              Text('Last updated: ${doc.updatedAt!.day}/${doc.updatedAt!.month}/${doc.updatedAt!.year}',
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
            ],
            const SizedBox(height: 18),
            HtmlWidget(
              doc.bodyHtml,
              textStyle: const TextStyle(fontSize: 14, height: 1.55),
            ),
          ],
        ),
      ),
    );
  }
}
