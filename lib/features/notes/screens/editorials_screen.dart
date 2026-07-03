import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/notes_editorial_provider.dart';
import '../../learn/screens/articles_list_screen.dart' show ArticleCardTile;

/// Editorial Analysis — editorials from The Hindu / Indian Express / PIB / etc.,
/// filterable by source. Each opens in the premium article reader (summary,
/// keywords, prelims/mains points live in the article body blocks).
class EditorialsScreen extends ConsumerStatefulWidget {
  const EditorialsScreen({super.key});

  @override
  ConsumerState<EditorialsScreen> createState() => _EditorialsScreenState();
}

class _EditorialsScreenState extends ConsumerState<EditorialsScreen> {
  String? _source;

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(editorialsProvider(_source));

    return Scaffold(
      appBar: AppBar(title: const Text('Editorial Analysis')),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => _Message(icon: Icons.wifi_off_rounded, title: 'Could not load editorials', subtitle: 'Try again.', onRetry: () => ref.invalidate(editorialsProvider(_source))),
        data: (data) => Column(
          children: [
            if (data.sources.isNotEmpty)
              SizedBox(
                height: 52,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(label: const Text('All'), selected: _source == null, onSelected: (_) => setState(() => _source = null)),
                    ),
                    for (final s in data.sources)
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(label: Text(s), selected: _source == s, onSelected: (_) => setState(() => _source = s)),
                      ),
                  ],
                ),
              ),
            Expanded(
              child: data.editorials.isEmpty
                  ? const _Message(icon: Icons.menu_book_outlined, title: 'No editorials yet', subtitle: 'Editorial analyses will appear here once published.')
                  : RefreshIndicator(
                      onRefresh: () async => ref.invalidate(editorialsProvider(_source)),
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: data.editorials.length,
                        itemBuilder: (_, i) => ArticleCardTile(card: data.editorials[i]),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
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
