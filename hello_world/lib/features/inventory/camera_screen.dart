import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import '../../main.dart'; // Global 'cameras' variable ke liye
import 'dart:io';

class CameraScreen extends StatefulWidget {
  final String mode; // 'add' ya 'sell'

  const CameraScreen({super.key, required this.mode});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  CameraController? _controller;
  bool _isCameraInitialized = false;
  FlashMode _flashMode = FlashMode.off; // Default flash off

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  // Camera shuru karna
  void _initializeCamera() {
    if (cameras.isEmpty) return;

    // Pehla camera (Back Camera) uthao
    _controller = CameraController(
      cameras[0],
      ResolutionPreset.high, // Higher resolution for better AI fingerprinting
      enableAudio: false,
    );

    _controller!.initialize().then((_) {
      if (!mounted) return;
      setState(() {
        _isCameraInitialized = true;
      });
    });
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  // Photo khichne ka function
  Future<void> _takePicture() async {
    if (_controller == null || !_controller!.value.isInitialized) return;

    try {
      final XFile image = await _controller!.takePicture();
      if (!mounted) return;
      Navigator.pop(context, File(image.path));
    } catch (e) {
      print("Error taking picture: $e");
    }
  }

  // Flash toggle function
  void _toggleFlash() async {
    if (_controller == null || !_controller!.value.isInitialized) return;

    FlashMode nextMode;
    switch (_flashMode) {
      case FlashMode.off:
        nextMode = FlashMode.torch; // Torch keeps the light ON
        break;
      case FlashMode.torch:
        nextMode = FlashMode.auto;
        break;
      case FlashMode.auto:
        nextMode = FlashMode.off;
        break;
      default:
        nextMode = FlashMode.off;
    }

    try {
      await _controller!.setFlashMode(nextMode);
      setState(() {
        _flashMode = nextMode;
      });
    } catch (e) {
      print("Error setting flash mode: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isCameraInitialized) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // 1. ASLI CAMERA PREVIEW
          SizedBox(
            height: double.infinity,
            width: double.infinity,
            child: CameraPreview(_controller!),
          ),

          // 2. UI Overlay (Buttons etc)
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
                      IconButton(
                        icon: const Icon(
                          Icons.close,
                          color: Colors.white,
                          size: 30,
                        ),
                        onPressed: () => Navigator.pop(context, null),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          widget.mode == 'add' ? "ADD NEW" : "SCAN",
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                        ),
                      ),
                      IconButton(
                        icon: Icon(
                          _flashMode == FlashMode.off
                              ? Icons.flash_off
                              : _flashMode == FlashMode.torch
                                  ? Icons.flash_on
                                  : Icons.flash_auto,
                          color: _flashMode == FlashMode.off ? Colors.white54 : Colors.yellow,
                          size: 28,
                        ),
                        onPressed: _toggleFlash,
                      ),
                    ],
                  ),
                ),

                // 3. SCAN GUIDE (Center Box)
                Container(
                  width: 250,
                  height: 250,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.white.withOpacity(0.5), width: 2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Stack(
                    children: [
                      // Corner markers for a professional look
                      _buildCorner(0, 0, isTop: true, isLeft: true),
                      _buildCorner(0, null, isTop: true, isRight: true),
                      _buildCorner(null, 0, isBottom: true, isLeft: true),
                      _buildCorner(null, null, isBottom: true, isRight: true),
                      Center(
                        child: Text(
                          "PLACE ITEM HERE",
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.3),
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Capture Button
                Padding(
                  padding: const EdgeInsets.only(bottom: 30),
                  child: GestureDetector(
                    onTap: _takePicture,
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 5),
                      ),
                      child: Container(
                        margin: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: widget.mode == 'add'
                              ? Colors.blue
                              : Colors.red,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.camera_alt,
                          color: Colors.white,
                          size: 30,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCorner(double? top, double? left, {bool isTop = false, bool isLeft = false, bool isRight = false, bool isBottom = false}) {
    return Positioned(
      top: top,
      left: left,
      right: isRight ? 0 : null,
      bottom: isBottom ? 0 : null,
      child: Container(
        width: 20,
        height: 20,
        decoration: BoxDecoration(
          border: Border(
            top: isTop ? const BorderSide(color: Colors.white, width: 4) : BorderSide.none,
            left: isLeft ? const BorderSide(color: Colors.white, width: 4) : BorderSide.none,
            right: isRight ? const BorderSide(color: Colors.white, width: 4) : BorderSide.none,
            bottom: isBottom ? const BorderSide(color: Colors.white, width: 4) : BorderSide.none,
          ),
        ),
      ),
    );
  }
}
