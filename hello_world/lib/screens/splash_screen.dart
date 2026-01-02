// lib/screens/splash_screen.dart
import 'package:flutter/material.dart';
import 'dart:async'; // Timer ke liye
import 'main_screen.dart'; // Jahan jana hai

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    // 3 Second ka Timer
    Timer(const Duration(seconds: 3), () {
      // 3 sec baad MainScreen par jao
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const MainScreen()),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 1. AAPKA LOGO
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.red[50], // Background circle
                shape: BoxShape.circle,
              ),
              child: Image.asset(
                'assets/logo.png', // Apni file check karein
                width: 100,
                height: 100,
                fit: BoxFit.contain,
                errorBuilder: (c, o, s) =>
                    const Icon(Icons.storefront, size: 80, color: Colors.red),
              ),
            ),

            const SizedBox(height: 30),

            // 2. APP NAME
            const Text(
              "RIAZ AHMAD CROKERY",
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w900,
                color: Colors.black,
                letterSpacing: 2,
              ),
            ),

            const SizedBox(height: 40),

            // 3. LOADING LINE BAR (New Change)
            SizedBox(
              width: 200, // Bar ki chaurayi (width)
              child: ClipRRect(
                // Kinare Gol karne ke liye
                borderRadius: BorderRadius.circular(10),
                child: LinearProgressIndicator(
                  backgroundColor: Colors.red[100], // Halka peeche ka rang
                  color: Colors.red, // Bhara hua rang
                  minHeight: 6, // Line ki motayi
                ),
              ),
            ),

            const SizedBox(height: 10),

            const Text(
              "Loading System...",
              style: TextStyle(color: Colors.grey, fontSize: 10),
            ),
          ],
        ),
      ),
    );
  }
}
