import 'dart:math';
import '../data/models/inventory_model.dart';

class RecognitionService {
  // Singleton
  static final RecognitionService _instance = RecognitionService._internal();
  factory RecognitionService() => _instance;
  RecognitionService._internal();

  // === MATHS: COSINE SIMILARITY ===
  // Industry standard for comparing AI embeddings
  double _calculateSimilarity(List<double> v1, List<double> v2) {
    double dotProduct = 0.0;
    double normA = 0.0;
    double normB = 0.0;
    for (int i = 0; i < v1.length; i++) {
      dotProduct += v1[i] * v2[i];
      normA += v1[i] * v1[i];
      normB += v2[i] * v2[i];
    }
    if (normA == 0 || normB == 0) return 0.0;
    return dotProduct / (sqrt(normA) * sqrt(normB));
  }

  // === MAIN LOGIC: FIND MATCH ===
  InventoryItem? findMatch(
    List<double> scannedEmbedding,
    List<InventoryItem> allItems,
  ) {
    InventoryItem? bestMatchItem;
    double highestSimilarity = -1.0;

    // Threshold: Agora similarity closer to 1.0, means better match.
    // 0.75 is a more precise threshold for MobileNetV2 features.
    double threshold = 0.75;

    for (var item in allItems) {
      double itemMaxSimilarity = -1.0;
      
      for (var savedEmbedding in item.embeddings) {
        double similarity = _calculateSimilarity(scannedEmbedding, savedEmbedding);
        if (similarity > itemMaxSimilarity) {
          itemMaxSimilarity = similarity;
        }
      }

      if (itemMaxSimilarity > highestSimilarity) {
        highestSimilarity = itemMaxSimilarity;
        bestMatchItem = item;
      }
    }

    print("🔎 Detection Confidence: ${(highestSimilarity * 100).toStringAsFixed(1)}%");

    if (highestSimilarity >= threshold) {
      return bestMatchItem;
    } else {
      // Fallback: If similarity is borderline (0.65 - 0.75), maybe return but warn?
      // For now, strict threshold for accuracy.
      return null;
    }
  }
}
