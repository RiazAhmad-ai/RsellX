import 'package:hive/hive.dart';

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

  @HiveField(6)
  late String barcode;

  @HiveField(7)
  late int lowStockThreshold;

  @HiveField(8)
  late String category;

  @HiveField(9)
  late String size;

  @HiveField(10)
  late String weight;

  @HiveField(11)
  late String subCategory;

  @HiveField(12)
  String? imagePath;

  @HiveField(13)
  String color;

  @HiveField(14)
  String brand;

  @HiveField(15)
  String itemType;

  @HiveField(16)
  String unit;

  InventoryItem({
    required this.id,
    required this.name,
    required this.price,
    required this.stock,
    this.description,
    this.barcode = "N/A",
    this.lowStockThreshold = 3,
    this.category = "General",
    this.size = "N/A",
    this.weight = "N/A",
    this.subCategory = "N/A",
    this.imagePath,
    this.color = "N/A",
    this.brand = "N/A",
    this.itemType = "N/A",
    this.unit = "Piece",
  });
}
