import 'package:hive/hive.dart';

part 'sale_model.g.dart';

@HiveType(typeId: 1)
class SaleRecord extends HiveObject {
  @HiveField(0)
  late String id;

  @HiveField(1)
  late String itemId;

  @HiveField(2)
  late String name;

  @HiveField(3)
  late double price;

  @HiveField(4)
  late double actualPrice;

  @HiveField(5)
  late int qty;

  @HiveField(6)
  late double profit;

  @HiveField(7)
  late DateTime date;

  @HiveField(8)
  late String status; // 'Sold', 'Refunded'

  @HiveField(9)
  String? billId;

  @HiveField(10)
  late String category;

  @HiveField(11)
  late String size;

  @HiveField(12)
  late String weight;

  @HiveField(13)
  late String subCategory;

  @HiveField(14)
  String? imagePath;

  SaleRecord({
    required this.id,
    required this.itemId,
    required this.name,
    required this.price,
    required this.actualPrice,
    required this.qty,
    required this.profit,
    required this.date,
    this.status = 'Sold',
    this.billId,
    this.category = "General",
    this.size = "N/A",
    this.weight = "N/A",
    this.subCategory = "N/A",
    this.imagePath,
  });
}
