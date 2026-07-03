import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../models/govt_job.dart';
import '../providers/govt_jobs_provider.dart';

class GovtJobsScreen extends ConsumerStatefulWidget {
  const GovtJobsScreen({super.key});

  @override
  ConsumerState<GovtJobsScreen> createState() => _GovtJobsScreenState();
}

class _GovtJobsScreenState extends ConsumerState<GovtJobsScreen> {
  final _search = TextEditingController();
  final _scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    _scroll.addListener(() {
      if (_scroll.position.pixels > _scroll.position.maxScrollExtent - 400) {
        ref.read(govtJobsProvider.notifier).loadMore();
      }
    });
  }

  @override
  void dispose() {
    _search.dispose();
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(govtJobsProvider);
    final notifier = ref.read(govtJobsProvider.notifier);
    final categories = ref.watch(govtJobCategoriesProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF7F7FB),
      appBar: AppBar(
        title: const Text(
          'Government Jobs',
          style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.bookmark_outline),
            tooltip: 'Saved jobs',
            onPressed: () => context.push('/govt-jobs/saved'),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              controller: _search,
              textInputAction: TextInputAction.search,
              onSubmitted: notifier.setSearch,
              decoration: InputDecoration(
                hintText: 'Search jobs, organisation…',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _search.text.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _search.clear();
                          notifier.setSearch('');
                        },
                      ),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          // Category chips
          categories.maybeWhen(
            data: (cats) => SizedBox(
              height: 44,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                children: [
                  _chip(
                    'All',
                    notifier.category == null,
                    () => notifier.setCategory(null),
                  ),
                  for (final c in cats)
                    _chip(
                      c.name,
                      notifier.category == c.slug,
                      () => notifier.setCategory(c.slug),
                    ),
                ],
              ),
            ),
            orElse: () => const SizedBox(height: 8),
          ),
          // List
          Expanded(
            child: state.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => _errorView(notifier),
              data: (s) => s.jobs.isEmpty
                  ? _emptyView()
                  : RefreshIndicator(
                      onRefresh: notifier.refresh,
                      child: ListView.builder(
                        controller: _scroll,
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                        itemCount: s.jobs.length + (s.loadingMore ? 1 : 0),
                        itemBuilder: (_, i) {
                          if (i >= s.jobs.length) {
                            return const Padding(
                              padding: EdgeInsets.all(16),
                              child: Center(child: CircularProgressIndicator()),
                            );
                          }
                          return _JobCard(job: s.jobs[i]);
                        },
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _chip(String label, bool selected, VoidCallback onTap) => Padding(
    padding: const EdgeInsets.only(right: 8),
    child: ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
      selectedColor: const Color(0xFF4F46E5),
      labelStyle: TextStyle(
        color: selected ? Colors.white : Colors.black87,
        fontSize: 13,
      ),
      backgroundColor: Colors.white,
    ),
  );

  Widget _emptyView() => ListView(
    children: const [
      SizedBox(height: 120),
      Icon(Icons.work_off_outlined, size: 54, color: Colors.black26),
      SizedBox(height: 12),
      Center(
        child: Text('No jobs found', style: TextStyle(color: Colors.black54)),
      ),
    ],
  );

  Widget _errorView(GovtJobsNotifier notifier) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text('Could not load jobs'),
        const SizedBox(height: 8),
        FilledButton(onPressed: notifier.refresh, child: const Text('Retry')),
      ],
    ),
  );
}

class _JobCard extends ConsumerWidget {
  final GovtJob job;
  const _JobCard({required this.job});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final saved = ref.watch(bookmarkedSlugsProvider).contains(job.slug);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => context.push('/govt-jobs/${job.slug}'),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      job.title,
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w600,
                        fontSize: 15.5,
                      ),
                    ),
                  ),
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    icon: Icon(
                      saved ? Icons.bookmark : Icons.bookmark_outline,
                      color: const Color(0xFF4F46E5),
                    ),
                    onPressed: () => ref
                        .read(bookmarkedSlugsProvider.notifier)
                        .toggle(job.slug),
                  ),
                ],
              ),
              if (job.organization != null)
                Text(
                  job.organization!,
                  style: const TextStyle(color: Colors.black54, fontSize: 13),
                ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: [
                  if (job.category != null)
                    _tag(
                      job.category!,
                      const Color(0xFFEDE9FE),
                      const Color(0xFF6D28D9),
                    ),
                  if (job.totalVacancies != null)
                    _tag(
                      '${job.totalVacancies} posts',
                      const Color(0xFFE0F2FE),
                      const Color(0xFF0369A1),
                    ),
                  if (job.lastDate != null)
                    _tag(
                      'Last: ${job.lastDate}',
                      job.isClosingSoon
                          ? const Color(0xFFFEE2E2)
                          : const Color(0xFFDCFCE7),
                      job.isClosingSoon
                          ? const Color(0xFFB91C1C)
                          : const Color(0xFF15803D),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _tag(String text, Color bg, Color fg) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    decoration: BoxDecoration(
      color: bg,
      borderRadius: BorderRadius.circular(999),
    ),
    child: Text(
      text,
      style: TextStyle(color: fg, fontSize: 12, fontWeight: FontWeight.w600),
    ),
  );
}
