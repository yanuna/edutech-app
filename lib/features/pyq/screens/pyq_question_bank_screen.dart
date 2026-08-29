import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../shared/widgets/rich_content_view.dart';
import '../providers/pyq_question_provider.dart';

/// Question-level PYQ browsing: filter previous-year MCQs by year & subject,
/// each shown with its correct answer + explanation. Trends via the chart icon.
class PyqQuestionBankScreen extends ConsumerStatefulWidget {
  const PyqQuestionBankScreen({super.key});

  @override
  ConsumerState<PyqQuestionBankScreen> createState() => _PyqQuestionBankScreenState();
}

class _PyqQuestionBankScreenState extends ConsumerState<PyqQuestionBankScreen> {
  int? _year;
  int? _subjectId;

  @override
  Widget build(BuildContext context) {
    final filter = PyqFilter(year: _year, subjectId: _subjectId);
    final async = ref.watch(pyqQuestionsProvider(filter));
    final filters = ref.watch(pyqFiltersProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('PYQ Question Bank'),
        actions: [
          IconButton(tooltip: 'Trends', icon: const Icon(Icons.insights_rounded), onPressed: () => context.push('/pyqs/trends')),
        ],
      ),
      body: Column(
        children: [
          filters.maybeWhen(
            data: (f) => Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: Row(children: [
                Expanded(child: _Dropdown<int?>(
                  label: 'Year',
                  value: _year,
                  items: [const DropdownMenuItem(value: null, child: Text('All years')), ...f.years.map((y) => DropdownMenuItem(value: y, child: Text('$y')))],
                  onChanged: (v) => setState(() => _year = v),
                )),
                const SizedBox(width: 12),
                Expanded(child: _Dropdown<int?>(
                  label: 'Subject',
                  value: _subjectId,
                  items: [const DropdownMenuItem(value: null, child: Text('All subjects')), ...f.subjects.map((s) => DropdownMenuItem(value: s.id, child: Text(s.name, overflow: TextOverflow.ellipsis)))],
                  onChanged: (v) => setState(() => _subjectId = v),
                )),
              ]),
            ),
            orElse: () => const SizedBox.shrink(),
          ),
          Expanded(
            child: async.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, _) => _Message(icon: Icons.wifi_off_rounded, title: 'Could not load', subtitle: 'Try again.', onRetry: () => ref.invalidate(pyqQuestionsProvider(filter))),
              data: (qs) => qs.isEmpty
                  ? const _Message(icon: Icons.history_edu_outlined, title: 'No questions', subtitle: 'No previous-year questions match these filters yet.')
                  : RefreshIndicator(
                      onRefresh: () async => ref.invalidate(pyqQuestionsProvider(filter)),
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: qs.length,
                        itemBuilder: (_, i) => _PyqCard(q: qs[i]),
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Dropdown<T> extends StatelessWidget {
  final String label;
  final T value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?> onChanged;
  const _Dropdown({required this.label, required this.value, required this.items, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return InputDecorator(
      decoration: InputDecoration(labelText: label, isDense: true, border: const OutlineInputBorder(), contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8)),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(value: value, isExpanded: true, items: items, onChanged: onChanged),
      ),
    );
  }
}

class _PyqCard extends StatelessWidget {
  final PyqQuestion q;
  const _PyqCard({required this.q});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), border: Border.all(color: Theme.of(context).dividerColor.withValues(alpha: .5))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(color: Theme.of(context).colorScheme.primary.withValues(alpha: .12), borderRadius: BorderRadius.circular(6)),
            child: Text('UPSC ${q.year}', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Theme.of(context).colorScheme.primary)),
          ),
          const SizedBox(height: 10),
          RichContentView(html: q.question, fontSize: 15),
          const SizedBox(height: 12),
          for (var i = 0; i < q.options.length; i++) _option(i + 1, q.options[i]),
          if (q.explanation != null && q.explanation!.isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: const Color(0xFF6366F1).withValues(alpha: .07), borderRadius: BorderRadius.circular(10), border: const Border(
                left: BorderSide(color: Color(0xFF6366F1), width: 3),
              )),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Explanation', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5, color: Color(0xFF4F46E5))),
                const SizedBox(height: 4),
                RichContentView(html: q.explanation!, fontSize: 14),
              ]),
            ),
          ],
        ],
      ),
    );
  }

  Widget _option(int number, String text) {
    final correct = number == q.correctOption;
    final color = correct ? const Color(0xFF10B981) : Colors.grey;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: correct ? const Color(0xFF10B981).withValues(alpha: .10) : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: correct ? .5 : .25)),
      ),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(correct ? Icons.check_circle : Icons.circle_outlined, size: 18, color: color),
        const SizedBox(width: 10),
        Expanded(child: RichContentView(html: text, fontSize: 14)),
      ]),
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
