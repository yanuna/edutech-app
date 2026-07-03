import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/notes_editorial_provider.dart';
import '../../learn/screens/articles_list_screen.dart' show ArticleCardTile;

/// Notes browse — short / revision / one-page / cheat-sheet / mind-map notes,
/// filterable by format. Each opens in the premium article reader.
class NotesScreen extends ConsumerStatefulWidget {
  const NotesScreen({super.key});

  @override
  ConsumerState<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends ConsumerState<NotesScreen> {
  String? _format;
  static const _formats = [
    (null, 'All'),
    ('short', 'Short'),
    ('revision', 'Revision'),
    ('one_page', 'One-page'),
    ('cheat_sheet', 'Cheat Sheet'),
    ('mind_map', 'Mind Map'),
  ];

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(notesProvider(_format));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notes'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(52),
          child: SizedBox(
            height: 52,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: [
                for (final f in _formats)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(f.$2),
                      selected: _format == f.$1,
                      onSelected: (_) => setState(() => _format = f.$1),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => _Message(icon: Icons.wifi_off_rounded, title: 'Could not load notes', subtitle: 'Try again.', onRetry: () => ref.invalidate(notesProvider(_format))),
        data: (notes) => notes.isEmpty
            ? const _Message(icon: Icons.sticky_note_2_outlined, title: 'No notes yet', subtitle: 'Notes will appear here once published.')
            : RefreshIndicator(
                onRefresh: () async => ref.invalidate(notesProvider(_format)),
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: notes.length,
                  itemBuilder: (_, i) => ArticleCardTile(card: notes[i]),
                ),
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
