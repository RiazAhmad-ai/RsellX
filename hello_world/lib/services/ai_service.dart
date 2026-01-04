import 'dart:io';
import 'package:flutter/foundation.dart'; // For compute
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image/image.dart' as img;

class AIService {
  // Singleton Pattern (Taake puri app mein ek hi dimaag use ho)
  static final AIService _instance = AIService._internal();
  factory AIService() => _instance;
  AIService._internal();

  Interpreter? _interpreter;

  // === 1. MODEL LOAD KARNA ===
  Future<void> loadModel() async {
    try {
      final options = InterpreterOptions();

      // Note: Delegates like NNAPI/GPU require specific native binaries.
      // For now, we use standard CPU execution which is stable and fast for MobileNet.

      _interpreter = await Interpreter.fromAsset(
        'assets/mobilenet_v2.tflite',
        options: options,
      );
      print("✅ AI Brain Loaded with Acceleration!");
    } catch (e) {
      print("❌ Error Loading Model: $e");
    }
  }

  // === 2. IMAGE KA "FINGERPRINT" NIKALNA ===
  Future<List<double>> getEmbedding(File imageFile) async {
    if (_interpreter == null) {
      throw Exception("Model load nahi hua! App restart karein.");
    }

    // A. Image file ko parhna aur process karna (Isolate mein)
    final imageData = await imageFile.readAsBytes();

    // HEAVY TASK: Running in separate thread to prevent UI freeze
    var input = await compute(_processImage, imageData);

    // D. Output ke liye jagah banana (1001 features vector)
    // Shape: [1, 1001]
    var output = List.filled(1 * 1001, 0.0).reshape([1, 1001]);

    // E. Jadoo: AI run karna
    // Interpreter operations usually need to be on the same thread unless handled carefully.
    // TFLite Flutter bindings generally run inference efficiently (often C++ side).
    // However, if needed, inference could also be moved to isolate but passing Interpreter is tricky.
    // For now, image processing is the main bottleneck, so we offloaded that.
    _interpreter!.run(input, output);

    // F. Result wapis bhejna
    return List<double>.from(output[0]);
  }
}

// === ISOLATE FUNCTION (Must be outside class or static) ===
List<List<List<List<double>>>> _processImage(List<int> imageData) {
  img.Image? originalImage = img.decodeImage(Uint8List.fromList(imageData));

  if (originalImage == null) throw Exception("Image corrupt hai.");

  // IMPROVEMENT: CENTER CROP (Background Removal Alternative)
  // Instead of stretching, we take the center square which usually contains the product.
  int size = originalImage.width < originalImage.height ? originalImage.width : originalImage.height;
  int x = (originalImage.width - size) ~/ 2;
  int y = (originalImage.height - size) ~/ 2;
  
  img.Image croppedImage = img.copyCrop(originalImage, x: x, y: y, width: size, height: size);

  // B. Resize to 224x224
  img.Image resizedImage = img.copyResize(
    croppedImage,
    width: 224,
    height: 224,
  );

  // C. Image ko Matrix mein badalna (Numbers -1 se 1 ke beech)
  // Input shape: [1, 224, 224, 3]
  return List.generate(1, (batch) {
    return List.generate(224, (y) {
      return List.generate(224, (x) {
        var pixel = resizedImage.getPixel(x, y);
        // Normalize RGB values
        return [
          (pixel.r - 127.5) / 127.5,
          (pixel.g - 127.5) / 127.5,
          (pixel.b - 127.5) / 127.5,
        ];
      });
    });
  });
}
