import 'package:flutter/material.dart';

import '../../../core/models/article.dart';
import '../../../shared/widgets/rich_content_view.dart';
import '../providers/reader_settings_provider.dart';

/// A section heading for a block, or null if the block is inline prose.
/// Shared by the renderer (to draw the header) and the sticky Table of Contents.
String? articleBlockHeading(ArticleBlock b) {
  switch (b.type) {
    case 'timeline':
      return 'Timeline';
    case 'challenges':
      return 'Challenges';
    case 'way_forward':
      return 'Way Forward';
    case 'summary':
      return 'Summary';
    case 'revision_box':
      return 'Revision Box';
    case 'stats':
      return 'Key Statistics';
    case 'comparison':
      return 'International Comparison';
    case 'scheme':
      return (b.data['name'] as String?)?.trim().isNotEmpty == true ? b.data['name'] as String : 'Government Scheme';
    case 'committee':
      return (b.data['name'] as String?) ?? 'Committee';
    case 'report':
      return (b.data['name'] as String?) ?? 'Report';
    case 'sc_case':
      return (b.data['name'] as String?) ?? 'Supreme Court Case';
    case 'constitutional_article':
      final n = b.data['number'];
      return n != null ? 'Article $n' : 'Constitutional Article';
    default:
      return null; // rich_text, image, quote, callout, flowchart, table
  }
}

/// Renders one article body block against the reader theme + font scale.
class ArticleBlockView extends StatelessWidget {
  final ArticleBlock block;
  final ReaderTheme theme;
  final double fontScale;
  const ArticleBlockView({super.key, required this.block, required this.theme, required this.fontScale});

  double get _base => 15.5 * fontScale;

  @override
  Widget build(BuildContext context) {
    final heading = articleBlockHeading(block);
    final child = _content(context);
    if (heading == null) return Padding(padding: const EdgeInsets.symmetric(vertical: 8), child: child);

    return Padding(
      padding: const EdgeInsets.only(top: 20, bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(heading, style: TextStyle(fontFamily: 'Poppins', fontSize: 18 * fontScale, fontWeight: FontWeight.w700, color: theme.text)),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }

  Widget _html(String? html) => RichContentView(html: html ?? '', fontSize: _base, color: theme.text);

  Widget _content(BuildContext context) {
    final d = block.data;
    switch (block.type) {
      case 'rich_text':
      case 'table':
      case 'summary':
      case 'comparison':
        return _html(d['html'] as String?);
      case 'callout':
        return _CalloutBox(style: (d['style'] as String?) ?? 'info', title: d['title'] as String?, theme: theme, fontScale: fontScale, child: _html(d['html'] as String?));
      case 'quote':
        return _Quote(text: (d['text'] as String?) ?? '', author: d['author'] as String?, theme: theme, fontScale: fontScale);
      case 'image':
      case 'flowchart':
        return _Figure(url: d['url'] as String?, caption: d['caption'] as String?, theme: theme, fontScale: fontScale);
      case 'timeline':
        return _Timeline(items: _list(d['items']), theme: theme, fontScale: fontScale);
      case 'stats':
        return _Stats(items: _list(d['items']), theme: theme, fontScale: fontScale);
      case 'sc_case':
        return _KeyValue(label: 'Held', value: d['held'] as String?, theme: theme, fontScale: fontScale);
      case 'scheme':
      case 'committee':
      case 'report':
        return _KeyValue(label: null, value: d['details'] as String?, theme: theme, fontScale: fontScale);
      case 'constitutional_article':
        return _KeyValue(label: null, value: d['text'] as String?, theme: theme, fontScale: fontScale);
      case 'challenges':
      case 'way_forward':
      case 'revision_box':
        return _Points(points: _list(d['points']), theme: theme, fontScale: fontScale, highlight: block.type == 'revision_box');
      default:
        return _html(d['html'] as String? ?? d['text'] as String?);
    }
  }

  static List<Map<String, dynamic>> _list(dynamic v) =>
      ((v as List?) ?? const []).map((e) => (e as Map).cast<String, dynamic>()).toList();
}

class _CalloutBox extends StatelessWidget {
  final String style;
  final String? title;
  final Widget child;
  final ReaderTheme theme;
  final double fontScale;
  const _CalloutBox({required this.style, this.title, required this.child, required this.theme, required this.fontScale});

  Color get _accent => switch (style) {
    'warning' => const Color(0xFFF59E0B),
    'success' => const Color(0xFF10B981),
    'danger' => const Color(0xFFEF4444),
    _ => const Color(0xFF6366F1),
  };

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _accent.withValues(alpha: theme.isDark ? .14 : .08),
        border: Border(left: BorderSide(color: _accent, width: 4)),
        borderRadius: const BorderRadius.horizontal(right: Radius.circular(10)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null && title!.isNotEmpty) ...[
            Text(title!, style: TextStyle(fontWeight: FontWeight.w700, color: _accent, fontSize: 14 * fontScale)),
            const SizedBox(height: 6),
          ],
          child,
        ],
      ),
    );
  }
}

