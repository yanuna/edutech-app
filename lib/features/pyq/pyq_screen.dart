import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/models/pyq.dart';
import '../../core/providers/pyq_provider.dart' show pyqIndexProvider, pyqOfflineProvider;

/// Previous Year Questions — pick a year, then browse Prelims / Mains / Optional
/// papers as cards. Tapping a paper/solution button opens the secure in-app
/// viewer (view-only, no download). FREE but requires login (enforced by the API).
class PyqScreen extends ConsumerStatefulWidget {
  const PyqScreen({super.key});

  @override
  ConsumerState<PyqScreen> createState() => _PyqScreenState();
}

class _PyqScreenState extends ConsumerState<PyqScreen> {
  int? _year; // null → latest year (resolved by the API)

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(pyqIndexProvider(_year));

    return Scaffold(
      appBar: AppBar(title: const Text('Previous Year Questions')),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => _Message(
          icon: Icons.wifi_off_rounded,
          title: 'Could not load papers',
          subtitle: 'Please check your connection and try again.',
          onRetry: () => ref.invalidate(pyqIndexProvider(_year)),
        ),
        data: (index) {
          if (index.years.isEmpty) {
            return const _Message(
              icon: Icons.folder_off_outlined,
              title: 'No papers yet',
              subtitle: 'Question papers will appear here once added.',
            );
          }
          final selected = _year ?? index.year;
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(pyqIndexProvider(_year)),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
              children: [
                _YearPicker(
                  years: index.years,
                  value: selected,
                  onChanged: (y) => setState(() => _year = y),
                ),
                const SizedBox(height: 20),
                if (index.papers.isEmpty)
                  _Message(
                    icon: Icons.folder_off_outlined,
                    title: 'No papers for $selected',
                    subtitle: 'Try another year from the dropdown above.',
                  )
                else ...[
                  if (index.prelims.isNotEmpty)
                    _Category(title: 'Prelims', papers: index.prelims),
                  if (index.mains.isNotEmpty)
                    _Category(title: 'Mains', papers: index.mains),
                  ..._optionalSections(index),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  List<Widget> _optionalSections(PyqIndex index) {
    final widgets = <Widget>[];
    index.optionalBySubject.forEach((subject, papers) {
      widgets.add(_Category(title: 'Optional · $subject', papers: papers));
    });
    return widgets;
  }
}

class _YearPicker extends StatelessWidget {
  final List<int> years;
  final int value;
  final ValueChanged<int> onChanged;
  const _YearPicker({required this.years, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: .4),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Theme.of(context).dividerColor.withValues(alpha: .4)),
      ),
      child: Row(
        children: [
          const Icon(Icons.event_note_outlined, size: 20),
          const SizedBox(width: 10),
          const Text('Select Year', style: TextStyle(fontWeight: FontWeight.w600)),
          const Spacer(),
          DropdownButton<int>(
            value: value,
            underline: const SizedBox.shrink(),
            borderRadius: BorderRadius.circular(12),
            items: years
                .map((y) => DropdownMenuItem(value: y, child: Text('$y')))
                .toList(),
            onChanged: (y) { if (y != null) onChanged(y); },
          ),
        ],
      ),
    );
  }
}

class _Category extends StatelessWidget {
  final String title;
  final List<PyqPaper> papers;
  const _Category({required this.title, required this.papers});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 8, bottom: 10),
          child: Row(
            children: [
              Text(title,
                  style: const TextStyle(
                      fontFamily: 'Poppins', fontSize: 17, fontWeight: FontWeight.w700)),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withValues(alpha: .12),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text('${papers.length}',
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Theme.of(context).colorScheme.primary)),
              ),
            ],
          ),
        ),
        ...papers.map((p) => _PaperCard(paper: p)),
        const SizedBox(height: 12),
      ],
    );
  }
}

class _PaperCard extends ConsumerStatefulWidget {
  final PyqPaper paper;
  const _PaperCard({required this.paper});

  @override
  ConsumerState<_PaperCard> createState() => _PaperCardState();
}

class _PaperCardState extends ConsumerState<_PaperCard> {
  PyqPaper get paper => widget.paper;

