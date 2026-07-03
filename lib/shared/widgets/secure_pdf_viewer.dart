import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:pdfx/pdfx.dart';

import '../../core/services/secure_file_store.dart';

/// In-app PDF viewer that renders pages to images via pdf.js-equivalent native
/// rendering (pdfx). There is NO text layer, and NO share / print / download
/// action — it is strictly view-only.
///
/// Combined with the native content protection (Android FLAG_SECURE in
/// MainActivity, iOS capture cover in AppDelegate), on-device screenshots and
/// screen recording are blocked as well.
///
/// Feed it in-memory bytes only (decrypted from [SecureFileStore] or fetched
/// from the network) — plaintext is never persisted by this widget.
///
/// Convenience constructors:
///   SecurePdfViewer.data(bytes, title: '…')        // from memory
///   SecurePdfViewer.offline('pyq_2023_p1', title)  // decrypt from secure store
///   SecurePdfViewer.download(url, cacheId, …)       // fetch + cache encrypted, then view
class SecurePdfViewer extends StatefulWidget {
  final String title;

  /// Provide exactly one source.
  final Uint8List? data;
  final String? offlineId;
  final Future<Uint8List> Function()? loader;

  const SecurePdfViewer._({
    required this.title,
    this.data,
    this.offlineId,
    this.loader,
  });

  /// View bytes already in memory.
  factory SecurePdfViewer.data(Uint8List bytes, {String title = 'Document'}) =>
      SecurePdfViewer._(title: title, data: bytes);

  /// Decrypt & view a file previously saved offline via [SecureFileStore].
  factory SecurePdfViewer.offline(String offlineId, {String title = 'Document'}) =>
      SecurePdfViewer._(title: title, offlineId: offlineId);

  /// Load bytes from any async source (e.g. a Dio download) and view them.
  factory SecurePdfViewer.loader(Future<Uint8List> Function() loader, {String title = 'Document'}) =>
      SecurePdfViewer._(title: title, loader: loader);

  @override
  State<SecurePdfViewer> createState() => _SecurePdfViewerState();
}

class _SecurePdfViewerState extends State<SecurePdfViewer> {
  PdfControllerPinch? _controller;
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

      if (bytes == null) {
        setState(() => _error = 'This document is not available offline.');
        return;
      }
      setState(() {
        _controller = PdfControllerPinch(document: PdfDocument.openData(bytes!));
      });
    } catch (e) {
      setState(() => _error = 'Unable to open this document.');
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title, overflow: TextOverflow.ellipsis),
        // Intentionally NO share / print / download actions — view-only.
      ),
      body: _error != null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(28),
                child: Text(_error!, textAlign: TextAlign.center),
              ),
            )
          : _controller == null
              ? const Center(child: CircularProgressIndicator())
              : PdfViewPinch(controller: _controller!),
    );
  }
}
