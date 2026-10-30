import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import '../component/bat.dart';
import '../component/block.dart';
import '../data/db.dart';
import '../theme.dart';
import '../widgets/pixel_widgets.dart';
import '../widgets/user_switcher.dart';

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});
  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen>
    with SingleTickerProviderStateMixin {
  // Tuning (open items in PLAN.md)
  static const blockSpeed = 0.42; // screen widths per second
  static const spawnEvery = 1.5; // seconds between columns
  static const scorePerSecond = 50;

  late final Ticker _ticker;
  final _repaint = ValueNotifier<int>(0);
  final _rnd = Random();
  ui.Image? _img;

  Size _area = Size.zero;
  Bat? _bat;
  final List<Block> _blocks = [];
  bool _up = false, _down = false, _over = false;
  double _elapsed = 0, _spawnIn = 1;
  Duration _last = Duration.zero;
  int _score = 0, _bestAtStart = 0;

  @override
  void initState() {
    super.initState();
    loadBatImage().then((i) => mounted ? setState(() => _img = i) : null);
    _ticker = createTicker(_tick)..start();
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  void _reset() {
    _bat = Bat(_area);
    _blocks.clear();
    _elapsed = 0;
    _spawnIn = 1;
    _score = 0;
    _over = false;
    _up = _down = false;
    _bestAtStart = session.current.best;
    _ticker.muted = false;
  }

  void _tick(Duration d) {
    final dt = ((d - _last).inMicroseconds / 1e6).clamp(0.0, 0.05);
    _last = d;
    final bat = _bat;
    if (bat == null || _over || _ticker.muted || _img == null) return;

    _elapsed += dt;
    bat.update(dt, (_down ? 1 : 0) - (_up ? 1 : 0));

    _spawnIn -= dt;
    if (_spawnIn <= 0) {
      _blocks.addAll(Block.column(_rnd, _area));
      _spawnIn = spawnEvery;
    }
    for (final b in _blocks) {
      b.update(dt, _area.width * blockSpeed);
    }
    _blocks.removeWhere((b) => b.gone);

    final hit = bat.hitbox;
    final dead = hit.top <= 0 ||
        hit.bottom >= _area.height ||
        _blocks.any((b) => b.rect(_area.height).overlaps(hit));

    final newScore = (_elapsed * scorePerSecond).floor();
    _repaint.value++;
    if (dead) {
      _over = true;
      session.submitScore(_score);
      setState(() {});
    } else if (newScore != _score) {
      setState(() => _score = newScore);
    }
  }

  bool get _pastBest => _bestAtStart > 0 && _score > _bestAtStart;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: C.slate,
      body: Stack(children: [
        SafeArea(
          child: Row(children: [
            // Left panel: score + Up
            SizedBox(
              width: 150,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('SCORE', style: pixel(9)),
                  const SizedBox(height: 6),
                  Text('$_score',
                      style: pixel(20, color: _pastBest ? C.green : C.navy)),
                  if (_pastBest) ...[
                    const SizedBox(height: 6),
                    Text('PAST BEST!', style: pixel(8, color: C.green)),
                  ],
                  const SizedBox(height: 6),
                  Text('BEST ${max(session.current.best, 0)}', style: body(20)),
                  const Spacer(),
                  Center(
                    child: HoldButton(
                        icon: Icons.keyboard_arrow_up, onChanged: (v) => _up = v),
                  ),
                ]),
              ),
            ),
            // Play area
            Expanded(
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  border: Border.symmetric(
                      vertical: BorderSide(color: C.navy, width: 3)),
                ),
                child: LayoutBuilder(builder: (_, box) {
                  final size = Size(box.maxWidth, box.maxHeight);
                  if (size != _area) {
                    _area = size;
                    _reset();
                  }
                  return CustomPaint(
                    size: size,
                    painter: _GamePainter(_bat, _blocks, _img, _repaint),
                  );
                }),
              ),
            ),
            // Right panel: user switcher + Down
            SizedBox(
              width: 150,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(children: [
                  Align(
                    alignment: Alignment.centerRight,
                    child: UserSwitcher(
                      onOpen: () => _ticker.muted = true,
                      onClose: (changed) {
                        if (changed && _area != Size.zero) {
                          setState(_reset);
                        } else if (!_over) {
                          _ticker.muted = false;
                        }
                      },
                    ),
                  ),
                  const Spacer(),
                  HoldButton(
                      icon: Icons.keyboard_arrow_down, onChanged: (v) => _down = v),
                ]),
              ),
            ),
          ]),
        ),
        if (_over) _GameOver(
          score: _score,
          onRestart: () => setState(_reset),
          onHome: () => Navigator.pop(context),
        ),
      ]),
    );
  }
}

class _GamePainter extends CustomPainter {
  _GamePainter(this.bat, this.blocks, this.img, Listenable repaint)
      : super(repaint: repaint);
  final Bat? bat;
  final List<Block> blocks;
  final ui.Image? img;

  @override
  void paint(Canvas c, Size s) {
    c.drawRect(Offset.zero & s, Paint()..color = Colors.white);
    for (final b in blocks) {
      b.paint(c, s.height);
    }
    // Danger edges: touching them ends the game.
    final red = Paint()..color = C.red;
    c.drawRect(Rect.fromLTWH(0, 0, s.width, 6), red);
    c.drawRect(Rect.fromLTWH(0, s.height - 6, s.width, 6), red);
    if (bat != null && img != null) bat!.paint(c, img!);
  }

  @override
  bool shouldRepaint(_GamePainter o) => o.bat != bat || o.img != img;
}

class _GameOver extends StatelessWidget {
  const _GameOver({required this.score, required this.onRestart, required this.onHome});
  final int score;
  final VoidCallback onRestart, onHome;

  @override
  Widget build(BuildContext context) => Positioned.fill(
    child: Container(
      color: C.navy.withOpacity(0.78),
      alignment: Alignment.center,
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Text('GAME OVER', style: pixel(26, color: Colors.white)),
        const SizedBox(height: 14),
        Text('SCORE $score', style: pixel(14, color: Colors.white)),
        const SizedBox(height: 28),
        Row(mainAxisSize: MainAxisSize.min, children: [
          PixelButton(icon: Icons.replay, color: C.red, onTap: onRestart),
          const SizedBox(width: 24),
          PixelButton(
              icon: Icons.home,
              color: Colors.white,
              textColor: C.navy,
              onTap: onHome),
        ]),
      ]),
    ),
  );
}