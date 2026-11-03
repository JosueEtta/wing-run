import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';

import 'audio.dart';
import 'component/bat.dart';
import 'data/db.dart';
import 'screens/home_screen.dart';

Future<void> main() async {
  final binding = WidgetsFlutterBinding.ensureInitialized();

  // Keep the native splash on screen until HomeScreen calls remove().
  FlutterNativeSplash.preserve(widgetsBinding: binding);

  // Wing Run is a landscape game.
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);

  // Load everything the home screen needs BEFORE showing it.
  await Future.wait([
    session.load(), // users + current user from SQLite
    loadBatImage(), // decode the bat sprite sheet once
    AudioService.instance.init(),
  ]);

  runApp(const WingRunApp());

  // Start the music without delaying the first frame.
  AudioService.instance.playMusic();
}

class WingRunApp extends StatelessWidget {
  const WingRunApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Wing Run',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: Colors.white,
      ),
      home: const HomeScreen(),
    );
  }
}