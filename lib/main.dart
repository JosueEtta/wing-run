import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'screens/home_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Wing Run is a landscape game.
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);

  runApp(const WingRunApp());
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
      // The app starts on the home screen.
      home: const HomeScreen(),
    );
  }
}