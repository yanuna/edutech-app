import 'package:flutter/material.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import 'package:html/dom.dart' as dom;

/// Renders admin-authored HTML content with the "Universal HTML Styles" look —
/// automatically, without any CSS embedded in the content itself.
///
/// This mirrors the backend default stylesheet (`resources/css/uhs-default.css`):
/// styled headings, paragraphs, lists, tables, blockquotes, code blocks, links,
/// horizontal rules and callout boxes (`.note` / `.tip` / `.important` /
/// `.warning` / `.alert` / `.example` / `.formula`). It is fully theme-aware —
/// colours come from the current [Theme] brightness, so light & dark both look
/// right with the same HTML.
///
/// Rendering uses `flutter_widget_from_html` (never a WebView) so even very large
/// topic documents (100 KB+) lay out lazily and never crash the render thread —
/// the reason the app standardised on fwfh for content. For questions that need
/// LaTeX/chemistry, use [RichContentView] instead.
class StyledHtmlView extends StatelessWidget {
  final String html;

  /// Defaults to lazy [RenderMode.listView] when this view is the whole scrolling
  /// body, or [RenderMode.column] when embedded inside another list/column.
  final RenderMode renderMode;

  final double fontSize;

  const StyledHtmlView(
    this.html, {
    super.key,
    this.renderMode = RenderMode.column,
    this.fontSize = 16,
  });

  @override
  Widget build(BuildContext context) {
    final palette = _UhsPalette(Theme.of(context).brightness == Brightness.dark);
    return _render(html, palette, renderMode: renderMode);
  }

  Widget _render(String content, _UhsPalette p, {RenderMode renderMode = RenderMode.column}) {
    return HtmlWidget(
      content,
      renderMode: renderMode,
      textStyle: TextStyle(
        fontFamily: 'Poppins',
        fontSize: fontSize,
        height: 1.7,
        color: p.fg,
      ),
      customStylesBuilder: (e) => _stylesFor(e, p),
      customWidgetBuilder: (e) => _widgetFor(e, p),
    );
  }

  // ── Per-element inline styles (CSS subset fwfh understands) ──────────────
  Map<String, String>? _stylesFor(dom.Element e, _UhsPalette p) {
    final cls = e.classes;

    // Class-based styles for rich "notes" content — mirrors the backend
    // "UPSC Master-Notes Components" stylesheet. (Timeline + callout boxes are
    // handled by real widgets in _widgetFor.)
    if (cls.contains('highlight')) {
      return {'background-color': p.hex(p.accentSoft), 'color': p.hex(p.fg), 'font-weight': '600'};
    }
    if (cls.contains('header-section')) {
      return {'text-align': 'center', 'border-bottom': '3px solid ${p.hex(p.accent)}', 'padding-bottom': '12px', 'margin-bottom': '18px'};
    }
    if (cls.contains('footer-note')) {
      return {'text-align': 'center', 'color': p.hex(p.muted), 'font-size': '13px', 'margin-top': '24px', 'padding-top': '12px', 'border-top': '1px solid ${p.hex(p.border)}'};
    }
    if (cls.contains('image-container')) {
      return {'text-align': 'center', 'margin': '16px 0'};
    }
    if (cls.contains('image-caption')) {
      return {'text-align': 'center', 'font-style': 'italic', 'color': p.hex(p.muted), 'font-size': '13px'};
    }
    if (cls.contains('math')) {
      return {'background-color': p.hex(p.accentSoft), 'border': '1px solid ${p.hex(p.border)}', 'padding': '10px 14px', 'text-align': 'center', 'font-family': 'serif'};
    }

    switch (e.localName) {
      case 'h1':
        return {'color': p.hex(p.fg), 'font-size': '26px', 'font-weight': '700', 'margin': '18px 0 8px'};
      case 'h2':
        // .section-title: accent colour + left bar instead of the bottom rule.
        if (cls.contains('section-title')) {
          return {'color': p.hex(p.accent), 'font-size': '22px', 'font-weight': '700', 'margin': '18px 0 8px', 'border-left': '5px solid ${p.hex(p.accent)}', 'padding-left': '10px'};
        }
        return {'color': p.hex(p.fg), 'font-size': '22px', 'font-weight': '700', 'margin': '18px 0 8px', 'border-bottom': '2px solid ${p.hex(p.border)}', 'padding-bottom': '4px'};
      case 'h3':
        return {'color': p.hex(p.fg), 'font-size': '19px', 'font-weight': '700', 'margin': '16px 0 6px'};
      case 'h4':
        return {'color': p.hex(p.fg), 'font-size': '17px', 'font-weight': '700', 'margin': '14px 0 6px'};
      case 'h5':
      case 'h6':
        return {'color': p.hex(p.muted), 'font-size': '14px', 'font-weight': '700', 'margin': '12px 0 4px'};
      case 'a':
        return {'color': p.hex(p.link)};
      case 'th':
        return {'background-color': p.hex(p.tableHead), 'font-weight': '700', 'padding': '6px 10px', 'border': '1px solid ${p.hex(p.border)}', 'text-align': 'left'};
      case 'td':
        return {'padding': '6px 10px', 'border': '1px solid ${p.hex(p.border)}', 'text-align': 'left'};
      case 'code':
        // Inline code only — <pre><code> is handled by the widget builder below.
        if (e.parent?.localName == 'pre') return null;
        return {'background-color': p.hex(p.codeBg), 'color': p.hex(p.codeFg), 'font-family': 'monospace'};
      case 'mark':
        return {'background-color': '#fef08a', 'color': '#1f2933'};
      case 'small':
        return {'color': p.hex(p.muted), 'font-size': '13px'};
      default:
        return null;
    }
  }

