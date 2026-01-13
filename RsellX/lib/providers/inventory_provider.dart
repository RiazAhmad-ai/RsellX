import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:rsellx/data/models/inventory_model.dart';
import 'package:rsellx/data/models/damage_model.dart';
import 'package:rsellx/core/utils/app_logger.dart';

class InventoryProvider extends ChangeNotifier {
  List<InventoryItem> _cachedInventory = [];
  bool _inventoryDirty = true;
  
  // Stream subscriptions for proper cleanup
  StreamSubscription? _inventoryBoxSubscription;
  StreamSubscription? _damageBoxSubscription;

  InventoryProvider() {
    _initializeListeners();
  }
  
  void _initializeListeners() {
    try {
      if (Hive.isBoxOpen('inventoryBox')) {
        _inventoryBoxSubscription = _inventoryBox.watch().listen((_) {
          _inventoryDirty = true;
          _clearComputedCache();
          notifyListeners();
        }, onError: (error) {
          AppLogger.error('InventoryProvider inventory stream error', error: error);
        });
      }
      
      if (Hive.isBoxOpen('damageBox')) {
        _damageBoxSubscription = _damageBox.watch().listen((_) {
          _clearComputedCache();
          notifyListeners();
        }, onError: (error) {
          AppLogger.error('InventoryProvider damage stream error', error: error);
        });
      }
      
      // Initial load
      _refreshCache();
    } catch (e) {
      AppLogger.error('InventoryProvider initialization error', error: e);
    }
  }
  
  @override
  void dispose() {
    _inventoryBoxSubscription?.cancel();
    _damageBoxSubscription?.cancel();
    super.dispose();
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
    _rebuildBarcodeIndex();
    _inventoryDirty = false;
  }

  void addInventoryItem(InventoryItem item) {
    _inventoryBox.put(item.id, item);
    // Stream subscription will trigger notifyListeners
  }

  void updateInventoryItem(InventoryItem item) {
    item.save();
    // Stream subscription will trigger notifyListeners
  }

  void deleteInventoryItem(InventoryItem item) {
    item.delete();
    // Stream subscription will trigger notifyListeners
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

  // === COMPUTED VALUE CACHE ===
  double? _cachedTotalStockValue;
  double? _cachedTotalDamageLoss;
  int? _cachedLowStockCount;
  
  // === BARCODE INDEX ===
  final Map<String, InventoryItem> _barcodeIndex = {};

  void _rebuildBarcodeIndex() {
    _barcodeIndex.clear();
    for (var item in _cachedInventory) {
      if (item.barcode.isNotEmpty) {
        _barcodeIndex[item.barcode] = item;
      }
    }
  }

  void _clearComputedCache() {
    _cachedTotalStockValue = null;
    _cachedTotalDamageLoss = null;
    _cachedLowStockCount = null;
    // Index rebuild needed when inventory changes
    _rebuildBarcodeIndex();
  }

  double getTotalStockValue() {
    if (_cachedTotalStockValue != null) return _cachedTotalStockValue!;
    
    // Perform calculation on cached list which is faster than box iteration
    double total = 0.0;
    for (var item in inventory) {
      total += (item.price * item.stock);
    }
    _cachedTotalStockValue = total;
    return total;
  }

  double getTotalDamageLoss() {
    if (_cachedTotalDamageLoss != null) return _cachedTotalDamageLoss!;
    
    _cachedTotalDamageLoss = _damageBox.values.fold<double>(0.0, (double sum, item) => sum + item.lossAmount);
    return _cachedTotalDamageLoss!;
  }

  int getLowStockCount() {
    if (_cachedLowStockCount != null) return _cachedLowStockCount!;
    
    _cachedLowStockCount = inventory.where((item) => item.stock < item.lowStockThreshold).length;
    return _cachedLowStockCount!;
  }

  Future<void> clearAllData() async {
    await _inventoryBox.clear();
    await _damageBox.clear();
  }

  InventoryItem? findItemByBarcode(String barcode) {
    if (_inventoryDirty) _refreshCache();
    // O(1) Lookup
    return _barcodeIndex[barcode];
  }
}
