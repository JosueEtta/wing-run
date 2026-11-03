import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../component/bat.dart';
import '../data/db.dart';
import '../theme.dart';
import '../widgets/add_user_dialog.dart';
import '../widgets/user_switcher.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'game_screen.dart';

const _yellow = Color(0xFFFACC15);
const _lightBlue = Color(0xFF93C5FD);

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  /// Slow loop (4 s) that drives the floating bat and the bobbing blocks.
  late final AnimationController _float =
  AnimationController(vsync: this, duration: const Duration(seconds: 4));

  @override
  @override
  void initState() {
    super.initState();
    // Remove the splash once the first frame is drawn, then check first launch.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      FlutterNativeSplash.remove();
      _askNameOnFirstLaunch();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Animations respect the reduced-motion setting.
    if (MediaQuery.disableAnimationsOf(context)) {
      _float.stop();
      _float.value = 0;
    } else if (!_float.isAnimating) {
      _float.repeat();
    }
  }

  @override
  void dispose() {
    _float.dispose();
    super.dispose();
  }

  /// First launch = no user in the database yet.
  Future<void> _askNameOnFirstLaunch() async {
    if (!mounted || session.users.isNotEmpty) return;
    final name = await showAddUserDialog(context, first: true);
    if (name == null) return;
    await session.addUser(name);
  }

  /// The round + button.
  Future<void> _addUser() async {
    final name = await showAddUserDialog(context);
    if (name == null) return;
    await session.addUser(name);
  }

  void _openLeaderboard() {
    showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Close leaderboard',
      barrierColor: const Color(0x800F172A),
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (_, __, ___) => const _LeaderboardPanel(),
      transitionBuilder: (context, anim, _, child) {
        if (MediaQuery.disableAnimationsOf(context)) return child;
        final scale = Tween<double>(begin: 0.92, end: 1).animate(
          CurvedAnimation(
            parent: anim,
            curve: Curves.easeOutBack,
            reverseCurve: Curves.easeIn,
          ),
        );
        return FadeTransition(
          opacity: anim,
          child: ScaleTransition(scale: scale, child: child),
        );
      },
    );
  }

  void _play() {
    // Safety net: never open the game without a user.
    if (session.users.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Create a user first, then press Play.')),
      );
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const GameScreen()),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: Colors.white,
    // The Add User dialog handles the keyboard itself. Without this line the
    // home screen shrinks behind it and overflows in landscape.
    resizeToAvoidBottomInset: false,
    body: Stack(children: [
      // Blue blocks hang from the top and rise from the bottom.
      Positioned.fill(child: IgnorePointer(child: _BlockDecor(t: _float))),
      SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(children: [
            // Top right: + / username / trophy
            Row(mainAxisAlignment: MainAxisAlignment.end, children: [
              _Pressable(
                label: 'Add user',
                circle: true,
                size: 48,
                color: C.blue,
                onTap: _addUser,
                child: const Icon(Icons.add, color: Colors.white, size: 28),
              ),
              const SizedBox(width: 14),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 190),
                child: UserSwitcher(),
              ),
              const SizedBox(width: 14),
              _Pressable(
                label: 'Leaderboard',
                circle: true,
                size: 48,
                color: _yellow,
                onTap: _openLeaderboard,
                child: Icon(Icons.emoji_events, color: C.navy, size: 26),
              ),
            ]),
            // Center: title, bat, Start game
            Expanded(
              child: Center(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    Text(
                      'WING RUN',
                      style: TextStyle(
                        fontSize: 46,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 2,
                        color: C.navy,
                      ),
                    ),
                    const SizedBox(height: 6),
                    AnimatedBuilder(
                      animation: _float,
                      builder: (_, child) => Transform.translate(
                        offset: Offset(
                            0, math.sin(_float.value * 2 * math.pi) * 6),
                        child: child,
                      ),
                      child: const BatSpriteView(size: 110),
                    ),
                    const SizedBox(height: 14),
                    _Pressable(
                      label: 'Start game',
                      color: C.red,
                      onTap: _play,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 34, vertical: 14),
                      child: const Row(mainAxisSize: MainAxisSize.min, children: [
                        Icon(Icons.play_arrow, color: Colors.white, size: 30),
                        SizedBox(width: 8),
                        Text(
                          'START GAME',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.5,
                            color: Colors.white,
                          ),
                        ),
                      ]),
                    ),
                  ]),
                ),
              ),
            ),
          ]),
        ),
      ),
    ]),
  );
}

