import 'dart:math';
import 'package:flutter/material.dart';
import '../theme.dart';

class Block {
  Block({required this.x, required this.width, required this.length, required this.top});

  double x;
  final double width;
  final double length;
  final bool top;

  /// Max length: 40% of screen height, for every block.
  static const maxFraction = 0.4;

  /// Spawns a column: top only, bottom only, or both.
  /// Both <= 0.4 each, so the gap is always >= 20% of the height.
  static List<Block> column(Random r, Size area) {
    final w = area.height * 0.1;
    Block make(bool top) => Block(
      x: area.width,
      width: w,
      length: area.height * (0.15 + r.nextDouble() * (maxFraction - 0.15)),
      top: top,
    );
    switch (r.nextInt(3)) {
      case 0:
        return [make(true)];
      case 1:
        return [make(false)];
      default:
        return [make(true), make(false)];
    }
  }

  Rect rect(double h) => Rect.fromLTWH(x, top ? 0 : h - length, width, length);

  void update(double dt, double speed) => x -= speed * dt;

  bool get gone => x + width < 0;

  void paint(Canvas c, double h) {
    final r = rect(h);
    c.drawRect(r, Paint()..color = C.blue);
    c.drawRect(
      Rect.fromLTWH(r.left + 5, r.top + 3, 6, r.height - 6),
      Paint()..color = C.lightBlue,
    );
    c.drawRect(
      r.deflate(1.5),
      Paint()
        ..color = C.navy
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    );
  }
}