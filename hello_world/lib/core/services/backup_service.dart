import 'dart:convert';
import 'dart:io';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:file_picker/file_picker.dart';
import '../../data/models/inventory_model.dart';
import '../../data/models/sale_model.dart';
import '../../data/models/expense_model.dart';
import '../../data/models/credit_model.dart';
import '../../data/models/damage_model.dart';
import 'logger_service.dart';

class BackupService {
  static Future<void> exportBackup() async {
    final inventoryBox = Hive.box<InventoryItem>('inventoryBox');

    final salesBox = Hive.box<SaleRecord>('historyBox');
    final cartBox = Hive.box<SaleRecord>('cartBox');
    final expensesBox = Hive.box<ExpenseItem>('expensesBox');
    final creditsBox = Hive.box<CreditRecord>('creditsBox');
    final settingsBox = Hive.box('settingsBox');

    final backupData = {
      'inventory': inventoryBox.values.map((e) => {
        'id': e.id,
        'name': e.name,
        'price': e.price,
        'stock': e.stock,
        'description': e.description,
        'barcode': e.barcode,
        'category': e.category,
        'subCategory': e.subCategory,
        'size': e.size,
        'weight': e.weight,
        'lowStockThreshold': e.lowStockThreshold,
        'imagePath': e.imagePath,
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
        'category': e.category, // Added
        'subCategory': e.subCategory, // Added
        'size': e.size, // Added
        'weight': e.weight, // Added
        'imagePath': e.imagePath, // Added
      }).toList(),
      'cart': cartBox.values.map((e) => {
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
        'category': e.category,
        'subCategory': e.subCategory,
        'size': e.size,
        'weight': e.weight,
        'imagePath': e.imagePath,
      }).toList(),
      'expenses': expensesBox.values.map((e) => {
        'id': e.id,
        'title': e.title,
        'amount': e.amount,
        'date': e.date.toIso8601String(),
        'category': e.category,
      }).toList(),
      'credits': creditsBox.values.map((e) => {
        'id': e.id,
        'name': e.name,
        'phone': e.phone,
        'amount': e.amount,
        'date': e.date.toIso8601String(),
        'type': e.type,
        'isSettled': e.isSettled,
        'description': e.description,
        'dueDate': e.dueDate?.toIso8601String(),
        'paidAmount': e.paidAmount,
        'logs': e.logs,
      }).toList(),
      'damages': Hive.box<DamageRecord>('damageBox').values.map((e) => {
        'id': e.id,
        'itemId': e.itemId,
        'itemName': e.itemName,
        'qty': e.qty,
        'lossAmount': e.lossAmount,
        'reason': e.reason,
        'date': e.date.toIso8601String(),
      }).toList(),
      'settings': await _prepareSettingsForExport(settingsBox),
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
      try {
        File file = File(result.files.single.path!);
        final String jsonString = await file.readAsString();
        final Map<String, dynamic> backupData = jsonDecode(jsonString);

        if (backupData.isEmpty) {
          AppLogger.error("Selected backup file is empty or invalid.");
          return false;
        }

        // Restore Inventory
        if (backupData.containsKey('inventory') && backupData['inventory'] is List) {
          final box = Hive.box<InventoryItem>('inventoryBox');
          await box.clear();
          for (var item in backupData['inventory']) {
            if (item is Map) {
              box.put(item['id'], InventoryItem(
                id: item['id']?.toString() ?? DateTime.now().millisecondsSinceEpoch.toString(),
                name: item['name']?.toString() ?? "Unknown",
                price: ((item['price'] as num?)?.toDouble()) ?? 0.0,
                stock: ((item['stock'] as num?)?.toInt()) ?? 0,
                description: item['description']?.toString(),
                barcode: item['barcode']?.toString() ?? "N/A",
                category: item['category']?.toString() ?? "General",
                subCategory: item['subCategory']?.toString() ?? "N/A",
                size: item['size']?.toString() ?? "N/A",
                weight: item['weight']?.toString() ?? "N/A",
                lowStockThreshold: ((item['lowStockThreshold'] as num?)?.toInt()) ?? 5,
                imagePath: item['imagePath']?.toString(),
              ));
            }
          }
        }

        // Restore Sales
        if (backupData.containsKey('sales') && backupData['sales'] is List) {
          final box = Hive.box<SaleRecord>('historyBox');
          await box.clear();
          for (var item in backupData['sales']) {
            if (item is Map) {
              box.put(item['id'], SaleRecord(
                id: item['id']?.toString() ?? DateTime.now().millisecondsSinceEpoch.toString(),
                itemId: item['itemId']?.toString() ?? "",
                name: item['name']?.toString() ?? "Unknown",
                price: ((item['price'] as num?)?.toDouble()) ?? 0.0,
                actualPrice: ((item['actualPrice'] as num?)?.toDouble()) ?? 0.0,
                qty: ((item['qty'] as num?)?.toInt()) ?? 1,
                profit: ((item['profit'] as num?)?.toDouble()) ?? 0.0,
                date: DateTime.tryParse(item['date']?.toString() ?? "") ?? DateTime.now(),
                status: item['status']?.toString() ?? "Sold",
                billId: item['billId']?.toString(),
                category: item['category']?.toString() ?? "General",
                subCategory: item['subCategory']?.toString() ?? "N/A",
                size: item['size']?.toString() ?? "N/A",
                weight: item['weight']?.toString() ?? "N/A",
                imagePath: item['imagePath']?.toString(),
              ));
            }
          }
        }

        // Restore Expenses
        if (backupData.containsKey('expenses') && backupData['expenses'] is List) {
          final box = Hive.box<ExpenseItem>('expensesBox');
          await box.clear();
          for (var item in backupData['expenses']) {
            if (item is Map) {
              box.put(item['id'], ExpenseItem(
                id: item['id']?.toString() ?? DateTime.now().millisecondsSinceEpoch.toString(),
                title: item['title']?.toString() ?? "Unknown",
                amount: ((item['amount'] as num?)?.toDouble()) ?? 0.0,
                date: DateTime.tryParse(item['date']?.toString() ?? "") ?? DateTime.now(),
                category: item['category']?.toString() ?? "General",
              ));
            }
          }
        }

        // Restore Cart
        if (backupData.containsKey('cart') && backupData['cart'] is List) {
          final box = Hive.box<SaleRecord>('cartBox');
          await box.clear();
          for (var item in backupData['cart']) {
            if (item is Map) {
              box.put(item['id'], SaleRecord(
                id: item['id']?.toString() ?? DateTime.now().millisecondsSinceEpoch.toString(),
                itemId: item['itemId']?.toString() ?? "",
                name: item['name']?.toString() ?? "Unknown",
                price: ((item['price'] as num?)?.toDouble()) ?? 0.0,
                actualPrice: ((item['actualPrice'] as num?)?.toDouble()) ?? 0.0,
                qty: ((item['qty'] as num?)?.toInt()) ?? 1,
                profit: ((item['profit'] as num?)?.toDouble()) ?? 0.0,
                date: DateTime.tryParse(item['date']?.toString() ?? "") ?? DateTime.now(),
                status: item['status']?.toString() ?? "Cart",
                billId: item['billId']?.toString(),
                category: item['category']?.toString() ?? "General",
                subCategory: item['subCategory']?.toString() ?? "N/A",
                size: item['size']?.toString() ?? "N/A",
                weight: item['weight']?.toString() ?? "N/A",
                imagePath: item['imagePath']?.toString(),
              ));
            }
          }
        }

        // Restore Credits
        if (backupData.containsKey('credits') && backupData['credits'] is List) {
          final box = Hive.box<CreditRecord>('creditsBox');
          await box.clear();
          for (var item in backupData['credits']) {
            if (item is Map) {
              box.put(item['id'], CreditRecord(
                id: item['id']?.toString() ?? DateTime.now().millisecondsSinceEpoch.toString(),
                name: item['name']?.toString() ?? "Unknown",
                phone: item['phone']?.toString() ?? "",
                amount: ((item['amount'] as num?)?.toDouble()) ?? 0.0,
                date: DateTime.tryParse(item['date']?.toString() ?? "") ?? DateTime.now(),
                type: item['type']?.toString() ?? "To Pay",
                isSettled: item['isSettled'] == true,
                description: item['description']?.toString(),
                dueDate: item['dueDate'] != null ? DateTime.tryParse(item['dueDate'].toString()) : null,
                paidAmount: ((item['paidAmount'] as num?)?.toDouble()) ?? 0.0,
                logs: (item['logs'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
              ));
            }
          }
        }

        // Restore Damages
        if (backupData.containsKey('damages') && backupData['damages'] is List) {
          final box = Hive.box<DamageRecord>('damageBox');
          await box.clear();
          for (var item in backupData['damages']) {
            if (item is Map) {
              box.put(item['id'], DamageRecord(
                id: item['id']?.toString() ?? DateTime.now().millisecondsSinceEpoch.toString(),
                itemId: item['itemId']?.toString() ?? "",
                itemName: item['itemName']?.toString() ?? (item['name']?.toString() ?? "Unknown"),
                qty: ((item['qty'] as num?)?.toInt()) ?? 0,
                lossAmount: ((item['lossAmount'] as num?)?.toDouble()) ?? 0.0,
                reason: item['reason']?.toString() ?? "",
                date: DateTime.tryParse(item['date']?.toString() ?? "") ?? DateTime.now(),
              ));
            }
          }
        }

        // Restore Settings
        if (backupData.containsKey('settings') && backupData['settings'] is Map) {
          final box = Hive.box('settingsBox');
          await box.clear();
          final settings = Map<String, dynamic>.from(backupData['settings']);
          
          // Restore Logo Image if present
          if (settings.containsKey('logo_base64')) {
            try {
              final String base64Image = settings['logo_base64'];
              if (base64Image.isNotEmpty) {
                final bytes = base64Decode(base64Image);
                final dir = await getApplicationDocumentsDirectory();
                final file = File('${dir.path}/restored_logo_${DateTime.now().millisecondsSinceEpoch}.png');
                await file.writeAsBytes(bytes);
                
                settings['logoPath'] = file.path; 
              }
            } catch (e) {
              AppLogger.error("Error restoring logo", error: e);
            }
            settings.remove('logo_base64'); 
          }

          settings.forEach((key, value) {
            box.put(key, value);
          });
        }
        return true;
      } catch (e, stackTrace) {
        AppLogger.error("Critical error during backup import", error: e, stackTrace: stackTrace);
        return false;
      }
    }
    return false;
  }

  static Future<Map<String, dynamic>> _prepareSettingsForExport(Box settingsBox) async {
    final Map<String, dynamic> settingsMap = settingsBox.toMap().map((k, v) => MapEntry(k.toString(), v));
    
    // Retrieve and encode logo if exists
    if (settingsMap.containsKey('logoPath')) {
      final String? path = settingsMap['logoPath'] as String?;
      if (path != null && path.isNotEmpty) {
        final file = File(path);
        if (await file.exists()) {
          try {
            final bytes = await file.readAsBytes();
            final base64Image = base64Encode(bytes);
            settingsMap['logo_base64'] = base64Image;
          } catch (e) {
            AppLogger.error("Failed to encode logo", error: e);
          }
        }
      }
    }
    return settingsMap;
  }
}
