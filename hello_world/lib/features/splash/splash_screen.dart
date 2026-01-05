// lib/features/splash/splash_screen.dart
import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:async';
import '../main/main_screen.dart';
import '../../data/repositories/data_store.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';

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
      backgroundColor: AppColors.background,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 1. AAPKA LOGO
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1), // Background circle
                shape: BoxShape.circle,
              ),
              child: DataStore().logoPath != null && File(DataStore().logoPath!).existsSync()
                  ? Image.file(
                      File(DataStore().logoPath!),
                      width: 100,
                      height: 100,
                      fit: BoxFit.contain,
                    )
                  : Image.asset(
                      'assets/logo.png',
                      width: 100,
                      height: 100,
                      fit: BoxFit.contain,
                      errorBuilder: (c, o, s) =>
                          const Icon(Icons.storefront, size: 80, color: AppColors.primary),
                    ),
            ),

            const SizedBox(height: 30),

            // 2. APP NAME
            Text(
              DataStore().shopName,
              style: AppTextStyles.h1.copyWith(letterSpacing: 2),
            ),

            const SizedBox(height: 40),

            // 3. LOADING LINE BAR (New Change)
            SizedBox(
              width: 200, // Bar ki chaurayi (width)
              child: ClipRRect(
                // Kinare Gol karne ke liye
                borderRadius: BorderRadius.circular(10),
                child: LinearProgressIndicator(
                  backgroundColor: AppColors.primary.withOpacity(0.1),
                  color: AppColors.primary,
                  minHeight: 6,
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
