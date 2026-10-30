import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';

Future<ui.Image>? _batImage;

/// Bat.png: 256x64 sheet, 4 frames of 64x64. Loaded once.
Future<ui.Image> loadBatImage() => _batImage ??= () async {
  final data = await rootBundle.load('assets/Bat.png');
  final codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
  return (await codec.getNextFrame()).image;
}();

void paintBatFrame(Canvas c, ui.Image img, Rect dst, double t) {
  final frame = (t * 12).floor() % 4;
  c.drawImageRect(
    img,
    Rect.fromLTWH(frame * 64.0, 0, 64, 64),
    dst,
    Paint()..filterQuality = FilterQuality.none, // keep pixels crisp
  );
}

class Bat {
  Bat(this.area)
      : size = area.height * 0.16,
        x = area.width * 0.2,
        y = area.height / 2;

  final Size area;
  final double size;
  final double x;
  double y;
  double t = 0;

  static const speed = 0.85; // screen heights per second

  /// dir: -1 up, 0 still, 1 down. No gravity, no flap.
  void update(double dt, int dir) {
    t += dt;
    y += dir * area.height * speed * dt;
  }

  /// Smaller than the image so collisions feel fair.
  Rect get hitbox =>
      Rect.fromCenter(center: Offset(x, y), width: size * 0.5, height: size * 0.38);

  void paint(Canvas c, ui.Image img) => paintBatFrame(
      c, img, Rect.fromCenter(center: Offset(x, y), width: size, height: size), t);
}

/// Animated bat for the home screen scene.
class BatSpriteView extends StatefulWidget {
  const BatSpriteView({super.key, this.size = 110});
  final double size;
  @override
  State<BatSpriteView> createState() => _BatSpriteViewState();
}

class _BatSpriteViewState extends State<BatSpriteView>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  final _t = ValueNotifier<double>(0);
  ui.Image? _img;

  @override
  void initState() {
    super.initState();
    loadBatImage().then((i) => mounted ? setState(() => _img = i) : null);
    _ticker = createTicker((d) => _t.value = d.inMicroseconds / 1e6)..start();
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_img == null) return SizedBox.square(dimension: widget.size);
    return CustomPaint(
      size: Size.square(widget.size),
      painter: _P(_img!, _t),
    );
  }
}

class _P extends CustomPainter {
  _P(this.img, this.t) : super(repaint: t);
  final ui.Image img;
  final ValueNotifier<double> t;
  @override
  void paint(Canvas c, Size s) {
    final bob = sin(t.value * 3) * s.height * 0.06;
    paintBatFrame(c, img, Rect.fromLTWH(0, bob, s.width, s.height), t.value);
  }

  @override
  bool shouldRepaint(_P o) => false;
}