import 'package:flutter/material.dart';
import 'core/theme.dart';
import 'screens/splash_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const SiswaMartApp());
}

class SiswaMartApp extends StatelessWidget {
  const SiswaMartApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SiswaMart',
      debugShowCheckedModeBanner: false,
      theme: neoTheme,
      home: const SplashScreen(),
    );
  }
}
