import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:rsellx/data/models/inventory_model.dart';
import 'package:rsellx/data/models/damage_model.dart';

class InventoryProvider extends ChangeNotifier {
  List<InventoryItem> _cachedInventory = [];
  bool _inventoryDirty = true;

  InventoryProvider() {
    _inventoryBox.watch().listen((_) {
      _inventoryDirty = true;
      notifyListeners();
    });
    _damageBox.watch().listen((_) {
      notifyListeners();
    });
    // Initial load
    _refreshCache();
  }

  Box<InventoryItem> get _inventoryBox => Hive.box<InventoryItem>('inventoryBox');
  Box<DamageRecord> get _damageBox => Hive.box<DamageRecord>('damageBox');

  List<InventoryItem> get inventory {
    if (_inventoryDirty) {
      _refreshCache();
    }
    return _cachedInventory;
  }

  List<DamageRecord> get damageHistory => _damageBox.values.toList()..sort((a, b) => b.date.compareTo(a.date));

  void _refreshCache() {
    _cachedInventory = _inventoryBox.values.toList();
    _inventoryDirty = false;
  }

  void addInventoryItem(InventoryItem item) {
    _inventoryBox.put(item.id, item);
  }

  void updateInventoryItem(InventoryItem item) {
    item.save();
  }

  void deleteInventoryItem(InventoryItem item) {
    item.delete();
  }

  void addDamageRecord(DamageRecord record) {
    _damageBox.put(record.id, record);
    
    // Deduct from inventory
    final item = _inventoryBox.get(record.itemId);
    if (item != null) {
      item.stock -= record.qty;
      item.save();
    }
  }

  void updateDamageRecord(DamageRecord oldRecord, DamageRecord newRecord) {
    // 1. Restore stock from old record
    final oldItem = _inventoryBox.get(oldRecord.itemId);
    if (oldItem != null) {
      oldItem.stock += oldRecord.qty;
      oldItem.save();
    }

    // 2. Apply stock deduction for new record
    final newItem = _inventoryBox.get(newRecord.itemId);
    if (newItem != null) {
      newItem.stock -= newRecord.qty;
      newItem.save();
    }

    // 3. Update the damage box
    _damageBox.put(newRecord.id, newRecord);
  }

  void deleteDamageRecord(DamageRecord record) {
    // 1. Restore stock
    final item = _inventoryBox.get(record.itemId);
    if (item != null) {
      item.stock += record.qty;
      item.save();
    }

    // 2. Delete from damage box
    record.delete();
  }

  double getTotalStockValue() {
    // Perform calculation on cached list which is faster than box iteration
    double total = 0.0;
    for (var item in inventory) {
      total += (item.price * item.stock);
    }
    return total;
  }

  double getTotalDamageLoss() {
    return _damageBox.values.fold(0.0, (sum, item) => sum + item.lossAmount);
  }

  int getLowStockCount() {
    return inventory.where((item) => item.stock < item.lowStockThreshold).length;
  }

  Future<void> clearAllData() async {
    await _inventoryBox.clear();
    await _damageBox.clear();
  }

  InventoryItem? findItemByBarcode(String barcode) {
    try {
      // Search in memory cache
      return inventory.firstWhere((item) => item.barcode == barcode);
    } catch (_) {
      return null;
    }
  }
}
