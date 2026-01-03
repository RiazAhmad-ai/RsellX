import 'package:hive/hive.dart';

// Yeh line error degi shuru mein, pareshan na hon.
// Jab hum command chalayenge to yeh file khud ban jayegi.
part 'inventory_model.g.dart';

@HiveType(typeId: 0)
class InventoryItem extends HiveObject {
  @HiveField(0)
  late String id;

  @HiveField(1)
  late String name;

  @HiveField(2)
  late double price;

  @HiveField(3)
  late int stock;

  @HiveField(4)
  late String? description;

  // === MAGIC PART ===
  // Hum tasveer save nahi karenge, balki uska "AI Fingerprint" save karenge.
  // List<double> = Ek photo ka fingerprint
  // List<List<double>> = Multiple photos (angles) ke fingerprints
  @HiveField(5)
  late List<List<double>> embeddings;

  InventoryItem({
    required this.id,
    required this.name,
    required this.price,
    required this.stock,
    this.description,
    required this.embeddings,
  });
}
