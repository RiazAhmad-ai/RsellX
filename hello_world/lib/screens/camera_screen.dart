// lib/screens/camera_screen.dart
import 'package:flutter/material.dart';

class CameraScreen extends StatefulWidget {
  // Mode batayega ke hum bech rahe hain (sell) ya add kar rahe hain (add)
  final String mode;

  const CameraScreen({super.key, required this.mode});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  // Helpers: Mode ke hisaab se rang aur text decide karo
  bool get isAdding => widget.mode == 'add';
  Color get themeColor =>
      isAdding ? Colors.blue : Colors.red; // Blue for Add, Red for Sell
  String get modeText => isAdding ? "AI ADDING MODE" : "AI SELLING MODE";

  @override
  void initState() {
    super.initState();

    // 1. Animation Shuru (Lakeer upar neeche chalane ke liye)
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    // 2. AUTO CLOSE LOGIC (Timer)
    // 3 second baad maano scan complete ho gaya aur wapis jao
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        // 'true' ka matlab: Scan Kamyab raha -> Ab Form kholo
        Navigator.pop(context, true);
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose(); // Animation band karo memory save karne ke liye
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // === 1. BACKGROUND IMAGE (Camera View) ===
          Container(
            height: double.infinity,
            width: double.infinity,
            color: Colors.grey[900],
            child: Image.network(
              'https://images.unsplash.com/photo-1517705008128-361805f42e86?auto=format&fit=crop&q=80&w=414',
              fit: BoxFit.cover,
              color: Colors.black.withOpacity(0.5), // Thoda andhera
              colorBlendMode: BlendMode.darken,
              errorBuilder: (context, error, stackTrace) => const Center(
                child: Icon(Icons.broken_image, color: Colors.white),
              ),
            ),
          ),

          // === 2. ANIMATED SCAN LINE ===
          AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              final height = MediaQuery.of(context).size.height;
              // Line upar neeche move karegi (20% height se 70% height tak)
              return Positioned(
                top: height * 0.2 + (height * 0.5 * _controller.value),
                left: 0,
                right: 0,
                child: Container(
                  height: 3, // Line ki motayi
                  decoration: BoxDecoration(
                    color: themeColor, // <--- Dynamic Color (Red/Blue)
                    boxShadow: [
                      BoxShadow(
                        color: themeColor.withOpacity(0.6),
                        blurRadius: 20,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),

          // === 3. UI OVERLAY (Buttons & Text) ===
          SafeArea(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Top Bar
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Back Button (Cancel Scan)
                      IconButton(
                        icon: const Icon(
                          Icons.close,
                          color: Colors.white,
                          size: 30,
                        ),
                        onPressed: () => Navigator.pop(
                          context,
                          false,
                        ), // False matlab scan cancel hua
                      ),

                      // Mode Badge (Dynamic Color)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.3),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.circle, color: themeColor, size: 10),
                            const SizedBox(width: 8),
                            Text(
                              modeText,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Bottom Controls
                Padding(
                  padding: const EdgeInsets.only(bottom: 40),
                  child: Column(
                    children: [
                      Text(
                        isAdding ? "SEARCHING..." : "SCANNING...",
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          letterSpacing: 3,
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Fake Capture Button (Design Only)
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 4),
                        ),
                        child: Container(
                          margin: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: themeColor, // <--- Dynamic Color
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
