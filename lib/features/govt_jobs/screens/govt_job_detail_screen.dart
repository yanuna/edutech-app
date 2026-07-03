import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/govt_job.dart';
import '../providers/govt_jobs_provider.dart';

class GovtJobDetailScreen extends ConsumerWidget {
  final String slug;
  const GovtJobDetailScreen({super.key, required this.slug});

  Future<void> _open(String url) async {
    final uri = Uri.tryParse(url);
    if (uri != null) await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(govtJobDetailProvider(slug));
    final saved = ref.watch(bookmarkedSlugsProvider).contains(slug);

    return Scaffold(
      backgroundColor: const Color(0xFFF7F7FB),
      appBar: AppBar(
        title: const Text(
          'Job Details',
          style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600),
        ),
        actions: [
          IconButton(
            icon: Icon(
              saved ? Icons.bookmark : Icons.bookmark_outline,
              color: const Color(0xFF4F46E5),
            ),
            onPressed: () =>
                ref.read(bookmarkedSlugsProvider.notifier).toggle(slug),
          ),
        ],
      ),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Could not load this job'),
              const SizedBox(height: 8),
              FilledButton(
                onPressed: () => ref.invalidate(govtJobDetailProvider(slug)),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (job) => _body(context, job),
      ),
    );
  }

  Widget _body(BuildContext context, GovtJob job) {
    final rows = <List<String>>[
      if (job.advertisementNo != null)
        ['Advertisement No.', job.advertisementNo!],
      if (job.totalVacancies != null)
        ['Total Vacancies', '${job.totalVacancies}'],
      if (job.qualification != null) ['Qualification', job.qualification!],
      if (job.ageLimit != null) ['Age Limit', job.ageLimit!],
      if (job.salary != null) ['Salary', job.salary!],
      if (job.state != null) ['Location', job.state!],
      if (job.applicationStartDate != null)
        ['Application Start', job.applicationStartDate!],
      if (job.lastDate != null) ['Last Date', job.lastDate!],
      if (job.examDate != null) ['Exam Date', job.examDate!],
    ];

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  job.title,
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w700,
                    fontSize: 18,
                  ),
                ),
                if (job.organization != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      job.organization!,
                      style: const TextStyle(color: Colors.black54),
                    ),
                  ),
                const SizedBox(height: 14),
                for (final r in rows)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 7),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: 140,
                          child: Text(
                            r[0],
                            style: const TextStyle(
                              color: Colors.black54,
                              fontSize: 13.5,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            r[1],
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 13.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                if (job.selectionProcess != null)
                  _section('Selection Process', job.selectionProcess!),
                if (job.description != null)
                  _section('Details', job.description!),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        if (job.applicationLink != null)
          FilledButton.icon(
            onPressed: () => _open(job.applicationLink!),
            icon: const Icon(Icons.open_in_new),
            label: const Text('Apply Online'),
          ),
        if (job.notificationPdfUrl != null)
          Padding(
            padding: const EdgeInsets.only(top: 10),
            child: OutlinedButton.icon(
              onPressed: () => _open(job.notificationPdfUrl!),
              icon: const Icon(Icons.picture_as_pdf_outlined),
              label: const Text('Notification PDF'),
            ),
          ),
        if (job.officialWebsiteUrl != null)
          Padding(
            padding: const EdgeInsets.only(top: 10),
            child: OutlinedButton.icon(
              onPressed: () => _open(job.officialWebsiteUrl!),
              icon: const Icon(Icons.public),
              label: const Text('Official Website'),
            ),
          ),
      ],
    );
  }

  Widget _section(String title, String body) => Padding(
    padding: const EdgeInsets.only(top: 16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w600,
            fontSize: 15,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          body,
          style: const TextStyle(
            color: Colors.black87,
            height: 1.5,
            fontSize: 14,
          ),
        ),
      ],
    ),
  );
}
