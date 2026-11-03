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
    c.drawRect(r, Paint()..color = _blue);
    // light highlight stripe
    c.drawRect(
        Rect.fromLTWH(r.left + 5, r.top, 5, r.height), Paint()..color = _light);
    // dark outline
    c.drawRect(
        r.deflate(1.5),
        Paint()
          ..color = _navy
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3);
  }
}

/// Builds columns around a gap whose center moves from one column to the next.
///
/// The gap is chosen first; the top block fills the space above it and the
/// bottom block the space below it. So the bat can never sit still: the free
/// space is always somewhere new. All sizes are fractions of the height.
class ColumnMaker {
  static const minGap = 0.20; // never smaller than 20% (plan rule)
  static const maxGap = 0.32;
  static const edgeMargin = 0.03; // keep the gap clear of the red edges
  static const widthFrac = 0.15; // block width, as a fraction of the height

  double _prevCenter = 0.5;

  void reset() => _prevCenter = 0.5;

  /// [maxShift]: the farthest the gap center may move since the last column
  /// (fraction of the height), computed from the bat's travel time.
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