  // ── Elements that need a real widget (boxes, code, quotes) ───────────────
  Widget? _widgetFor(dom.Element e, _UhsPalette p) {
    final classes = e.classes;

    // Timeline: <div class="timeline"> with <div class="timeline-item"> children,
    // each holding .timeline-date / .timeline-title / .timeline-desc. Rendered as
    // a real dot-and-line timeline (CSS ::before dots can't be done in fwfh).
    if (e.localName == 'div' && classes.contains('timeline')) {
      final items = e.children.where((c) => c.classes.contains('timeline-item')).toList();
      if (items.isEmpty) return null;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (int i = 0; i < items.length; i++)
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _timelineRail(p, isLast: i == items.length - 1),
                  const SizedBox(width: 12),
                  Expanded(child: _timelineBody(items[i], p)),
                ],
              ),
            ),
        ],
      );
    }

    // Callout boxes: <div class="note|tip|important|warning|alert|example|
    // formula|callout|upsc-alert|debate-box">
    final callout = _calloutColor(classes, p);
    if (e.localName == 'div' && callout != null) {
      return Container(
        width: double.infinity,
        margin: const EdgeInsets.symmetric(vertical: 10),
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        decoration: BoxDecoration(
          color: callout.bg,
          border: Border(left: BorderSide(color: callout.bar, width: 4)),
          borderRadius: const BorderRadius.horizontal(right: Radius.circular(8)),
        ),
        child: _render(e.innerHtml, p),
      );
    }

    // Blockquote → left-bar card.
    if (e.localName == 'blockquote') {
      return Container(
        width: double.infinity,
        margin: const EdgeInsets.symmetric(vertical: 10),
        padding: const EdgeInsets.fromLTRB(14, 8, 14, 8),
        decoration: BoxDecoration(
          color: p.accentSoft,
          border: Border(left: BorderSide(color: p.accent, width: 4)),
          borderRadius: const BorderRadius.horizontal(right: Radius.circular(8)),
        ),
        child: DefaultTextStyle.merge(
          style: TextStyle(fontStyle: FontStyle.italic, color: p.muted),
          child: _render(e.innerHtml, p),
        ),
      );
    }

    // Code block: <pre> → dark, horizontally scrollable, monospace.
    if (e.localName == 'pre') {
      return Container(
        width: double.infinity,
        margin: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: p.preBg,
          borderRadius: BorderRadius.circular(10),
        ),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.all(14),
          child: SelectableText(
            e.text,
            style: TextStyle(fontFamily: 'monospace', fontSize: 13.5, height: 1.5, color: p.preFg),
          ),
        ),
      );
    }

    // Wide tables scroll horizontally instead of overflowing.
    if (e.localName == 'table') {
      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: _TableShell(html: e.outerHtml, palette: p, fontSize: fontSize),
      );
    }

    return null;
  }

  _CalloutStyle? _calloutColor(Set<String> classes, _UhsPalette p) {
    if (classes.contains('note')) return _CalloutStyle(p.bnote, const Color(0xFF3B82F6));
    if (classes.contains('tip')) return _CalloutStyle(p.btip, const Color(0xFF10B981));
    if (classes.contains('important')) return _CalloutStyle(p.bimportant, const Color(0xFF8B5CF6));
    if (classes.contains('warning')) return _CalloutStyle(p.bwarning, const Color(0xFFF59E0B));
    if (classes.contains('alert')) return _CalloutStyle(p.balert, const Color(0xFFEF4444));
    if (classes.contains('example')) return _CalloutStyle(p.bexample, const Color(0xFF0EA5E9));
    if (classes.contains('upsc-alert')) return _CalloutStyle(p.accentSoft, p.accent);
    if (classes.contains('debate-box')) return _CalloutStyle(p.bdebate, const Color(0xFFD97706));
    if (classes.contains('formula') || classes.contains('callout')) {
      return _CalloutStyle(p.accentSoft, p.accent);
    }
    return null;
  }

  // ── Timeline helpers ─────────────────────────────────────────────────────
  Widget _timelineRail(_UhsPalette p, {required bool isLast}) {
    return Column(
      children: [
        Container(
          width: 14,
          height: 14,
          margin: const EdgeInsets.only(top: 4),
          decoration: BoxDecoration(
            color: p.accent,
            shape: BoxShape.circle,
            border: Border.all(color: p.accentSoft, width: 3),
          ),
        ),
        if (!isLast) Expanded(child: Container(width: 2, color: p.border)),
      ],
    );
  }

  Widget _timelineBody(dom.Element item, _UhsPalette p) {
    final date = item.querySelector('.timeline-date')?.text.trim() ?? '';
    final title = item.querySelector('.timeline-title')?.text.trim() ?? '';
    final descEl = item.querySelector('.timeline-desc');
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (date.isNotEmpty)
            Align(
              alignment: Alignment.centerLeft,
              child: Container(
                margin: const EdgeInsets.only(bottom: 4),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                  color: p.accent,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  date,
                  style: const TextStyle(
                    color: Colors.white,
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          if (title.isNotEmpty)
            Text(
              title,
              style: TextStyle(
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w700,
                fontSize: 15,
                color: p.fg,
              ),
            ),
          if (descEl != null) _render(descEl.innerHtml, p),
        ],
      ),
    );
  }
}

