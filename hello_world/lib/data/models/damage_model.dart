import 'package:hive/hive.dart';

part 'damage_model.g.dart';

@HiveType(typeId: 4)
class DamageRecord extends HiveObject {
  @HiveField(0)
  late String id;

  @HiveField(1)
  late String itemId;

  @HiveField(2)
  late String itemName;

  @HiveField(3)
  late int qty;

  @HiveField(4)
  late double lossAmount; // Usually costPrice * qty

  @HiveField(5)
  late DateTime date;

  @HiveField(6)
  late String reason;

  DamageRecord({
    required this.id,
    required this.itemId,
    required this.itemName,
    required this.qty,
    required this.lossAmount,
    required this.date,
    this.reason = "Broken",
  });
}
