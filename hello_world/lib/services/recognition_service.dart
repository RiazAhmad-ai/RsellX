import 'dart:math';
import '../data/inventory_model.dart';

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
    // 0.70 is a good starting point for MobileNetV2 features.
    // Increase to 0.80 if it matches wrong items too easily.
    double threshold = 0.70;

    for (var item in allItems) {
      for (var savedEmbedding in item.embeddings) {
        double similarity = _calculateSimilarity(scannedEmbedding, savedEmbedding);

        if (similarity > highestSimilarity) {
          highestSimilarity = similarity;
          bestMatchItem = item;
        }
      }
    }

    print("🔎 Closest Match Similarity: $highestSimilarity");

    if (highestSimilarity >= threshold) {
      return bestMatchItem;
    } else {
      return null;
    }
  }
}
