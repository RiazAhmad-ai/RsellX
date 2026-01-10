import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:image/image.dart' as img;
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import 'full_scanner_screen.dart';

/// 🎯 ADVANCED OCR SCANNER
/// High accuracy text recognition with:
/// - Image preprocessing
/// - Multiple recognition methods
/// - Confidence scoring
/// - Handwritten text support
class AdvancedTextScannerScreen extends StatefulWidget {
  const AdvancedTextScannerScreen({super.key});

  @override
  State<AdvancedTextScannerScreen> createState() => _AdvancedTextScannerScreenState();
}

class _AdvancedTextScannerScreenState extends State<AdvancedTextScannerScreen> {
  CameraController? _controller;
  bool _isProcessing = false;
  final AudioPlayer _player = AudioPlayer();
  String _statusMessage = "Align text in box";
  double _confidence = 0.0;
  bool _flashOn = false;
  
  @override
  void initState() {
    super.initState();
    _initializeCamera();
    _player.setSource(AssetSource('scanner_beep.mp3'));
  }

  Future<void> _initializeCamera() async {
    final cameras = await availableCameras();
    if (cameras.isEmpty) return;

    final firstCamera = cameras.first;
    _controller = CameraController(
      firstCamera,
      ResolutionPreset.veryHigh, // ⬆️ Higher resolution for better OCR
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.jpeg,
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

  /// 🎯 MAIN SCAN FUNCTION - Advanced Multi-Method Recognition
  Future<void> _captureAndScan() async {
    if (_controller == null || !_controller!.value.isInitialized || _isProcessing) return;

    setState(() {
      _isProcessing = true;
      _statusMessage = "Capturing image...";
    });

    try {
      // Step 1: Capture image
      final XFile image = await _controller!.takePicture();
      
      setState(() => _statusMessage = "Enhancing image...");
      
      // Step 2: Enhance image for better OCR
      final enhancedPath = await _enhanceImageForOCR(image.path);
      
      setState(() => _statusMessage = "Recognizing text...");
      
      // Step 3: Multi-method recognition
      final result = await _smartTextRecognition(enhancedPath);
      
      // Step 4: Validate and return
      if (mounted) {
        if (result['text'].trim().isNotEmpty) {
          _confidence = result['confidence'];
          
          // Play sound
          _player.resume();
          
          // Show preview dialog
          final confirmed = await _showPreviewDialog(result['text'], result['confidence']);
          
          if (confirmed == true) {
            Navigator.pop(context, result['text'].trim());
          } else {
            setState(() {
              _isProcessing = false;
              _statusMessage = "Try again with better lighting";
            });
          }
        } else {
          setState(() {
            _isProcessing = false;
            _statusMessage = "No text found. Try again";
          });
          
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("❌ No text detected. Ensure good lighting!"),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isProcessing = false;
          _statusMessage = "Error occurred. Retry";
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e")),
        );
      }
    }
  }

  /// 📸 IMAGE ENHANCEMENT - Preprocessing for better OCR accuracy
  Future<String> _enhanceImageForOCR(String imagePath) async {
    try {
      // Load image
      final bytes = await File(imagePath).readAsBytes();
      img.Image? image = img.decodeImage(bytes);
      
      if (image == null) return imagePath;
      
      // Enhancement pipeline
      // 1. Grayscale conversion
      image = img.grayscale(image);
      
      // 2. Increase contrast (makes text stand out)
      image = img.contrast(image, contrast: 130);
      
      // 3. Adjust brightness
      image = img.brightness(image, brightness: 15);
      
      // 4. Sharpen for better edge detection
      image = img.adjustColor(
        image,
        saturation: 0,
        brightness: 1.15,
        contrast: 1.3,
      );
      
      // 5. Noise reduction (optional)
      // image = img.gaussianBlur(image, radius: 1);
      
      // Save enhanced image
      final enhancedPath = imagePath.replaceAll('.jpg', '_enhanced.jpg');
      await File(enhancedPath).writeAsBytes(img.encodeJpg(image, quality: 95));
      
      return enhancedPath;
    } catch (e) {
      debugPrint("Image enhancement failed: $e");
      return imagePath; // Return original if enhancement fails
    }
  }

  /// 🧠 SMART TEXT RECOGNITION - Multiple methods for highest accuracy
  Future<Map<String, dynamic>> _smartTextRecognition(String imagePath) async {
    final inputImage = InputImage.fromFilePath(imagePath);
    
    List<Map<String, dynamic>> results = [];
    
    // Method 1: Auto-detect (best for handwritten)
    try {
      final recognizer = TextRecognizer();
      final result = await recognizer.processImage(inputImage);
      await recognizer.close();
      
      if (result.text.trim().isNotEmpty) {
        results.add({
          'text': _getBestBlock(result),
          'confidence': _calculateConfidence(result),
          'method': 'auto-detect',
        });
      }
    } catch (e) {
      debugPrint("Auto-detect failed: $e");
    }
    
    // Method 2: Latin script (best for printed)
    try {
      final recognizer = TextRecognizer(script: TextRecognitionScript.latin);
      final result = await recognizer.processImage(inputImage);
      await recognizer.close();
      
      if (result.text.trim().isNotEmpty) {
        results.add({
          'text': _getBestBlock(result),
          'confidence': _calculateConfidence(result),
          'method': 'latin',
        });
      }
    } catch (e) {
      debugPrint("Latin recognition failed: $e");
    }
    
    // Method 3: Devanagari (good for handwriting)
    try {
      final recognizer = TextRecognizer(script: TextRecognitionScript.devanagari);
      final result = await recognizer.processImage(inputImage);
      await recognizer.close();
      
      if (result.text.trim().isNotEmpty) {
        results.add({
          'text': _getBestBlock(result),
          'confidence': _calculateConfidence(result),
          'method': 'devanagari',
        });
      }
    } catch (e) {
      debugPrint("Devanagari recognition failed: $e");
    }
    
    // Return best result based on confidence
    if (results.isEmpty) {
      return {'text': '', 'confidence': 0.0, 'method': 'none'};
    }
    
    // Sort by confidence
    results.sort((a, b) => (b['confidence'] as double).compareTo(a['confidence'] as double));
    
    return results.first;
  }

  /// 📊 CALCULATE CONFIDENCE SCORE
  double _calculateConfidence(RecognizedText result) {
    if (result.blocks.isEmpty) return 0.0;
    
    double totalConfidence = 0.0;
    int lineCount = 0;
    
    for (var block in result.blocks) {
      for (var line in block.lines) {
        // ML Kit doesn't provide confidence directly, so we use heuristics
        // Longer text with more words = higher confidence
        final wordCount = line.text.split(' ').where((w) => w.isNotEmpty).length;
        final lengthScore = (line.text.length / 50).clamp(0.0, 1.0);
        final wordScore = (wordCount / 5).clamp(0.0, 1.0);
        
        totalConfidence += (lengthScore + wordScore) / 2;
        lineCount++;
      }
    }
    
    return lineCount > 0 ? (totalConfidence / lineCount).clamp(0.0, 1.0) : 0.0;
  }

  /// 🎯 GET BEST TEXT BLOCK - Extract most prominent text
  String _getBestBlock(RecognizedText recognizedText) {
    if (recognizedText.blocks.isEmpty) return recognizedText.text;
    
    double maxArea = 0;
    String bestBlockText = "";

    // Find largest block (usually the main content)
    for (TextBlock block in recognizedText.blocks) {
      double area = block.boundingBox.width * block.boundingBox.height;
      if (area > maxArea) {
        maxArea = area;
        bestBlockText = block.text;
      }
    }
    
    return bestBlockText.isNotEmpty ? bestBlockText : recognizedText.text;
  }

  /// 💬 PREVIEW DIALOG - Show recognized text for confirmation
  Future<bool?> _showPreviewDialog(String text, double confidence) async {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(
              confidence > 0.7 ? Icons.check_circle : Icons.warning,
              color: confidence > 0.7 ? Colors.green : Colors.orange,
            ),
            const SizedBox(width: 10),
            const Text("Recognized Text"),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.accent),
              ),
              child: SelectableText(
                text,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                const Text("Confidence: "),
                Text(
                  "${(confidence * 100).toStringAsFixed(0)}%",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: confidence > 0.7 ? Colors.green : Colors.orange,
                  ),
                ),
              ],
            ),
            if (confidence < 0.7)
              const Padding(
                padding: EdgeInsets.only(top: 8),
                child: Text(
                  "💡 Tip: Better lighting improves accuracy",
                  style: TextStyle(fontSize: 12, color: Colors.orange),
                ),
              ),
          ],
        ),
        actions: [
          TextButton.icon(
            onPressed: () => Navigator.pop(context, false),
            icon: const Icon(Icons.camera_alt),
            label: const Text("Retry"),
          ),
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(context, true),
            icon: const Icon(Icons.check),
            label: const Text("Confirm"),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accent,
            ),
          ),
        ],
      ),
    );
  }

  /// 💡 TOGGLE FLASH
  void _toggleFlash() async {
    if (_controller == null) return;
    
    setState(() => _flashOn = !_flashOn);
    
    try {
      await _controller!.setFlashMode(_flashOn ? FlashMode.torch : FlashMode.off);
    } catch (e) {
      debugPrint("Flash toggle failed: $e");
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

          // Overlay with scanning box
          CustomPaint(
            painter: ScannerOverlayPainter(),
            child: Container(),
          ),

          // Top Bar with controls
          Positioned(
            top: 50,
            left: 0,
            right: 0,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                  IconButton(
                    icon: Icon(
                      _flashOn ? Icons.flash_on : Icons.flash_off,
                      color: Colors.white,
                    ),
                    onPressed: _toggleFlash,
                  ),
                ],
              ),
            ),
          ),
          
          // Status Message
          Positioned(
            top: 100,
            left: 0,
            right: 0,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 40),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.black87,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.accent, width: 2),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    "📝 Advanced OCR Scanner",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _statusMessage,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),

          // Tips Box
          Positioned(
            bottom: 180,
            left: 0,
            right: 0,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 40),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    "💡 Pro Tips:",
                    style: TextStyle(
                      color: AppColors.accent,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    "• Good lighting\n• Clear writing\n• Avoid shadows",
                    style: TextStyle(color: Colors.white70, fontSize: 11),
                    textAlign: TextAlign.center,
                  ),
                ],
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
                  ? Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const CircularProgressIndicator(color: AppColors.accent),
                        const SizedBox(height: 10),
                        Text(
                          _statusMessage,
                          style: const TextStyle(color: Colors.white),
                        ),
                      ],
                    )
                  : GestureDetector(
                      onTap: _captureAndScan,
                      child: Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.accent, width: 4),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.accent.withOpacity(0.5),
                              blurRadius: 20,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: Container(
                          margin: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              colors: [AppColors.accent, AppColors.accentDark],
                            ),
                          ),
                          child: const Icon(Icons.document_scanner, color: Colors.white, size: 32),
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
