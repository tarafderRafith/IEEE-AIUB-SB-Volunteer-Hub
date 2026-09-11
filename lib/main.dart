import 'package:flutter/material.dart';
import 'screens/splash_screen.dart';

void main() {
  runApp(const VolunteerHubApp());
}

class VolunteerHubApp extends StatelessWidget {
  const VolunteerHubApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'IEEE AIUB Student Branch Volunteers Hub',
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF06152E),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF0A3D91),
          brightness: Brightness.dark,
        ),
      ),
      home: const SplashScreen(),
    );
  }
}