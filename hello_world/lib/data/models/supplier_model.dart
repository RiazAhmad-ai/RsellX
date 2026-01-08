import 'package:hive/hive.dart';

part 'supplier_model.g.dart';

@HiveType(typeId: 5)
class Supplier extends HiveObject {
  @HiveField(0)
  late String id;

  @HiveField(1)
  late String name;

  @HiveField(2)
  late String phone;

  @HiveField(3)
  late String? address;

  @HiveField(4)
  late double balance; // Total amount owed to this supplier

  Supplier({
    required this.id,
    required this.name,
    required this.phone,
    this.address,
    this.balance = 0.0,
  });
}

@HiveType(typeId: 6)
class PurchaseRecord extends HiveObject {
  @HiveField(0)
  late String id;

  @HiveField(1)
  late String supplierId;

  @HiveField(2)
  late String itemId;

  @HiveField(3)
  late String itemName;

  @HiveField(4)
  late int qty;

  @HiveField(5)
  late double purchasePrice;

  @HiveField(6)
  late DateTime date;

  PurchaseRecord({
    required this.id,
    required this.supplierId,
    required this.itemId,
    required this.itemName,
    required this.qty,
    required this.purchasePrice,
    required this.date,
  });
}