/// A flat button that grows a little on hover and shrinks when pressed.
class _Pressable extends StatefulWidget {
  const _Pressable({
    required this.label,
    required this.color,
    required this.onTap,
    required this.child,
    this.circle = false,
    this.size,
    this.padding,
  });

  final String label;
  final Color color;
  final VoidCallback onTap;
  final Widget child;
  final bool circle;
  final double? size;
  final EdgeInsetsGeometry? padding;

  @override
  State<_Pressable> createState() => _PressableState();
}

class _PressableState extends State<_Pressable> {
  bool _down = false, _hover = false;

  @override
  Widget build(BuildContext context) {
    final reduce = MediaQuery.disableAnimationsOf(context);
    // No shadow: the button shrinks a little when pressed and grows on hover.
    final scale = _down ? 0.94 : (_hover ? 1.05 : 1.0);
    return Semantics(
      button: true,
      label: widget.label,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hover = true),
        onExit: (_) => setState(() => _hover = false),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: (_) => setState(() => _down = true),
          onTapUp: (_) => setState(() => _down = false),
          onTapCancel: () => setState(() => _down = false),
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: reduce ? Duration.zero : const Duration(milliseconds: 110),
            curve: Curves.easeOut,
            width: widget.size,
            height: widget.size,
            padding: widget.padding,
            alignment: Alignment.center,
            transformAlignment: Alignment.center,
            transform: Matrix4.diagonal3Values(scale, scale, 1),
            decoration: BoxDecoration(
              color: widget.color,
              shape: widget.circle ? BoxShape.circle : BoxShape.rectangle,
              borderRadius: widget.circle ? null : BorderRadius.circular(16),
              border: Border.all(color: C.navy, width: 3),
            ),
            child: widget.child,
          ),
        ),
      ),
    );
  }
}

/// Decoration: blocks anchored to the top and bottom edges that slowly bob.
class _BlockDecor extends StatelessWidget {
  const _BlockDecor({required this.t});
  final Animation<double> t;

  // x position (fraction of the width), from the top?, height, phase.
  // Top blocks stay on the left so the top-right buttons stay clear.
  static const _specs = [
    (0.05, true, 70.0, 0.0),
    (0.15, true, 110.0, 0.3),
    (0.30, true, 56.0, 0.6),
    (0.09, false, 90.0, 0.5),
    (0.24, false, 60.0, 0.15),
    (0.72, false, 80.0, 0.8),
    (0.84, false, 120.0, 0.4),
    (0.93, false, 64.0, 0.1),
  ];

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (_, box) => AnimatedBuilder(
      animation: t,
      builder: (_, __) => Stack(children: [
        for (final (fx, fromTop, h, phase) in _specs)
          Positioned(
            left: fx * box.maxWidth,
            top: fromTop ? 0 : null,
            bottom: fromTop ? null : 0,
            // The height changes, so the block stays attached to its edge.
            child: _Block(
              width: 38,
              height: h + math.sin((t.value + phase) * 2 * math.pi) * 6,
            ),
          ),
      ]),
    ),
  );
}

class _Block extends StatelessWidget {
  const _Block({required this.width, required this.height});
  final double width, height;

