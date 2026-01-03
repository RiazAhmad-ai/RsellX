import 'dart:io';
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
      // Options set karna (CPU/GPU)
      final options = InterpreterOptions();

      // Asset se model uthana
      _interpreter = await Interpreter.fromAsset(
        'assets/mobilenet_v2.tflite',
        options: options,
      );
      print("✅ AI Brain Loaded Successfully!");
    } catch (e) {
      print("❌ Error Loading Model: $e");
    }
  }

  // === 2. IMAGE KA "FINGERPRINT" NIKALNA ===
  Future<List<double>> getEmbedding(File imageFile) async {
    if (_interpreter == null) {
      throw Exception("Model load nahi hua! App restart karein.");
    }

    // A. Image file ko parhna aur process karna
    final imageData = await imageFile.readAsBytes();
    img.Image? originalImage = img.decodeImage(imageData);

    if (originalImage == null) throw Exception("Image corrupt hai.");

    // B. Image ko chota karna (224x224) jo AI model ki requirement hai
    img.Image resizedImage = img.copyResize(
      originalImage,
      width: 224,
      height: 224,
    );

    // C. Image ko Matrix mein badalna (Numbers -1 se 1 ke beech)
    // Input shape: [1, 224, 224, 3]
    var input = List.generate(1, (batch) {
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

    // D. Output ke liye jagah banana (1001 features vector)
    // Shape: [1, 1001]
    var output = List.filled(1 * 1001, 0.0).reshape([1, 1001]);

    // E. Jadoo: AI run karna
    _interpreter!.run(input, output);

    // F. Result wapis bhejna
    return List<double>.from(output[0]);
  }
}