  @override
  void initState() {
    super.initState();
    // Reconcile the in-memory offline flags with what's actually on disk.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) ref.read(pyqOfflineProvider.notifier).refresh(paper);
    });
  }

  void _open(String slot) {
    final label = PyqSlot.labels[slot] ?? 'Document';
    final title = Uri.encodeComponent('${paper.title} · $label');
    context.push('/pyqs/view/${paper.id}/$slot?title=$title');
  }

  Future<void> _save() async {
    try {
      await ref.read(pyqOfflineProvider.notifier).save(paper);
      if (mounted) _toast('Saved for offline reading');
    } catch (_) {
      if (mounted) _toast('Could not save. Check your connection and try again.');
    }
  }

  Future<void> _remove() async {
    await ref.read(pyqOfflineProvider.notifier).remove(paper);
    if (mounted) _toast('Removed from offline');
  }

  void _toast(String msg) => ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating));

  @override
  Widget build(BuildContext context) {
    final offline = ref.watch(pyqOfflineProvider);
    final isSaved = offline.isOffline(paper);
    final isBusy = offline.isBusy(paper.id);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Theme.of(context).dividerColor.withValues(alpha: .5)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(paper.title,
                style: const TextStyle(fontSize: 15.5, fontWeight: FontWeight.w700)),
            const SizedBox(height: 2),
            Text('${paper.year} · ${paper.categoryLabel}',
                style: TextStyle(fontSize: 12.5, color: Colors.grey.shade600)),
            const SizedBox(height: 14),
            _SlotRow(
              label: 'Question Paper',
              icon: Icons.description_outlined,
              enBtn: paper.has(PyqSlot.questionPaperEn)
                  ? () => _open(PyqSlot.questionPaperEn) : null,
              hiBtn: paper.has(PyqSlot.questionPaperHi)
                  ? () => _open(PyqSlot.questionPaperHi) : null,
            ),
            const SizedBox(height: 10),
            _SlotRow(
              label: 'Solution',
              icon: Icons.check_circle_outline,
              solution: true,
              enBtn: paper.has(PyqSlot.solutionEn)
                  ? () => _open(PyqSlot.solutionEn) : null,
              hiBtn: paper.has(PyqSlot.solutionHi)
                  ? () => _open(PyqSlot.solutionHi) : null,
            ),
            if (paper.available.isNotEmpty) ...[
              const SizedBox(height: 12),
              Divider(height: 1, color: Theme.of(context).dividerColor.withValues(alpha: .4)),
              const SizedBox(height: 8),
              _OfflineFooter(
                isSaved: isSaved,
                isBusy: isBusy,
                onSave: _save,
                onRemove: _remove,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Bottom row of a paper card: a "Save offline" button, a "Saving…" spinner
/// while downloading, or an "Available offline" badge with a remove action.
class _OfflineFooter extends StatelessWidget {
  final bool isSaved;
  final bool isBusy;
  final VoidCallback onSave;
  final VoidCallback onRemove;
  const _OfflineFooter({
    required this.isSaved,
    required this.isBusy,
    required this.onSave,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    if (isBusy) {
      return Row(
        children: [
          const SizedBox(
            width: 16, height: 16,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          const SizedBox(width: 10),
          Text('Saving…',
              style: TextStyle(fontSize: 12.5, color: Colors.grey.shade600)),
        ],
      );
    }

    if (isSaved) {
      return Row(
        children: [
          Icon(Icons.offline_pin_rounded, size: 18, color: Colors.green.shade600),
          const SizedBox(width: 6),
          Text('Available offline',
              style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: Colors.green.shade700)),
          const Spacer(),
          TextButton(
            onPressed: onRemove,
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              minimumSize: const Size(0, 32),
              foregroundColor: Colors.grey.shade600,
            ),
            child: const Text('Remove', style: TextStyle(fontSize: 12.5)),
          ),
        ],
      );
    }

    return Align(
      alignment: Alignment.centerLeft,
      child: OutlinedButton.icon(
        onPressed: onSave,
        icon: const Icon(Icons.download_for_offline_outlined, size: 18),
        label: const Text('Save offline', style: TextStyle(fontSize: 12.5)),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          minimumSize: const Size(0, 34),
          visualDensity: VisualDensity.compact,
        ),
      ),
    );
  }
}

class _SlotRow extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool solution;
  final VoidCallback? enBtn;
  final VoidCallback? hiBtn;
  const _SlotRow({
    required this.label,
    required this.icon,
    this.solution = false,
    this.enBtn,
    this.hiBtn,
  });

  @override
  Widget build(BuildContext context) {
    final none = enBtn == null && hiBtn == null;
    return Row(
      children: [
        SizedBox(
          width: 118,
          child: Row(children: [
            Icon(icon, size: 16, color: solution ? Colors.teal : Theme.of(context).colorScheme.primary),
            const SizedBox(width: 6),
            Flexible(child: Text(label,
                style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600))),
          ]),
        ),
        const SizedBox(width: 8),
        if (none)
          Text('Not uploaded', style: TextStyle(fontSize: 12, color: Colors.grey.shade500, fontStyle: FontStyle.italic))
        else ...[
          if (enBtn != null) _LangChip(text: 'EN', solution: solution, onTap: enBtn!),
          if (hiBtn != null) ...[
            const SizedBox(width: 8),
            _LangChip(text: 'हिं', solution: solution, onTap: hiBtn!),
          ],
        ],
      ],
    );
  }
}

class _LangChip extends StatelessWidget {
  final String text;
  final bool solution;
  final VoidCallback onTap;
  const _LangChip({required this.text, required this.solution, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final c = solution ? Colors.teal : Theme.of(context).colorScheme.primary;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(9),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: c.withValues(alpha: .10),
          borderRadius: BorderRadius.circular(9),
          border: Border.all(color: c.withValues(alpha: .35)),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.visibility_outlined, size: 14, color: c),
          const SizedBox(width: 5),
          Text(text, style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: c)),
        ]),
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
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 46, color: Colors.grey.shade400),
            const SizedBox(height: 14),
            Text(title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            Text(subtitle, textAlign: TextAlign.center, style: TextStyle(color: Colors.grey.shade600)),
            if (onRetry != null) ...[
              const SizedBox(height: 16),
              FilledButton.tonal(onPressed: onRetry, child: const Text('Retry')),
            ],
          ],
        ),
      ),
    );
  }
}
