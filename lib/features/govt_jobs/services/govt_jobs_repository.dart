import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/api_client.dart';
import '../../../core/api/api_endpoints.dart';
import '../models/govt_job.dart';

final govtJobsRepositoryProvider = Provider<GovtJobsRepository>(
  (ref) => GovtJobsRepository(),
);

typedef JobsPage = ({List<GovtJob> jobs, int currentPage, int lastPage});

class GovtJobsRepository {
  Future<JobsPage> getJobs({String? q, String? category, int page = 1}) async {
    final res = await ApiClient.instance.get(
      ApiEndpoints.govtJobs,
      params: {
        if (q != null && q.isNotEmpty) 'q': q,
        if (category != null && category.isNotEmpty) 'category': category,
        'page': page,
      },
    );
    final data = res.data as Map<String, dynamic>;
    final jobs = ((data['data'] as List?) ?? [])
        .map((e) => GovtJob.fromJson(e as Map<String, dynamic>))
        .toList();
    final meta = (data['meta'] as Map<String, dynamic>?) ?? const {};
    return (
      jobs: jobs,
      currentPage: (meta['current_page'] as int?) ?? 1,
      lastPage: (meta['last_page'] as int?) ?? 1,
    );
  }

  Future<GovtJob> getJob(String slug) async {
    final res = await ApiClient.instance.get(ApiEndpoints.govtJob(slug));
    return GovtJob.fromJson(
      (res.data as Map<String, dynamic>)['data'] as Map<String, dynamic>,
    );
  }

  Future<List<JobCategoryLite>> getCategories() async {
    final res = await ApiClient.instance.get(ApiEndpoints.govtJobsFilters);
    final cats =
        ((res.data as Map<String, dynamic>)['categories'] as List?) ?? [];
    return cats
        .map((e) => JobCategoryLite.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<bool> toggleBookmark(String slug) async {
    final res = await ApiClient.instance.post(
      ApiEndpoints.govtJobBookmark(slug),
    );
    return (res.data as Map<String, dynamic>)['bookmarked'] == true;
  }

  Future<List<GovtJob>> getBookmarks() async {
    final res = await ApiClient.instance.get(ApiEndpoints.govtJobBookmarks);
    final data = ((res.data as Map<String, dynamic>)['data'] as List?) ?? [];
    return data
        .map((e) => GovtJob.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
