import 'package:flutter/material.dart';

/// A faint, repeating diagonal watermark (e.g. the signed-in user's email) tiled
/// across a secure document viewer. Best-effort deterrent against off-device
/// captures (photographing the screen, web/desktop where FLAG_SECURE can't
/// apply). Always wrap in [IgnorePointer] so it never eats viewer gestures.
class SecureWatermark extends StatelessWidget {
  final String text;
  const SecureWatermark(this.text, {super.key});

  @override
  Widget build(BuildContext context) => IgnorePointer(
        child: CustomPaint(
          size: Size.infinite,
          painter: _WatermarkPainter(text),
        ),
      );
}

class _WatermarkPainter extends CustomPainter {
  final String text;
  _WatermarkPainter(this.text);

  @override
  void paint(Canvas canvas, Size size) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: Colors.grey.withValues(alpha: 0.14),
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    const gapX = 220.0;
    const gapY = 140.0;
    for (double y = 0; y < size.height + gapY; y += gapY) {
      for (double x = -gapX; x < size.width + gapX; x += gapX) {
        canvas.save();
        canvas.translate(x, y);
        canvas.rotate(-0.5);
        tp.paint(canvas, Offset.zero);
        canvas.restore();
      }
    }
  }

  @override
  bool shouldRepaint(covariant _WatermarkPainter old) => old.text != text;
}
