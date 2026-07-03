import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

/// Renders rich question content faithfully: HTML (bold/italic/colors, lists,
/// tables, images) plus LaTeX maths and chemistry — the same way it will look
/// in the admin preview.
///
/// Maths is rendered with KaTeX (fast, no server round-trip) and chemistry via
/// the `mhchem` extension (e.g. `\ce{2H2 + O2 -> 2H2O}`). The web view auto-sizes
/// to its content height and passes taps through to the parent (so option tiles
/// stay tappable). KaTeX is loaded from a CDN; for full offline support the
/// assets can be bundled locally later.
class RichContentView extends StatefulWidget {
  final String html;
  final double fontSize;
  final Color color;

  const RichContentView({
    super.key,
    required this.html,
    this.fontSize = 15,
    this.color = const Color(0xFF1F2937),
  });

  @override
  State<RichContentView> createState() => _RichContentViewState();
}

class _RichContentViewState extends State<RichContentView> {
  WebViewController? _controller;
  double _height = 24; // small initial height; grows once content is measured

  // A WebView (KaTeX) is only needed for content with LaTeX maths/chemistry or
  // HTML markup. Plain text — the large majority of question/explanation text —
  // is rendered natively as a Text widget below, so a review list doesn't spawn
  // one heavy native WebView per item (which froze/janked the screen).
  static final _richPattern = RegExp(r'\$|\\\(|\\\[|\\ce\{|<[a-zA-Z/]');
  bool get _isRich => _richPattern.hasMatch(widget.html);

  @override
  void initState() {
    super.initState();
    if (_isRich) _initWebView();
  }

  void _initWebView() {
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0x00000000))
      ..addJavaScriptChannel(
        'FlutterHeight',
        onMessageReceived: (msg) {
          final h = double.tryParse(msg.message);
          if (h != null && mounted && (h - _height).abs() > 1) {
            setState(() => _height = h);
          }
        },
      )
      ..loadHtmlString(_document(widget.html));
  }

  @override
  void didUpdateWidget(covariant RichContentView old) {
    super.didUpdateWidget(old);
    if (old.html == widget.html &&
        old.color == widget.color &&
        old.fontSize == widget.fontSize) {
      return;
    }
    if (_isRich) {
      if (_controller == null) {
        _initWebView();
      } else {
        _controller!.loadHtmlString(_document(widget.html));
      }
    }
  }

  // Decodes the handful of HTML entities that can appear in otherwise-plain
  // text. (&amp; is decoded last so an encoded "&amp;lt;" isn't turned into "<".)
  String _decodeBasicEntities(String s) => s
      .replaceAll('&nbsp;', ' ')
      .replaceAll('&lt;', '<')
      .replaceAll('&gt;', '>')
      .replaceAll('&quot;', '"')
      .replaceAll('&#39;', "'")
      .replaceAll('&apos;', "'")
      .replaceAll('&amp;', '&')
      .trim();

  String _hex(Color c) {
    final argb = c.toARGB32();
    return '#${(argb & 0xFFFFFF).toRadixString(16).padLeft(6, '0')}';
  }

  String _document(String body) {
    // JSON-encode the body so quotes/newlines inside the HTML can't break the doc.
    final safeBody = jsonEncode(body);
    return '''
<!DOCTYPE html>
<html>
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1, maximum-scale=1">
<link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/katex@0.16.9/dist/katex.min.css">
<script defer src="https://cdn.jsdelivr.net/npm/katex@0.16.9/dist/katex.min.js"></script>
<script defer src="https://cdn.jsdelivr.net/npm/katex@0.16.9/dist/contrib/mhchem.min.js"></script>
<script defer src="https://cdn.jsdelivr.net/npm/katex@0.16.9/dist/contrib/auto-render.min.js"></script>
<style>
  html, body { margin:0; padding:0; background:transparent; }
  body {
    font-family: 'Poppins', -apple-system, Roboto, sans-serif;
    font-size: ${widget.fontSize}px;
    color: ${_hex(widget.color)};
    line-height: 1.55;
    word-wrap: break-word;
    overflow: hidden;
  }
  p { margin: 0 0 8px; }
  p:last-child { margin-bottom: 0; }
  img { max-width: 100%; height: auto; border-radius: 6px; }
  table { border-collapse: collapse; margin: 6px 0; }
  th, td { border: 1px solid #cbd5e1; padding: 4px 8px; }
  pre, code { background: #f1f5f9; border-radius: 4px; padding: 1px 4px; }
</style>
</head>
<body>
<div id="content"></div>
<script>
  document.getElementById('content').innerHTML = $safeBody;
  function report() {
    if (window.FlutterHeight) {
      FlutterHeight.postMessage(String(document.body.scrollHeight));
    }
  }
  function renderAll() {
    try {
      renderMathInElement(document.body, {
        delimiters: [
          {left: '\$\$', right: '\$\$', display: true},
          {left: '\$',   right: '\$',   display: false},
          {left: '\\\\(', right: '\\\\)', display: false},
          {left: '\\\\[', right: '\\\\]', display: true}
        ],
        throwOnError: false
      });
    } catch (e) {}
    report();
  }
  window.addEventListener('load', renderAll);
  window.addEventListener('resize', report);
  // images / fonts may finish after load — re-measure a couple of times
  setTimeout(report, 400);
  setTimeout(report, 1200);
</script>
</body>
</html>
''';
  }

  @override
  Widget build(BuildContext context) {
    // Fast path: plain text renders natively — no WebView, no CDN round-trip.
    if (!_isRich) {
      return Text(
        _decodeBasicEntities(widget.html),
        style: TextStyle(
          fontFamily: 'Poppins',
          fontSize: widget.fontSize,
          color: widget.color,
          height: 1.55,
        ),
      );
    }

    return SizedBox(
      height: _height,
      child: WebViewWidget(
        controller: _controller!,
        // Empty set → the web view doesn't claim gestures, so a parent InkWell
        // (e.g. an option tile) still receives taps.
        gestureRecognizers: const <Factory<OneSequenceGestureRecognizer>>{},
      ),
    );
  }
}
