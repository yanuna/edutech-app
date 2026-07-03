import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';

import '../api/api_client.dart';
import '../api/api_endpoints.dart';
import 'secure_file_store.dart';

/// Loads a PYQ PDF for the secure viewer.
///
/// Flow: if an AES-encrypted offline copy exists, decrypt it in memory and use
/// that (works offline). Otherwise stream the bytes from the API (bearer token
/// added by the Dio auth interceptor), cache them ENCRYPTED for next time, and
/// return them. Plaintext bytes only ever live in memory.
class PyqService {
  PyqService._();

  static String cacheId(int paperId, String slot) => 'pyq_${paperId}_$slot';

  /// Returns decrypted-in-memory PDF bytes, downloading + encrypting on first use.
  static Future<Uint8List> loadPdf(int paperId, String slot, {bool cache = true}) async {
    final id = cacheId(paperId, slot);

    if (cache && await SecureFileStore.instance.exists(id)) {
      final cached = await SecureFileStore.instance.read(id);
      if (cached != null) return cached;
    }

    final res = await ApiClient.instance.dio.get(
      ApiEndpoints.pyqFile(paperId, slot),
      options: Options(responseType: ResponseType.bytes),
    );
    final bytes = Uint8List.fromList(List<int>.from(res.data as List));

    if (cache) {
      // Best-effort: never let a caching failure break viewing.
      try {
        await SecureFileStore.instance.save(id, bytes);
      } catch (_) {}
    }
    return bytes;
  }

  /// Whether a slot is already saved for offline reading.
  static Future<bool> isOffline(int paperId, String slot) =>
      SecureFileStore.instance.exists(cacheId(paperId, slot));

  /// Download + encrypt for offline WITHOUT opening the viewer (e.g. a "Save
  /// offline" button).
  static Future<void> saveOffline(int paperId, String slot) async {
    await loadPdf(paperId, slot, cache: true);
  }

  static Future<void> removeOffline(int paperId, String slot) =>
      SecureFileStore.instance.delete(cacheId(paperId, slot));
}

/// Plain-JSON disk cache of the PYQ index (year list + paper metadata) so the
/// list still renders when the device is offline — a prerequisite for reaching
/// papers that were saved for offline reading. This is non-sensitive metadata
/// (titles, years, slot availability), so it is NOT encrypted; the PDFs
/// themselves stay AES-encrypted via [SecureFileStore].
class PyqIndexCache {
  PyqIndexCache._();

  static const _subDir = 'pyq_index_cache';

  static String _key(int? year) => year == null ? 'latest' : 'year_$year';

  static Future<File> _file(int? year) async {
    final base = await getApplicationDocumentsDirectory();
    final dir = Directory('${base.path}/$_subDir');
    if (!await dir.exists()) await dir.create(recursive: true);
    return File('${dir.path}/${_key(year)}.json');
  }

  static Future<void> write(int? year, Map<String, dynamic> json) async {
    try {
      await (await _file(year)).writeAsString(jsonEncode(json), flush: true);
    } catch (_) {
      // Best-effort: a caching failure must never break a live fetch.
    }
  }

  static Future<Map<String, dynamic>?> read(int? year) async {
    try {
      final file = await _file(year);
      if (!await file.exists()) return null;
      return jsonDecode(await file.readAsString()) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }
}