class _Quote extends StatelessWidget {
  final String text;
  final String? author;
  final ReaderTheme theme;
  final double fontScale;
  const _Quote({required this.text, this.author, required this.theme, required this.fontScale});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(color: theme.text.withValues(alpha: .05), borderRadius: BorderRadius.circular(10)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('"$text"', style: TextStyle(fontSize: 16 * fontScale, fontStyle: FontStyle.italic, color: theme.text, height: 1.5)),
          if (author != null && author!.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text('— $author', style: TextStyle(fontSize: 13 * fontScale, fontWeight: FontWeight.w600, color: theme.muted)),
          ],
        ],
      ),
    );
  }
}

class _Figure extends StatelessWidget {
  final String? url;
  final String? caption;
  final ReaderTheme theme;
  final double fontScale;
  const _Figure({this.url, this.caption, required this.theme, required this.fontScale});

  @override
  Widget build(BuildContext context) {
    if (url == null || url!.isEmpty) return const SizedBox.shrink();
    return Column(
      children: [
        GestureDetector(
          onTap: () => showDialog(
            context: context,
            builder: (_) => Dialog(
              backgroundColor: Colors.black,
              insetPadding: const EdgeInsets.all(12),
              child: InteractiveViewer(minScale: 0.5, maxScale: 4, child: Image.network(url!, fit: BoxFit.contain)),
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.network(url!, fit: BoxFit.cover, width: double.infinity,
                errorBuilder: (_, _, _) => const SizedBox.shrink()),
          ),
        ),
        if (caption != null && caption!.isNotEmpty) ...[
          const SizedBox(height: 6),
          Text(caption!, style: TextStyle(fontSize: 12.5 * fontScale, color: theme.muted), textAlign: TextAlign.center),
        ],
      ],
    );
  }
}

class _Timeline extends StatelessWidget {
  final List<Map<String, dynamic>> items;
  final ReaderTheme theme;
  final double fontScale;
  const _Timeline({required this.items, required this.theme, required this.fontScale});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final it in items)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 54,
                  padding: const EdgeInsets.symmetric(vertical: 3),
                  decoration: BoxDecoration(color: const Color(0xFF6366F1).withValues(alpha: .12), borderRadius: BorderRadius.circular(6)),
                  child: Text('${it['year'] ?? ''}', textAlign: TextAlign.center, style: TextStyle(fontSize: 12.5 * fontScale, fontWeight: FontWeight.w700, color: const Color(0xFF6366F1))),
                ),
                const SizedBox(width: 12),
                Expanded(child: Text('${it['text'] ?? ''}', style: TextStyle(fontSize: 14.5 * fontScale, color: theme.text, height: 1.4))),
              ],
            ),
          ),
      ],
    );
  }
}

class _Stats extends StatelessWidget {
  final List<Map<String, dynamic>> items;
  final ReaderTheme theme;
  final double fontScale;
  const _Stats({required this.items, required this.theme, required this.fontScale});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        for (final it in items)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(color: theme.text.withValues(alpha: .05), borderRadius: BorderRadius.circular(10)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${it['value'] ?? ''}', style: TextStyle(fontSize: 18 * fontScale, fontWeight: FontWeight.w800, color: theme.text)),
                Text('${it['label'] ?? ''}', style: TextStyle(fontSize: 12 * fontScale, color: theme.muted)),
              ],
            ),
          ),
      ],
    );
  }
}

class _KeyValue extends StatelessWidget {
  final String? label;
  final String? value;
  final ReaderTheme theme;
  final double fontScale;
  const _KeyValue({this.label, this.value, required this.theme, required this.fontScale});

  @override
  Widget build(BuildContext context) {
    if (value == null || value!.isEmpty) return const SizedBox.shrink();
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: theme.text.withValues(alpha: .04), borderRadius: BorderRadius.circular(10), border: Border.all(color: theme.text.withValues(alpha: .08))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (label != null) ...[
            Text(label!, style: TextStyle(fontSize: 12 * fontScale, fontWeight: FontWeight.w700, color: theme.muted, letterSpacing: .3)),
            const SizedBox(height: 4),
          ],
          Text(value!, style: TextStyle(fontSize: 14.5 * fontScale, color: theme.text, height: 1.5)),
        ],
      ),
    );
  }
}

class _Points extends StatelessWidget {
  final List<Map<String, dynamic>> points;
  final ReaderTheme theme;
  final double fontScale;
  final bool highlight;
  const _Points({required this.points, required this.theme, required this.fontScale, this.highlight = false});

  @override
  Widget build(BuildContext context) {
    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final p in points)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 6, right: 10),
                  child: Container(width: 6, height: 6, decoration: BoxDecoration(color: const Color(0xFF6366F1), shape: BoxShape.circle)),
                ),
                Expanded(child: Text('${p['text'] ?? ''}', style: TextStyle(fontSize: 14.5 * fontScale, color: theme.text, height: 1.45))),
              ],
            ),
          ),
      ],
    );

    if (!highlight) return content;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [const Color(0xFF6366F1).withValues(alpha: .10), const Color(0xFF7C3AED).withValues(alpha: .06)]),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF6366F1).withValues(alpha: .25)),
      ),
      child: content,
    );
  }
}
