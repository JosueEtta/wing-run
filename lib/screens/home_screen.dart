import 'package:flutter/material.dart';
import '../component/bat.dart';
import '../data/db.dart';
import '../theme.dart';
import '../widgets/add_user_dialog.dart';
import '../widgets/pixel_widgets.dart';
import '../widgets/user_switcher.dart';
import 'game_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    // Wait for the first frame, then check if this is the first launch.
    WidgetsBinding.instance.addPostFrameCallback((_) => _askNameOnFirstLaunch());
  }

  /// First launch = no user in the database yet.
  Future<void> _askNameOnFirstLaunch() async {
    if (!mounted || session.users.isNotEmpty) return;
    final name = await showAddUserDialog(context, first: true);
    if (name == null) return;
    await _createUser(name);
  }

  Future<void> _createUser(String name) async {
    // TODO: replace this line with the method of your Session class (in
    // data/db.dart) that saves the user in SQLite, makes him the current
    // user, and calls notifyListeners() so the leaderboard refreshes.
    await session.addUser(name);
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
    body: SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(children: [
          // Left: title, bat scene, Play
          Expanded(
            flex: 5,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('WING RUN', style: pixel(30)),
                const SizedBox(height: 16),
                const Expanded(child: _Scene()),
                const SizedBox(height: 20),
                PixelButton(
                  label: 'PLAY',
                  icon: Icons.play_arrow,
                  fontSize: 20,
                  onTap: _play,
                ),
              ],
            ),
          ),
          const SizedBox(width: 24),
          // Right: user switcher + leaderboard
          Expanded(
            flex: 4,
            child: Column(children: [
              const Align(
                  alignment: Alignment.centerRight, child: UserSwitcher()),
              const SizedBox(height: 12),
              const Expanded(child: _Leaderboard()),
            ]),
          ),
        ]),
      ),
    ),
  );
}

class _Scene extends StatelessWidget {
  const _Scene();

  Widget _block(double w, double h) => Container(
    width: w,
    height: h,
    decoration: BoxDecoration(
      color: C.blue,
      border: Border.all(color: C.navy, width: 3),
    ),
  );

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    decoration: pixelBox(),
    child: Stack(children: [
      Positioned(left: 40, top: 0, child: _block(34, 60)),
      Positioned(right: 50, top: 0, child: _block(34, 90)),
      Positioned(left: 90, bottom: 0, child: _block(34, 80)),
      Positioned(right: 110, bottom: 0, child: _block(34, 50)),
      const Center(child: BatSpriteView(size: 110)),
    ]),
  );
}

class _Leaderboard extends StatelessWidget {
  const _Leaderboard();

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(12),
    decoration: pixelBox(color: C.slate),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('LEADERBOARD', style: pixel(11)),
      const SizedBox(height: 10),
      Expanded(
        child: ListenableBuilder(
          listenable: session,
          builder: (_, __) => ListView.builder(
            itemCount: session.users.length,
            itemBuilder: (_, i) {
              final u = session.users[i]; // already sorted best DESC
              final me = u.id == session.currentId;
              final medal = [C.gold, C.silver, C.bronze];
              return Container(
                margin: const EdgeInsets.only(bottom: 6),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                color: me ? C.highlight : Colors.white,
                child: Row(children: [
                  Container(
                    width: 28,
                    height: 28,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: i < 3 ? medal[i] : Colors.transparent,
                      border: Border.all(
                          color: i < 3 ? C.navy : Colors.transparent, width: 2),
                    ),
                    child: Text('${i + 1}', style: pixel(9)),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                      child: Text(u.name,
                          overflow: TextOverflow.ellipsis, style: body(24))),
                  Text('${u.best}', style: pixel(10)),
                ]),
              );
            },
          ),
        ),
      ),
    ]),
  );
}