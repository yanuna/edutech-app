import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:pdfrx/pdfrx.dart';

import '../../core/services/secure_file_store.dart';
import 'secure_watermark.dart';

/// In-app, view-only PDF viewer built on **pdfrx**.
///
/// Security posture (DRM-like):
///   * NO share / print / download actions.
///   * Text selection & copy are hard-disabled (`PdfTextSelectionParams(enabled:
///     false)`), which also removes the long-press context menu.
///   * Screenshots & screen recording are blocked natively by Android
///     `FLAG_SECURE` (MainActivity) and the iOS capture cover (AppDelegate).
///   * An optional tiled [watermark] (e.g. the user's email) is painted over the
///     pages as an off-device deterrent.
///
/// Despite the lock-down the document stays **searchable**: pdfrx keeps a text
/// layer, so [PdfTextSearcher] finds and highlights keywords even though the
/// user can't select or copy that text.
///
/// Feed it in-memory bytes only (decrypted from [SecureFileStore] or fetched
/// from the network) — plaintext is never persisted by this widget.
///
/// Set [embedded] to render inline (no Scaffold) inside another screen; leave it
/// false for a standalone full-screen route.
///
/// Convenience constructors:
///   SecurePdfViewer.data(bytes, title: '…')          // from memory
///   SecurePdfViewer.offline('pyq_2023_p1', title: …) // decrypt from secure store
///   SecurePdfViewer.loader(() => dio.get(...), …)     // fetch, then view
class SecurePdfViewer extends StatefulWidget {
  final String title;
  final String? watermark;
  final bool embedded;

  /// Provide exactly one source.
  final Uint8List? data;
  final String? offlineId;
  final Future<Uint8List> Function()? loader;

  const SecurePdfViewer._({
    required this.title,
    this.watermark,
    this.embedded = false,
    this.data,
    this.offlineId,
    this.loader,
  });

  factory SecurePdfViewer.data(
    Uint8List bytes, {
    String title = 'Document',
    String? watermark,
    bool embedded = false,
  }) =>
      SecurePdfViewer._(
          title: title, data: bytes, watermark: watermark, embedded: embedded);

  factory SecurePdfViewer.offline(
    String offlineId, {
    String title = 'Document',
    String? watermark,
    bool embedded = false,
  }) =>
      SecurePdfViewer._(
          title: title,
          offlineId: offlineId,
          watermark: watermark,
          embedded: embedded);

  factory SecurePdfViewer.loader(
    Future<Uint8List> Function() loader, {
    String title = 'Document',
    String? watermark,
    bool embedded = false,
  }) =>
      SecurePdfViewer._(
          title: title,
          loader: loader,
          watermark: watermark,
          embedded: embedded);

  @override
  State<SecurePdfViewer> createState() => _SecurePdfViewerState();
}

class _SecurePdfViewerState extends State<SecurePdfViewer> {
  final PdfViewerController _controller = PdfViewerController();
  late final PdfTextSearcher _searcher =
      PdfTextSearcher(_controller)..addListener(_onSearchUpdate);
  final TextEditingController _searchField = TextEditingController();

  Uint8List? _bytes;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      Uint8List? bytes = widget.data;
      bytes ??= widget.offlineId != null
          ? await SecureFileStore.instance.read(widget.offlineId!)
          : (widget.loader != null ? await widget.loader!() : null);

      // _load() is fired from initState and awaits a full PDF download, so the
      // user can easily back out before it returns — every setState below then
      // fired after dispose().
      if (!mounted) return;

      if (bytes == null) {
        setState(() => _error = 'This document is not available offline.');
        return;
      }
      setState(() => _bytes = bytes);
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = 'Unable to open this document.');
    }
  }

  void _onSearchUpdate() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _searcher.removeListener(_onSearchUpdate);
    _searcher.dispose();
    _searchField.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Widget content = _error != null
        ? Center(
            child: Padding(
              padding: const EdgeInsets.all(28),
              child: Text(_error!, textAlign: TextAlign.center),
            ),
          )
        : _bytes == null
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  _searchBar(),
                  Expanded(child: _viewer(_bytes!)),
                ],
              );

    if (widget.embedded) return content;

    return Scaffold(
      appBar: AppBar(title: Text(widget.title, overflow: TextOverflow.ellipsis)),
      body: content,
    );
  }

  Widget _viewer(Uint8List bytes) => PdfViewer.data(
        bytes,
        sourceName: widget.title,
        controller: _controller,
        params: PdfViewerParams(
          // Hard-disable selection/copy + long-press context menu.
          textSelectionParams: const PdfTextSelectionParams(enabled: false),
          // Highlight in-document search matches.
          pagePaintCallbacks: [_searcher.pageTextMatchPaintCallback],
          viewerOverlayBuilder: widget.watermark == null
              ? null
              : (context, size, handleLinkTap) =>
                  [SecureWatermark(widget.watermark!)],
        ),
      );

  Widget _searchBar() {
    final total = _searcher.matches.length;
    final current = _searcher.currentIndex;
    final label = total == 0
        ? (_searcher.isSearching ? 'Searching…' : '')
        : '${(current ?? 0) + 1} / $total';

    return Material(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Row(
          children: [
            const Icon(Icons.search, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: _searchField,
                textInputAction: TextInputAction.search,
                decoration: const InputDecoration(
                  isDense: true,
                  hintText: 'Search in document…',
                  border: InputBorder.none,
                ),
                onChanged: (v) {
                  if (v.trim().isEmpty) {
                    _searcher.resetTextSearch();
                  } else {
                    _searcher.startTextSearch(v, caseInsensitive: true);
                  }
                },
              ),
            ),
            if (label.isNotEmpty)
              Text(label, style: const TextStyle(fontSize: 13)),
            IconButton(
              visualDensity: VisualDensity.compact,
              icon: const Icon(Icons.keyboard_arrow_up),
              tooltip: 'Previous match',
              onPressed: total == 0 ? null : () => _searcher.goToPrevMatch(),
            ),
            IconButton(
              visualDensity: VisualDensity.compact,
              icon: const Icon(Icons.keyboard_arrow_down),
              tooltip: 'Next match',
              onPressed: total == 0 ? null : () => _searcher.goToNextMatch(),
            ),
          ],
        ),
      ),
    );
  }
}
