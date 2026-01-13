import 'package:hive/hive.dart';

part 'credit_model.g.dart';

@HiveType(typeId: 3)
class CreditRecord extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String name; // Party Name (Customer or Supplier)

  @HiveField(2)
  String phone;

  @HiveField(3)
  double amount;

  @HiveField(4)
  DateTime date;

  @HiveField(5)
  String type; // 'Lend' (Receive) or 'Borrow' (Pay)

  @HiveField(6)
  bool isSettled; // Paid/Received completely?

  @HiveField(7)
  String? description;

  @HiveField(8)
  DateTime? dueDate;

  @HiveField(9)
  double paidAmount;

  @HiveField(10)
  List<String> logs;

  CreditRecord({
    required this.id,
    required this.name,
    required this.phone,
    required this.amount,
    required this.date,
    required this.type,
    this.isSettled = false,
    this.description,
    this.dueDate,
    this.paidAmount = 0.0,
    this.logs = const [],
  });

  double get balance => amount - paidAmount;
}
