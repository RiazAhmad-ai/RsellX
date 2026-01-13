import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:rsellx/core/services/backup_service.dart';
import 'package:rsellx/core/services/reporting_service.dart';
import 'package:rsellx/core/services/logger_service.dart';
import 'package:hive/hive.dart';
import 'package:rsellx/data/models/inventory_model.dart';
import 'package:rsellx/data/models/sale_model.dart';
import 'package:rsellx/data/models/expense_model.dart';
import 'package:rsellx/data/models/credit_model.dart';

class BackupProvider extends ChangeNotifier {
  Box<InventoryItem> get _inventoryBox => Hive.box<InventoryItem>('inventoryBox');
  Box<ExpenseItem> get _expensesBox => Hive.box<ExpenseItem>('expensesBox');
  Box<SaleRecord> get _historyBox => Hive.box<SaleRecord>('historyBox');
  Box<SaleRecord> get _cartBox => Hive.box<SaleRecord>('cartBox');
  Box<CreditRecord> get _creditsBox => Hive.box<CreditRecord>('creditsBox');
  Box get _settingsBox => Hive.box('settingsBox');

  Future<void> exportBackup() async {
    await BackupService.exportBackup();
  }

  Future<bool> importBackup() async {
    final success = await BackupService.importBackup();
    if (success) {
      notifyListeners();
    }
    return success;
  }

  Future<bool> importInventoryFromExcel() async {
    final success = await ReportingService.importInventoryFromExcel();
    if (success) {
      notifyListeners();
    }
    return success;
  }

  Future<void> clearAllData() async {
    await _inventoryBox.clear();
    await _historyBox.clear();
    await _cartBox.clear();
    await _expensesBox.clear();
    await _creditsBox.clear();
    
    // Clear Settings & Logo
    final String? logoPath = _settingsBox.get('logoPath') as String?;
    if (logoPath != null) {
      final file = File(logoPath);
      if (await file.exists()) {
        try {
          await file.delete();
        } catch (e) {
          AppLogger.error("Failed to delete logo", error: e);
        }
      }
    }
    await _settingsBox.clear();

    notifyListeners();
  }
}
