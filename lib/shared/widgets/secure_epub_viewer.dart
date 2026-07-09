import 'package:flutter/material.dart';
import 'package:flutter_epub_viewer/flutter_epub_viewer.dart';

import 'secure_watermark.dart';

/// In-app, view-only EPUB reader built on **flutter_epub_viewer** (epub.js inside
/// an isolated InAppWebView).
///
/// Security posture (DRM-like, best-effort):
///   * NO share / print / download actions.
///   * Native copy/context menu is suppressed (`suppressNativeContextMenu: true`)
///     and scripted content in the book is disabled.
///   * Screenshots & screen recording are blocked natively by Android
///     `FLAG_SECURE` (MainActivity) and the iOS capture cover (AppDelegate).
///   * An optional tiled [watermark] is overlaid as an off-device deterrent.
///
/// The book stays **searchable** via epub.js: [EpubController.search] returns
/// matches with a CFI, and tapping a result jumps to it.
///
/// The [url] must be a short-lived signed URL to the .epub — epub.js streams it
/// inside the webview, so no plaintext copy is written to disk.
///
/// Set [embedded] to render inline (no Scaffold) inside another screen.
class SecureEpubViewer extends StatefulWidget {
  final String url;
  final String title;
  final String? watermark;
  final bool embedded;

  const SecureEpubViewer({
    super.key,
    required this.url,
    this.title = 'Document',
    this.watermark,
    this.embedded = false,
  });

  @override
  State<SecureEpubViewer> createState() => _SecureEpubViewerState();
}

class _SecureEpubViewerState extends State<SecureEpubViewer> {
  final EpubController _controller = EpubController();
  bool _loaded = false;

  Future<void> _openSearch() async {
    final field = TextEditingController();
    final query = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Search in book'),
        content: TextField(
          controller: field,
          autofocus: true,
          textInputAction: TextInputAction.search,
          decoration: const InputDecoration(hintText: 'Enter keywords…'),
          onSubmitted: (v) => Navigator.pop(ctx, v.trim()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, field.text.trim()),
            child: const Text('Search'),
          ),
        ],
      ),
    );

    if (query == null || query.isEmpty || !mounted) return;

    final results = await _controller.search(query: query);
    if (!mounted) return;

    if (results.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No matches for “$query”.')),
      );
      return;
    }

    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => ListView.separated(
        padding: const EdgeInsets.only(bottom: 16),
        itemCount: results.length,
        separatorBuilder: (_, _) => const Divider(height: 1),
        itemBuilder: (_, i) {
          final r = results[i];
          return ListTile(
            dense: true,
            title: Text(
              r.excerpt.trim(),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 13),
            ),
            onTap: () {
              Navigator.pop(ctx);
              _controller.display(cfi: r.cfi);
            },
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final Widget content = Column(
      children: [
        _searchBar(),
        Expanded(
          child: Stack(
            children: [
              EpubViewer(
                epubController: _controller,
                epubSource: EpubSource.fromUrl(widget.url),
                displaySettings: EpubDisplaySettings(
                  flow: EpubFlow.paginated,
                  snap: true,
                  allowScriptedContent: false,
                ),
                suppressNativeContextMenu: true,
                onEpubLoaded: () {
                  if (mounted) setState(() => _loaded = true);
                },
              ),
              if (widget.watermark != null)
                Positioned.fill(child: SecureWatermark(widget.watermark!)),
            ],
          ),
        ),
      ],
    );

    if (widget.embedded) return content;

    return Scaffold(
      appBar: AppBar(title: Text(widget.title, overflow: TextOverflow.ellipsis)),
      body: content,
    );
  }

  Widget _searchBar() => Material(
        elevation: 1,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          child: Row(
            children: [
              const Icon(Icons.menu_book_outlined, size: 20),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'View-only • search enabled',
                  style: TextStyle(fontSize: 13),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              IconButton(
                visualDensity: VisualDensity.compact,
                icon: const Icon(Icons.search),
                tooltip: 'Search in book',
                onPressed: _loaded ? _openSearch : null,
              ),
            ],
          ),
        ),
      );
}
