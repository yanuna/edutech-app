import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/api_client.dart';
import '../api/api_endpoints.dart';
import '../models/pyq.dart';
import '../services/pyq_service.dart';

/// PYQ index for a given year (or `null` → latest year with data).
/// Returns the available years too, so the screen can render the year picker.
final pyqIndexProvider = FutureProvider.family<PyqIndex, int?>((ref, year) async {
  final path = year == null ? ApiEndpoints.pyqs : ApiEndpoints.pyqsForYear(year);
  try {
    final res = await ApiClient.instance.get(path);
    final json = res.data as Map<String, dynamic>;
    await PyqIndexCache.write(year, json); // best-effort, for offline browsing
    return PyqIndex.fromJson(json);
  } catch (_) {
    // Offline / server unreachable → fall back to the last cached index so
    // papers saved for offline reading remain reachable.
    final cached = await PyqIndexCache.read(year);
    if (cached != null) return PyqIndex.fromJson(cached);
    rethrow;
  }
});

/// Tracks which PYQ papers are saved offline (AES-encrypted on device) and
/// which are mid-download, so the cards can show a "Save offline" button /
/// "Available offline" indicator with a spinner while working.
///
/// `saved` holds the slot cache-ids currently present offline; a paper counts
/// as offline once *every* one of its available slots is saved. `busy` holds
/// paper ids that are currently saving or removing.
class PyqOfflineState {
  final Set<String> saved;
  final Set<int> busy;
  const PyqOfflineState({this.saved = const {}, this.busy = const {}});

  PyqOfflineState copyWith({Set<String>? saved, Set<int>? busy}) =>
      PyqOfflineState(saved: saved ?? this.saved, busy: busy ?? this.busy);

  bool isOffline(PyqPaper paper) =>
      paper.available.isNotEmpty &&
      paper.available.every((s) => saved.contains(PyqService.cacheId(paper.id, s)));

  bool isBusy(int paperId) => busy.contains(paperId);
}

class PyqOfflineNotifier extends StateNotifier<PyqOfflineState> {
  PyqOfflineNotifier() : super(const PyqOfflineState());

  /// Sync in-memory state with what's actually on disk for one paper.
  Future<void> refresh(PyqPaper paper) async {
    final saved = {...state.saved};
    for (final slot in paper.available) {
      final id = PyqService.cacheId(paper.id, slot);
      if (await PyqService.isOffline(paper.id, slot)) {
        saved.add(id);
      } else {
        saved.remove(id);
      }
    }
    if (mounted) state = state.copyWith(saved: saved);
  }

  /// Download + AES-encrypt every available slot of a paper for offline reading.
  Future<void> save(PyqPaper paper) async {
    if (paper.available.isEmpty || state.isBusy(paper.id)) return;
    state = state.copyWith(busy: {...state.busy, paper.id});
    try {
      final saved = {...state.saved};
      for (final slot in paper.available) {
        await PyqService.saveOffline(paper.id, slot);
        saved.add(PyqService.cacheId(paper.id, slot));
      }
      if (mounted) state = state.copyWith(saved: saved);
    } finally {
      if (mounted) state = state.copyWith(busy: {...state.busy}..remove(paper.id));
    }
  }

  /// Delete every offline copy of a paper.
  Future<void> remove(PyqPaper paper) async {
    if (state.isBusy(paper.id)) return;
    state = state.copyWith(busy: {...state.busy, paper.id});
    try {
      for (final slot in paper.available) {
        await PyqService.removeOffline(paper.id, slot);
      }
      final saved = {...state.saved}
        ..removeAll(paper.available.map((s) => PyqService.cacheId(paper.id, s)));
      if (mounted) state = state.copyWith(saved: saved);
    } finally {
      if (mounted) state = state.copyWith(busy: {...state.busy}..remove(paper.id));
    }
  }
}

final pyqOfflineProvider =
    StateNotifierProvider<PyqOfflineNotifier, PyqOfflineState>(
  (_) => PyqOfflineNotifier(),
);
