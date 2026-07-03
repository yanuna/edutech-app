import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../providers/book_provider.dart';

/// Books reference library — NCERT / ARC / Economic Survey / reports, filterable
/// by category. Tapping opens the PDF in the device's viewer.
class BooksScreen extends ConsumerStatefulWidget {
  const BooksScreen({super.key});

  @override
  ConsumerState<BooksScreen> createState() => _BooksScreenState();
}

class _BooksScreenState extends ConsumerState<BooksScreen> {
  String? _category;

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(booksProvider(_category));

    return Scaffold(
      appBar: AppBar(title: const Text('Books')),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => _Message(icon: Icons.wifi_off_rounded, title: 'Could not load books', subtitle: 'Try again.', onRetry: () => ref.invalidate(booksProvider(_category))),
        data: (data) => Column(
          children: [
            SizedBox(
              height: 52,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                children: [
                  Padding(padding: const EdgeInsets.only(right: 8), child: ChoiceChip(label: const Text('All'), selected: _category == null, onSelected: (_) => setState(() => _category = null))),
                  for (final c in data.categories)
                    Padding(padding: const EdgeInsets.only(right: 8), child: ChoiceChip(label: Text(c.label), selected: _category == c.key, onSelected: (_) => setState(() => _category = c.key))),
                ],
              ),
            ),
            Expanded(
              child: data.books.isEmpty
                  ? const _Message(icon: Icons.menu_book_outlined, title: 'No books yet', subtitle: 'Reference books will appear here once added.')
                  : RefreshIndicator(
                      onRefresh: () async => ref.invalidate(booksProvider(_category)),
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: data.books.length,
                        itemBuilder: (_, i) => _BookCard(book: data.books[i]),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BookCard extends StatelessWidget {
  final BookItem book;
  const _BookCard({required this.book});

  Future<void> _open(BuildContext context) async {
    final url = book.fileUrl;
    if (url == null) return;
    final uri = Uri.tryParse(url);
    if (uri == null || !await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not open the PDF')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14), side: BorderSide(color: Theme.of(context).dividerColor.withValues(alpha: .5))),
      child: InkWell(
        onTap: () => _open(context),
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: book.coverUrl != null
                    ? Image.network(book.coverUrl!, width: 52, height: 70, fit: BoxFit.cover, errorBuilder: (_, _, _) => _placeholder())
                    : _placeholder(),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(book.title, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14.5)),
                    if (book.author != null && book.author!.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(book.author!, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                    ],
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(color: const Color(0xFF6366F1).withValues(alpha: .12), borderRadius: BorderRadius.circular(999)),
                      child: Text(book.categoryLabel, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF4F46E5))),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.picture_as_pdf_outlined, color: Color(0xFFEF4444)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _placeholder() => Container(
    width: 52, height: 70,
    color: const Color(0xFF6366F1).withValues(alpha: .12),
    child: const Icon(Icons.menu_book_rounded, color: Color(0xFF6366F1)),
  );
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
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 46, color: Colors.grey.shade400),
          const SizedBox(height: 14),
          Text(title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          Text(subtitle, textAlign: TextAlign.center, style: TextStyle(color: Colors.grey.shade600)),
          if (onRetry != null) ...[const SizedBox(height: 16), FilledButton.tonal(onPressed: onRetry, child: const Text('Retry'))],
        ]),
      ),
    );
  }
}
