import 'dart:math';
import '../data/inventory_model.dart';

class RecognitionService {
  // Singleton
  static final RecognitionService _instance = RecognitionService._internal();
  factory RecognitionService() => _instance;
  RecognitionService._internal();

  // === MATHS: EUCLIDEAN DISTANCE ===
  // Do points ke darmiyan faasla napna
  double _calculateDistance(List<double> embedding1, List<double> embedding2) {
    double sum = 0.0;
    for (int i = 0; i < embedding1.length; i++) {
      sum += pow((embedding1[i] - embedding2[i]), 2);
    }
    return sqrt(sum);
  }

  // === MAIN LOGIC: FIND MATCH ===
  InventoryItem? findMatch(
    List<double> scannedEmbedding,
    List<InventoryItem> allItems,
  ) {
    InventoryItem? bestMatchItem;
    double lowestDistance = 9999.0;

    // Threshold: Agar faasla 0.85 se kam ho tabhi match maano.
    // Agar galat cheezen match ho rahi hain to isay 0.8 karein.
    // Agar sahi cheez match nahi ho rahi to 0.9 ya 1.0 karein.
    double threshold = 0.85;

    for (var item in allItems) {
      // Har item ke paas multiple angles ki photos ho sakti hain
      // Hum sabse best angle dhundenge
      for (var savedEmbedding in item.embeddings) {
        double distance = _calculateDistance(scannedEmbedding, savedEmbedding);

        if (distance < lowestDistance) {
          lowestDistance = distance;
          bestMatchItem = item;
        }
      }
    }

    print("🔎 Closest Match Distance: $lowestDistance");

    if (lowestDistance < threshold) {
      return bestMatchItem; // Mubarak ho! Item mil gaya
    } else {
      return null; // Koi match nahi mila
    }
  }
}
