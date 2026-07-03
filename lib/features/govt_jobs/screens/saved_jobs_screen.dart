import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/govt_jobs_provider.dart';

class SavedJobsScreen extends ConsumerWidget {
  const SavedJobsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(savedJobsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF7F7FB),
      appBar: AppBar(
        title: const Text(
          'Saved Jobs',
          style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600),
        ),
      ),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Text(
            'Could not load saved jobs',
            style: TextStyle(color: Colors.grey.shade600),
          ),
        ),
        data: (jobs) => jobs.isEmpty
            ? const Center(
                child: Text(
                  'No saved jobs yet',
                  style: TextStyle(color: Colors.black54),
                ),
              )
            : RefreshIndicator(
                onRefresh: () async => ref.invalidate(savedJobsProvider),
                child: ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: jobs.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (_, i) {
                    final job = jobs[i];
                    return Card(
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: ListTile(
                        title: Text(
                          job.title,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14.5,
                          ),
                        ),
                        subtitle: Text(
                          [
                            job.organization,
                            if (job.lastDate != null) 'Last: ${job.lastDate}',
                          ].whereType<String>().join(' · '),
                        ),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => context.push('/govt-jobs/${job.slug}'),
                      ),
                    );
                  },
                ),
              ),
      ),
    );
  }
}
