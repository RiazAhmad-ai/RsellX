import 'dart:async';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import '../data/models/credit_model.dart';
import '../core/utils/id_generator.dart';
import '../core/utils/app_logger.dart';

class CreditProvider extends ChangeNotifier {
  // Stream subscription for proper cleanup
  StreamSubscription? _creditsBoxSubscription;
  
  CreditProvider() {
    _initializeListener();
  }
  
  void _initializeListener() {
    try {
      if (Hive.isBoxOpen('creditsBox')) {
        _creditsBoxSubscription = _box.watch().listen((_) {
          notifyListeners();
        }, onError: (error) {
          AppLogger.error('CreditProvider stream error', error: error);
        });
      }
    } catch (e) {
      AppLogger.error('CreditProvider initialization error', error: e);
    }
  }
  
  @override
  void dispose() {
    _creditsBoxSubscription?.cancel();
    super.dispose();
  }
  
  Box<CreditRecord> get _box => Hive.box<CreditRecord>('creditsBox');

  List<CreditRecord> get allRecords {
    final list = _box.values.toList();
    list.sort((a, b) => b.date.compareTo(a.date)); // Newest first
    return list;
  }
  
  // Receivables: 'Lend' (Main Udhaar Diya - Customers)
  List<CreditRecord> get receivables => _getSortedRecords('Lend');
  
  // Payables: 'Borrow' (Maine Udhaar Liya - Suppliers)
  List<CreditRecord> get payables => _getSortedRecords('Borrow');

  List<CreditRecord> _getSortedRecords(String type) {
    // 1. Filter by type
    final list = allRecords.where((e) => e.type == type).toList();
    // 2. Sort: Active first (isSettled=false), then Newest Date
    list.sort((a, b) {
      if (a.isSettled != b.isSettled) {
        return a.isSettled ? 1 : -1; // Active first
      }
      return b.date.compareTo(a.date);
    });
    return list;
  }
  
  List<CreditRecord> get settledHistory => allRecords.where((e) => e.isSettled).toList();

  double get totalToReceive => receivables.fold(0, (sum, item) => sum + item.balance);
  double get totalToPay => payables.fold(0, (sum, item) => sum + item.balance);

  String _generateId() {
    // Use UUID for guaranteed uniqueness
    return IdGenerator.generateWithPrefix('credit');
  }

  Future<void> addCredit({
    required String name,
    required String phone,
    required double amount,
    required String type, // 'Lend' or 'Borrow'
    String? description,
    DateTime? dueDate,
  }) async {
    try {
      final record = CreditRecord(
        id: _generateId(),
        name: name,
        phone: phone,
        amount: amount,
        date: DateTime.now(),
        type: type,
        description: description,
        dueDate: dueDate,
        isSettled: false,
      );
      // Use put() instead of add() to use our generated ID
      await _box.put(record.id, record);
      notifyListeners();
    } catch (e) {
      AppLogger.error('Error adding credit', error: e);
      rethrow;
    }
  }

  Future<void> settleRecord(CreditRecord record) async {
    record.isSettled = true;
    await record.save();
    notifyListeners();
  }
  
  Future<void> addPayment(CreditRecord record, double paymentAmount) async {
    record.paidAmount += paymentAmount;
    
    // Log
    final now = DateTime.now();
    // Format: "Paid {amount} on {d}/{m} at {time}"
    final dateStr = "${now.day}/${now.month}";
    final timeStr = "${now.hour > 12 ? now.hour - 12 : (now.hour == 0 ? 12 : now.hour)}:${now.minute.toString().padLeft(2, '0')} ${now.hour >= 12 ? 'PM' : 'AM'}";
    
    final isRefund = paymentAmount < 0;
    final absAmount = paymentAmount.abs().toInt();
    final action = isRefund ? "Refunded" : "Paid";
    
    final log = "$action $absAmount on $dateStr at $timeStr";
    
    // Clone list to ensure Hive detects change
    List<String> newLogs = List.from(record.logs);
    newLogs.add(log);
    record.logs = newLogs;

    if (record.paidAmount >= record.amount - 0.1) { // Tolerance
      record.isSettled = true;
    }
    
    await record.save();
    notifyListeners();
  }

  Future<void> updateRecord(CreditRecord record, String name, String phone, double amount, String desc) async {
    record.name = name;
    record.phone = phone;
    record.amount = amount;
    record.description = desc;
    
    // Log edit
    final now = DateTime.now();
    final dateStr = "${now.day}/${now.month}";
    final timeStr = "${now.hour > 12 ? now.hour - 12 : (now.hour == 0 ? 12 : now.hour)}:${now.minute.toString().padLeft(2, '0')} ${now.hour >= 12 ? 'PM' : 'AM'}";
    
    // Ensure logs list is mutable/growable
    List<String> newLogs = List.from(record.logs);
    newLogs.add("Edited Record on $dateStr at $timeStr");
    record.logs = newLogs;
    
    await record.save();
    notifyListeners();
  }

  Future<void> deleteRecord(CreditRecord record) async {
     await record.delete();
     notifyListeners();
  }
}
