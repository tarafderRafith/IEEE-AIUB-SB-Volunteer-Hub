import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';

import 'firebase_options.dart';
import 'screens/splash_screen.dart';
import 'services/fcm_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase.
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Register the FCM background message handler.
  FirebaseMessaging.onBackgroundMessage(
    firebaseMessagingBackgroundHandler,
  );

  // Initialize Firebase Cloud Messaging.
  await FCMService.instance.initialize();

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