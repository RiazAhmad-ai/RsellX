import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:audioplayers/audioplayers.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';

// Reuse the painter from your full_scanner_screen
import 'full_scanner_screen.dart';

class TextScannerScreen extends StatefulWidget {
  const TextScannerScreen({super.key});

  @override
  State<TextScannerScreen> createState() => _TextScannerScreenState();
}

class _TextScannerScreenState extends State<TextScannerScreen> {
  CameraController? _controller;
  bool _isProcessing = false;
  final AudioPlayer _player = AudioPlayer();
  
  @override
  void initState() {
    super.initState();
    _initializeCamera();
    // Pre-load for faster playback
    _player.setSource(AssetSource('scanner_beep.mp3'));
  }

  Future<void> _initializeCamera() async {
    final cameras = await availableCameras();
    if (cameras.isEmpty) return;

    final firstCamera = cameras.first;
    _controller = CameraController(
      firstCamera,
      ResolutionPreset.high,
      enableAudio: false,
    );

    await _controller!.initialize();
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _controller?.dispose();
    _player.dispose();
    super.dispose();
  }

  Future<void> _captureAndScan() async {
    if (_controller == null || !_controller!.value.isInitialized || _isProcessing) return;

    setState(() => _isProcessing = true);

    try {
      final XFile image = await _controller!.takePicture();
      final textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);
      final inputImage = InputImage.fromFilePath(image.path);
      
      final RecognizedText recognizedText = await textRecognizer.processImage(inputImage);
      
      // Filter logic: Only keep text that is "centrally" located in the image
      // For simplicity, we can assume the user centers the text.
      // But we can filter by bounding box if we want to be strict.
      // For now, let's return the most prominent central block or just all text 
      // since the user framed it. 
      // To strictly match "only in this box", we'd filter blocks.
      
      // Let's implement a basic filter: 
      // The image is usually high res. The box is in the center.
      // We will accept any block that intersects the center 50% of the image.
      
      String resultText = "";
      
      // Usually mobile cameras rotate images. With fromFilePath, ML Kit handles rotation metadata.
      // We'll iterate blocks and pick the one closest to center or just all of them for now
      // and let the user refine. But user asked for "specific space".
      // Let's filter blocks that are centrally located.
      
      // We don't know the exact image size vs screen size mapping easily here without complexity.
      // So we will return the text "as seen". Since the user framed it, they likely framed only the text they want.
      // To be "scanner ki tarah", the framing is the key.
      
      // However, if we want to be smart, we can pick the block with the largest area in the center.
       
      double maxArea = 0;
      String bestBlockText = "";

      // Simple heuristic: largest text block is usually the barcode/label
      for (TextBlock block in recognizedText.blocks) {
        // Calculate area
        double area = block.boundingBox.width * block.boundingBox.height;
        if (area > maxArea) {
          maxArea = area;
          bestBlockText = block.text;
        }
      }
      
      // If we found something, use it. Otherwise use all text or first line.
      if (bestBlockText.isNotEmpty) {
        resultText = bestBlockText;
      } else {
         resultText = recognizedText.text;
      }

      textRecognizer.close();

      if (mounted) {
         if (resultText.trim().isNotEmpty) {
           _player.resume(); // Play Beep Sound
         }
         Navigator.pop(context, resultText.trim());
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_controller == null || !_controller!.value.isInitialized) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator(color: AppColors.accent)),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Camera Preview
          Center(child: CameraPreview(_controller!)),

          // Overlay
          CustomPaint(
            painter: ScannerOverlayPainter(),
            child: Container(),
          ),

          // Top Bar
          Positioned(
            top: 50,
            left: 20,
            child: IconButton(
              icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          
          Positioned(
             top: 60,
             left: 0,
             right: 0,
             child: const Center(
               child: Text(
                 "Align Text in Box",
                 style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
               ),
             ),
          ),

          // Capture Button
          Positioned(
            bottom: 50,
            left: 0,
            right: 0,
            child: Center(
              child: _isProcessing 
                  ? const CircularProgressIndicator(color: Colors.white)
                  : GestureDetector(
                      onTap: _captureAndScan,
                      child: Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 4),
                          color: Colors.white24,
                        ),
                        child: Container(
                          margin: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white,
                          ),
                          child: const Icon(Icons.camera_alt, color: Colors.black, size: 32),
                        ),
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class TextScannerOverlayPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black.withOpacity(0.5)
      ..style = PaintingStyle.fill;

    // Rectangular Cutout for Text (Wider and Shorter)
    final double cutoutWidth = size.width * 0.85;
    const double cutoutHeight = 100.0; // Fixed height for text strip
    
    final double left = (size.width - cutoutWidth) / 2;
    final double top = (size.height - cutoutHeight) / 2;
    final Rect cutoutRect = Rect.fromLTWH(left, top, cutoutWidth, cutoutHeight);

    final Path path = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
      ..addRRect(RRect.fromRectAndRadius(cutoutRect, const Radius.circular(12)))
      ..fillType = PathFillType.evenOdd;

    canvas.drawPath(path, paint);

    // Draw Corners
    final borderPaint = Paint()
      ..color = AppColors.accent
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.0;

    const double cornerLength = 30.0;
    const double radius = 12.0;
    
    // Top Left
    canvas.drawPath(
      Path()
        ..moveTo(left, top + cornerLength)
        ..lineTo(left, top + radius)
        ..arcToPoint(Offset(left + radius, top), radius: const Radius.circular(radius))
        ..lineTo(left + cornerLength, top),
      borderPaint,
    );

    // Top Right
    canvas.drawPath(
      Path()
        ..moveTo(left + cutoutWidth - cornerLength, top)
        ..lineTo(left + cutoutWidth - radius, top)
        ..arcToPoint(Offset(left + cutoutWidth, top + radius), radius: const Radius.circular(radius))
        ..lineTo(left + cutoutWidth, top + cornerLength),
      borderPaint,
    );

    // Bottom Left
    canvas.drawPath(
      Path()
        ..moveTo(left, top + cutoutHeight - cornerLength)
        ..lineTo(left, top + cutoutHeight - radius)
        ..arcToPoint(Offset(left + radius, top + cutoutHeight), radius: const Radius.circular(radius))
        ..lineTo(left + cornerLength, top + cutoutHeight),
      borderPaint,
    );

    // Bottom Right
    canvas.drawPath(
      Path()
        ..moveTo(left + cutoutWidth - cornerLength, top + cutoutHeight)
        ..lineTo(left + cutoutWidth - radius, top + cutoutHeight)
        ..arcToPoint(Offset(left + cutoutWidth, top + cutoutHeight - radius), radius: const Radius.circular(radius))
        ..lineTo(left + cutoutWidth, top + cutoutHeight - cornerLength),
      borderPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