/// A <table> rendered without re-triggering the outer table widget-builder
/// (which would recurse). fwfh renders the table natively here.
class _TableShell extends StatelessWidget {
  final String html;
  final _UhsPalette palette;
  final double fontSize;
  const _TableShell({required this.html, required this.palette, required this.fontSize});

  @override
  Widget build(BuildContext context) {
    return HtmlWidget(
      html,
      renderMode: RenderMode.column,
      textStyle: TextStyle(fontFamily: 'Poppins', fontSize: fontSize, height: 1.5, color: palette.fg),
      customStylesBuilder: (e) {
        switch (e.localName) {
          case 'th':
            return {'background-color': palette.hex(palette.tableHead), 'font-weight': '700', 'padding': '6px 10px', 'border': '1px solid ${palette.hex(palette.border)}', 'text-align': 'left'};
          case 'td':
            return {'padding': '6px 10px', 'border': '1px solid ${palette.hex(palette.border)}', 'text-align': 'left'};
          default:
            return null;
        }
      },
    );
  }
}

class _CalloutStyle {
  final Color bg;
  final Color bar;
  const _CalloutStyle(this.bg, this.bar);
}

/// Colour tokens mirroring `resources/css/uhs-default.css` for light & dark.
class _UhsPalette {
  final bool dark;
  const _UhsPalette(this.dark);

  Color get fg => dark ? const Color(0xFFE5E7EB) : const Color(0xFF1F2933);
  Color get muted => dark ? const Color(0xFF9CA3AF) : const Color(0xFF52606D);
  Color get accent => dark ? const Color(0xFFA5B4FC) : const Color(0xFF4F46E5);
  Color get accentSoft => dark ? const Color(0xFF1E253B) : const Color(0xFFEEF2FF);
  Color get border => dark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);
  Color get link => dark ? const Color(0xFFA5B4FC) : const Color(0xFF4338CA);
  Color get tableHead => dark ? const Color(0xFF1F2A3A) : const Color(0xFFF1F5F9);
  Color get codeBg => dark ? const Color(0xFF24304A) : const Color(0xFFF4F4F5);
  Color get codeFg => dark ? const Color(0xFFFCA5A5) : const Color(0xFFB91C1C);
  Color get preBg => dark ? const Color(0xFF0B1220) : const Color(0xFF1E293B);
  Color get preFg => const Color(0xFFE2E8F0);

  // Callout backgrounds
  Color get bnote => dark ? const Color(0xFF10203A) : const Color(0xFFEFF6FF);
  Color get btip => dark ? const Color(0xFF06281F) : const Color(0xFFECFDF5);
  Color get bimportant => dark ? const Color(0xFF1E163A) : const Color(0xFFF5F3FF);
  Color get bwarning => dark ? const Color(0xFF2A2008) : const Color(0xFFFFFBEB);
  Color get balert => dark ? const Color(0xFF2A1010) : const Color(0xFFFEF2F2);
  Color get bexample => dark ? const Color(0xFF06202F) : const Color(0xFFF0F9FF);
  Color get bdebate => dark ? const Color(0xFF2A1D08) : const Color(0xFFFFF7ED);

  String hex(Color c) {
    final argb = c.toARGB32();
    return '#${(argb & 0xFFFFFF).toRadixString(16).padLeft(6, '0')}';
  }
}
