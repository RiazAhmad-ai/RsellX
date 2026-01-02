// lib/main.dart
import 'package:flutter/material.dart';
import 'screens/splash_screen.dart'; // Pehle Splash Screen aayegi

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false, // Debug ka ribbon hataya
      title: 'RIAZ AHMAD CROKERY',
      theme: ThemeData(
        // App ka color theme (Laal aur Safed)
        primarySwatch: Colors.red,
        scaffoldBackgroundColor: Colors.white,
        useMaterial3: true,
      ),
      // App yahan se shuru hogi
      home: const SplashScreen(),
    );
  }
}
