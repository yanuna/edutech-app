import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/govt_job.dart';
import '../services/govt_jobs_repository.dart';

// ── Categories for the filter chips ──────────────────────────────────────────
final govtJobCategoriesProvider = FutureProvider<List<JobCategoryLite>>((ref) {
  return ref.read(govtJobsRepositoryProvider).getCategories();
});

// ── Paginated, filterable job list ───────────────────────────────────────────
class GovtJobsState {
  final List<GovtJob> jobs;
  final bool loadingMore;
  final bool hasMore;
  const GovtJobsState({
    required this.jobs,
    this.loadingMore = false,
    this.hasMore = false,
  });

  GovtJobsState copyWith({
    List<GovtJob>? jobs,
    bool? loadingMore,
    bool? hasMore,
  }) => GovtJobsState(
    jobs: jobs ?? this.jobs,
    loadingMore: loadingMore ?? this.loadingMore,
    hasMore: hasMore ?? this.hasMore,
  );
}

class GovtJobsNotifier extends StateNotifier<AsyncValue<GovtJobsState>> {
  GovtJobsNotifier(this._repo) : super(const AsyncValue.loading()) {
    load();
  }

  final GovtJobsRepository _repo;
  String _q = '';
  String? _category;
  int _page = 1;

  Future<void> load() async {
    state = const AsyncValue.loading();
    _page = 1;
    try {
      final r = await _repo.getJobs(q: _q, category: _category, page: 1);
      state = AsyncValue.data(
        GovtJobsState(jobs: r.jobs, hasMore: r.currentPage < r.lastPage),
      );
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> loadMore() async {
    final cur = state.value;
    if (cur == null || cur.loadingMore || !cur.hasMore) return;
    state = AsyncValue.data(cur.copyWith(loadingMore: true));
    try {
      final r = await _repo.getJobs(
        q: _q,
        category: _category,
        page: _page + 1,
      );
      _page++;
      state = AsyncValue.data(
        GovtJobsState(
          jobs: [...cur.jobs, ...r.jobs],
          hasMore: r.currentPage < r.lastPage,
        ),
      );
    } catch (_) {
      state = AsyncValue.data(cur.copyWith(loadingMore: false));
    }
  }

  void setSearch(String q) {
    if (q == _q) return;
    _q = q;
    load();
  }

  void setCategory(String? slug) {
    if (slug == _category) return;
    _category = slug;
    load();
  }

  String? get category => _category;
  Future<void> refresh() => load();
}

final govtJobsProvider =
    StateNotifierProvider<GovtJobsNotifier, AsyncValue<GovtJobsState>>(
      (ref) => GovtJobsNotifier(ref.read(govtJobsRepositoryProvider)),
    );

// ── Bookmarked job slugs (synced with the backend) ───────────────────────────
class BookmarkSlugsNotifier extends StateNotifier<Set<String>> {
  BookmarkSlugsNotifier(this._repo) : super(const {}) {
    _load();
  }

  final GovtJobsRepository _repo;

  Future<void> _load() async {
    try {
      final jobs = await _repo.getBookmarks();
      state = jobs.map((j) => j.slug).toSet();
    } catch (_) {
      /* guest / offline — keep empty */
    }
  }

  Future<bool> toggle(String slug) async {
    try {
      final on = await _repo.toggleBookmark(slug);
      state = on ? {...state, slug} : (state.toSet()..remove(slug));
      return on;
    } catch (_) {
      return state.contains(slug);
    }
  }
}

final bookmarkedSlugsProvider =
    StateNotifierProvider<BookmarkSlugsNotifier, Set<String>>(
      (ref) => BookmarkSlugsNotifier(ref.read(govtJobsRepositoryProvider)),
    );

// ── A single job's detail ────────────────────────────────────────────────────
final govtJobDetailProvider = FutureProvider.family<GovtJob, String>((
  ref,
  slug,
) {
  return ref.read(govtJobsRepositoryProvider).getJob(slug);
});

final savedJobsProvider = FutureProvider<List<GovtJob>>((ref) {
  return ref.read(govtJobsRepositoryProvider).getBookmarks();
});
