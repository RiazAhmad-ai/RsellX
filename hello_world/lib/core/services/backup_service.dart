import 'dart:convert';
import 'dart:io';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:file_picker/file_picker.dart';
import '../../data/models/inventory_model.dart';
import '../../data/models/sale_model.dart';
import '../../data/models/expense_model.dart';

class BackupService {
  static Future<void> exportBackup() async {
    final inventoryBox = Hive.box<InventoryItem>('inventoryBox');
    final salesBox = Hive.box<SaleRecord>('historyBox');
    final expensesBox = Hive.box<ExpenseItem>('expensesBox');

    final backupData = {
      'inventory': inventoryBox.values.map((e) => {
        'id': e.id,
        'name': e.name,
        'price': e.price,
        'stock': e.stock,
        'description': e.description,
        'barcode': e.barcode,
      }).toList(),
      'sales': salesBox.values.map((e) => {
        'id': e.id,
        'itemId': e.itemId,
        'name': e.name,
        'price': e.price,
        'actualPrice': e.actualPrice,
        'qty': e.qty,
        'profit': e.profit,
        'date': e.date.toIso8601String(),
        'status': e.status,
        'billId': e.billId,
      }).toList(),
      'expenses': expensesBox.values.map((e) => {
        'id': e.id,
        'title': e.title,
        'amount': e.amount,
        'date': e.date.toIso8601String(),
        'category': e.category,
      }).toList(),
      'timestamp': DateTime.now().toIso8601String(),
    };

    final String jsonString = jsonEncode(backupData);
    final directory = await getTemporaryDirectory();
    final file = File('${directory.path}/crockery_backup_${DateTime.now().millisecondsSinceEpoch}.json');
    
    await file.writeAsString(jsonString);
    await Share.shareXFiles([XFile(file.path)], text: 'Crockery Manager Data Backup');
  }

  static Future<bool> importBackup() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
    );

    if (result != null) {
      File file = File(result.files.single.path!);
      final String jsonString = await file.readAsString();
      final Map<String, dynamic> backupData = jsonDecode(jsonString);

      // Restore Inventory
      if (backupData.containsKey('inventory')) {
        final box = Hive.box<InventoryItem>('inventoryBox');
        await box.clear();
        for (var item in backupData['inventory']) {
          box.add(InventoryItem(
            id: item['id'],
            name: item['name'],
            price: (item['price'] as num).toDouble(),
            stock: (item['stock'] as num).toInt(),
            description: item['description'],
            barcode: item['barcode'],
          ));
        }
      }

      // Restore Sales
      if (backupData.containsKey('sales')) {
        final box = Hive.box<SaleRecord>('historyBox');
        await box.clear();
        for (var item in backupData['sales']) {
          box.add(SaleRecord(
            id: item['id'],
            itemId: item['itemId'],
            name: item['name'],
            price: (item['price'] as num).toDouble(),
            actualPrice: (item['actualPrice'] as num).toDouble(),
            qty: (item['qty'] as num).toInt(),
            profit: (item['profit'] as num).toDouble(),
            date: DateTime.parse(item['date']),
            status: item['status'],
            billId: item['billId'],
          ));
        }
      }

      // Restore Expenses
      if (backupData.containsKey('expenses')) {
        final box = Hive.box<ExpenseItem>('expensesBox');
        await box.clear();
        for (var item in backupData['expenses']) {
          box.add(ExpenseItem(
            id: item['id'],
            title: item['title'],
            amount: (item['amount'] as num).toDouble(),
            date: DateTime.parse(item['date']),
            category: item['category'],
          ));
        }
      }
      return true;
    }
    return false;
  }
}
