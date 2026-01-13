
import 'package:hive_flutter/hive_flutter.dart';
import '../../data/models/inventory_model.dart';
import '../../data/models/sale_model.dart';
import '../../data/models/expense_model.dart';
import '../../data/models/credit_model.dart';
import '../../data/models/damage_model.dart';
import 'logger_service.dart';

class DatabaseService {
  static Future<void> init() async {
    try {
      AppLogger.info("Initializing Database...");
      await Hive.initFlutter();
      _registerAdapters();
      
      // Open settings box first to check migration status
      final settingsBox = await Hive.openBox('settingsBox');
      final isMigrated = settingsBox.get('is_migrated_v3', defaultValue: false);
      
      if (!isMigrated) {
        await _migrateData();
        await settingsBox.put('is_migrated_v3', true);
      }
      
      await _openBoxes();
      AppLogger.info("Database Initialized Successfully.");
    } catch (e, stack) {
      AppLogger.error("Critical Database Initialization Failed", error: e, stackTrace: stack);
      rethrow; // Rethrow to let main handle the crash UI if needed
    }
  }

  static void _registerAdapters() {
    try {
      if (!Hive.isAdapterRegistered(0)) Hive.registerAdapter(InventoryItemAdapter());
      if (!Hive.isAdapterRegistered(1)) Hive.registerAdapter(SaleRecordAdapter());
      if (!Hive.isAdapterRegistered(2)) Hive.registerAdapter(ExpenseItemAdapter());
      if (!Hive.isAdapterRegistered(3)) Hive.registerAdapter(CreditRecordAdapter());
      if (!Hive.isAdapterRegistered(4)) Hive.registerAdapter(DamageRecordAdapter());
    } catch (e) {
      AppLogger.error("Adapter Registration Failed", error: e);
    }
  }

  static Future<void> _openBoxes() async {
    // Open boxes in parallel for faster startup
    await Future.wait([
      Hive.openBox<InventoryItem>('inventoryBox'),
      Hive.openBox<SaleRecord>('historyBox'),
      Hive.openBox<SaleRecord>('cartBox'),
      Hive.openBox<ExpenseItem>('expensesBox'),
      Hive.openBox<CreditRecord>('creditsBox'),
      Hive.openBox<DamageRecord>('damageBox'),
      Hive.openBox('settingsBox'),
    ]);

    // Periodically compact boxes to free up disk space
    _compactBoxes();
  }

  static Future<void> _compactBoxes() async {
    // Run compaction in background
    Future.microtask(() async {
      try {
        await Hive.box<InventoryItem>('inventoryBox').compact();
        await Hive.box<SaleRecord>('historyBox').compact();
        // Cart is transient, likely small but safe to compact
        await Hive.box<SaleRecord>('cartBox').compact(); 
      } catch (e) {
        AppLogger.error("Box compaction failed", error: e);
      }
    });
  }

  static Future<void> _migrateData() async {
    // 1. Migrate History
    await _migrateBox('historyBox', (value, key) {
      if (value is Map) {
        return SaleRecord(
          id: value['id']?.toString() ?? key.toString(),
          itemId: value['itemId']?.toString() ?? "",
          name: value['name']?.toString() ?? "Unknown",
          price: (value['price'] as num?)?.toDouble() ?? 0.0,
          actualPrice: (value['actualPrice'] as num?)?.toDouble() ?? 0.0,
          qty: (value['qty'] as num?)?.toInt() ?? 1,
          profit: (value['profit'] as num?)?.toDouble() ?? 0.0,
          date: DateTime.tryParse(value['date']?.toString() ?? "") ?? DateTime.now(),
          status: value['status']?.toString() ?? "Sold",
          billId: value['billId']?.toString(),
          category: value['category']?.toString() ?? "General",
          subCategory: value['subCategory']?.toString() ?? "N/A",
          size: value['size']?.toString() ?? "N/A",
          weight: value['weight']?.toString() ?? "N/A",
          imagePath: value['imagePath']?.toString(),
        );
      }
      return null;
    });

    // 2. Migrate Inventory (and fix broken image paths)
    await _migrateBox('inventoryBox', (value, key) {
      if (value is Map) {
        String? imagePath = value['imagePath']?.toString();
        
        // Fix for the '$fileName' literal bug:
        // If the path contains the literal text '$fileName', it's a shared buggy link.
        // We'll keep it for now but the next time the user edits it, the UI will handle it.
        // Or better: clear it if it's the broken literal to prevent "mass-updating" images.
        if (imagePath != null && imagePath.contains('\$fileName')) {
          imagePath = null; 
        }

        return InventoryItem(
          id: value['id']?.toString() ?? key.toString(),
          name: value['name']?.toString() ?? "Unknown",
          price: (value['price'] as num?)?.toDouble() ?? 0.0,
          stock: (value['stock'] as num?)?.toInt() ?? 0,
          description: value['description']?.toString(),
          barcode: value['barcode']?.toString() ?? "N/A",
          imagePath: imagePath,
          category: value['category']?.toString() ?? "General",
          subCategory: value['subCategory']?.toString() ?? "N/A",
          size: value['size']?.toString() ?? "N/A",
          weight: value['weight']?.toString() ?? "N/A",
          lowStockThreshold: (value['lowStockThreshold'] as num?)?.toInt() ?? 5,
        );
      }
      return null;
    });

    // 3. Migrate Expenses
    await _migrateBox('expensesBox', (value, key) {
      if (value is Map) {
        return ExpenseItem(
          id: value['id']?.toString() ?? key.toString(),
          title: value['title']?.toString() ?? "Unknown",
          amount: (value['amount'] as num?)?.toDouble() ?? 0.0,
          date: DateTime.tryParse(value['date']?.toString() ?? "") ?? DateTime.now(),
          category: value['category']?.toString() ?? "General",
        );
      }
      return null;
    });
  }

  static Future<void> _migrateBox(String boxName, dynamic Function(dynamic value, dynamic key) converter) async {
    var box = await Hive.openBox(boxName);
    final List<dynamic> keys = box.keys.toList();
    bool needsClose = false;

    for (var key in keys) {
      var value = box.get(key);
      if (value is Map) {
        try {
          final newValue = converter(value, key);
          if (newValue != null) {
            await box.put(key, newValue);
          }
        } catch (e) {
          AppLogger.error("Failed to migrate $boxName item $key", error: e);
        }
      }
    }
    
    // We don't necessarily need to close if we are going to open it typed later, 
    // but safe to close here to ensure clean state before typed open.
    await box.close(); 
  }
}
