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
      // 3 sec baad MainScreen par jao (aur wapis aana band karo)
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const MainScreen()),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // Ya apni brand color (Dark Blue)
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
              // Agar aapne asset lagaya hai to Image.asset use karein
              // Filhal main Icon use kar raha hoon safe side ke liye
              child: Image.asset(
                'assets/logo.png', // <--- Apni file ka naam yahan likhein
                width: 100,
                height: 100,
                fit: BoxFit.contain,
                // Agar image load na ho to Icon dikhaye
                errorBuilder: (c, o, s) =>
                    const Icon(Icons.storefront, size: 80, color: Colors.red),
              ),
            ),

            const SizedBox(height: 20),

            // 2. APP NAME
            const Text(
              "RIAZ AHMAD CROKERY",
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w900,
                color: Colors.black,
                letterSpacing: 0,
              ),
            ),
            Text(
              "Jehangira Underpass Shop#21", // Chota subtitle
              style: TextStyle(
                color: Colors.grey,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 10),

            // 3. Loading Circle (Chota sa)
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                color: Colors.red,
                strokeWidth: 2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