  @override
  Widget build(BuildContext context) => Container(
    width: width,
    height: height,
    decoration: BoxDecoration(
      color: C.blue,
      borderRadius: BorderRadius.circular(6),
      border: Border.all(color: C.navy, width: 3),
    ),
    child: Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.only(left: 5),
        child: FractionallySizedBox(
          heightFactor: 0.8,
          child: Container(
            width: 6,
            decoration: BoxDecoration(
              color: _lightBlue,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
        ),
      ),
    ),
  );
}

/// The leaderboard opened by the trophy: rows slide in one after the other.
class _LeaderboardPanel extends StatefulWidget {
  const _LeaderboardPanel();

  @override
  State<_LeaderboardPanel> createState() => _LeaderboardPanelState();
}

class _LeaderboardPanelState extends State<_LeaderboardPanel>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl =
  AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    if (MediaQuery.disableAnimationsOf(context)) {
      _ctrl.value = 1;
    } else {
      _ctrl.forward();
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Widget _row(int i, AppUser u) {
    final me = u.id == session.currentId;
    final medal = [C.gold, C.silver, C.bronze];
    // Each row starts a little after the previous one.
    final start = math.min(i * 0.07, 0.55);
    final interval = Interval(start, start + 0.4, curve: Curves.easeOutCubic);
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, child) {
        final v = interval.transform(_ctrl.value);
        return Opacity(
          opacity: v,
          child: Transform.translate(offset: Offset(24 * (1 - v), 0), child: child),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 6),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
        decoration: BoxDecoration(
          color: me ? C.highlight : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: me ? C.navy : const Color(0xFFE2E8F0), width: me ? 3 : 2),
        ),
        child: Row(children: [
          Container(
            width: 32,
            height: 32,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: i < 3 ? medal[i] : Colors.transparent,
              border: Border.all(
                  color: i < 3 ? C.navy : Colors.transparent, width: 2),
            ),
            child: Text('${i + 1}',
                style: TextStyle(
                    fontSize: 15, fontWeight: FontWeight.w900, color: C.navy)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(u.name,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                    fontSize: 18, fontWeight: FontWeight.w700, color: C.navy)),
          ),
          Text('${u.best}',
              style: TextStyle(
                  fontSize: 18, fontWeight: FontWeight.w900, color: C.navy)),
        ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final maxHeight = MediaQuery.sizeOf(context).height - 40;
    const label = TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w800,
        letterSpacing: 1,
        color: Color(0xFF64748B));
    return Center(
      child: Material(
        color: Colors.transparent,
        child: Container(
          width: 380,
          constraints: BoxConstraints(maxHeight: maxHeight),
          decoration: BoxDecoration(
            color: C.slate,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: C.navy, width: 3),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.fromLTRB(14, 8, 6, 8),
                decoration: BoxDecoration(
                  border: Border(bottom: BorderSide(color: C.navy, width: 3)),
                ),
                child: Row(children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: _yellow,
                      shape: BoxShape.circle,
                      border: Border.all(color: C.navy, width: 3),
                    ),
                    child: Icon(Icons.emoji_events, size: 20, color: C.navy),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text('Leaderboard',
                        style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            color: C.navy)),
                  ),
                  IconButton(
                    tooltip: 'Close',
                    icon: Icon(Icons.close, color: C.navy),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ]),
              ),
              // Column labels
              const Padding(
                padding: EdgeInsets.fromLTRB(22, 10, 22, 6),
                child: Row(children: [
                  SizedBox(width: 44, child: Text('RANK', style: label)),
                  Expanded(child: Text('PLAYER', style: label)),
                  Text('SCORE', style: label),
                ]),
              ),
              Flexible(
                child: ListenableBuilder(
                  listenable: session,
                  builder: (_, __) {
                    final users = session.users; // already sorted best DESC
                    if (users.isEmpty) {
                      return const Padding(
                        padding: EdgeInsets.all(24),
                        child: Text('No players yet.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.w700)),
                      );
                    }
                    return ListView.builder(
                      shrinkWrap: true,
                      padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
                      itemCount: users.length,
                      itemBuilder: (_, i) => _row(i, users[i]),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}