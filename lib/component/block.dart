import 'dart:math';
import 'package:flutter/material.dart';

/// One blue block, attached to the top or the bottom edge of the play area.
class Block {
  Block({
    required this.x,
    required this.width,
    required this.fromTop,
    required this.lengthFrac,
  });

  double x; // left edge, in pixels
  final double width; // in pixels
  final bool fromTop;
  final double lengthFrac; // fraction of the play-area height

  static const _blue = Color(0xFF2563EB);
  static const _navy = Color(0xFF0F172A);
  static const _light = Color(0xFF93C5FD);

  bool get gone => x + width < 0;

  void update(double dt, double pxPerSecond) => x -= pxPerSecond * dt;

  Rect rect(double height) {
    final len = lengthFrac * height;
    return fromTop
        ? Rect.fromLTWH(x, 0, width, len)
        : Rect.fromLTWH(x, height - len, width, len);
  }

  void paint(Canvas c, double height) {
    final r = rect(height);

    // Body with rounded corners (radius 6, like the home page)
    final body = RRect.fromRectAndRadius(r, const Radius.circular(6));
    c.drawRRect(body, Paint()..color = _blue);

    // Light stripe: 8px from the left, 6px wide, 80% of the inner height,
    // centered vertically, rounded ends.
    final innerH = r.height - 6;
    final stripeH = innerH * 0.8;
    final stripe = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        r.left + 8,
        r.top + 3 + (innerH - stripeH) / 2,
        6,
        stripeH,
      ),
      const Radius.circular(3),
    );
    c.drawRRect(stripe, Paint()..color = _light);

    // Navy outline, drawn inside the edge like Border.all
    c.drawRRect(
      body.deflate(1.5),
      Paint()
        ..color = _navy
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    );
  }
} // <-- this closing brace was missing

/// Builds columns around a gap whose center moves from one column to the next.
class ColumnMaker {
  static const minGap = 0.20;
  static const maxGap = 0.32;
  static const edgeMargin = 0.03;
  static const widthFrac = 0.15;

  double _prevCenter = 0.5;

  void reset() => _prevCenter = 0.5;

  List<Block> make(Random rnd, Size area, double maxShift) {
    final gap = minGap + rnd.nextDouble() * (maxGap - minGap);
    final lo = gap / 2 + edgeMargin;
    final hi = 1 - gap / 2 - edgeMargin;
    final shift = (rnd.nextDouble() * 2 - 1) * maxShift;
    final center = (_prevCenter + shift).clamp(lo, hi).toDouble();
    _prevCenter = center;

    final topLen = center - gap / 2;
    final bottomLen = 1 - center - gap / 2;
    final w = area.height * widthFrac;
    return [
      Block(x: area.width, width: w, fromTop: true, lengthFrac: topLen),
      Block(x: area.width, width: w, fromTop: false, lengthFrac: bottomLen),
    ];
  }
}