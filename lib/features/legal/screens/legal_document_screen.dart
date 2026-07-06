import 'package:flutter/material.dart';

import '../legal_content.dart';

/// Renders a single legal document (privacy / terms / refund / pricing /
/// contact) in a scrollable, well-typeset page.
class LegalDocumentScreen extends StatelessWidget {
  final String slug;
  const LegalDocumentScreen({super.key, required this.slug});

  @override
  Widget build(BuildContext context) {
    final doc = legalDocBySlug(slug);

    if (doc == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Legal')),
        body: const Center(child: Text('Document not found.')),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(doc.title)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
        children: [
          Text(doc.title, style: const TextStyle(fontFamily: 'Poppins', fontSize: 22, fontWeight: FontWeight.w800, height: 1.2)),
          const SizedBox(height: 6),
          Text(doc.subtitle, style: TextStyle(color: Colors.grey.shade600, fontSize: 13.5)),
          const SizedBox(height: 20),
          for (final s in doc.sections) ..._section(context, s),
        ],
      ),
    );
  }

  List<Widget> _section(BuildContext context, LegalSection s) {
    return [
      if (s.heading != null) ...[
        const SizedBox(height: 10),
        Text(s.heading!, style: const TextStyle(fontFamily: 'Poppins', fontSize: 16, fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
      ],
      for (final p in s.paragraphs)
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Text(p, style: const TextStyle(fontSize: 14, height: 1.55)),
        ),
      for (final b in s.bullets)
        Padding(
          padding: const EdgeInsets.only(bottom: 8, left: 2),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 7, right: 10),
                child: Container(width: 5, height: 5, decoration: BoxDecoration(color: Theme.of(context).colorScheme.primary, shape: BoxShape.circle)),
              ),
              Expanded(child: Text(b, style: const TextStyle(fontSize: 14, height: 1.5))),
            ],
          ),
        ),
      const SizedBox(height: 6),
    ];
  }
}
