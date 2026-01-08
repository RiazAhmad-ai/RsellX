import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import '../data/models/supplier_model.dart';
import '../data/models/inventory_model.dart';

class SupplierProvider extends ChangeNotifier {
  SupplierProvider() {
    _suppliersBox.watch().listen((_) => notifyListeners());
    _purchasesBox.watch().listen((_) => notifyListeners());
  }

  Box<Supplier> get _suppliersBox => Hive.box<Supplier>('suppliersBox');
  Box<PurchaseRecord> get _purchasesBox => Hive.box<PurchaseRecord>('purchasesBox');
  Box<InventoryItem> get _inventoryBox => Hive.box<InventoryItem>('inventoryBox');

  List<Supplier> get allSuppliers => _suppliersBox.values.toList();
  List<PurchaseRecord> get allPurchases => _purchasesBox.values.toList()..sort((a, b) => b.date.compareTo(a.date));

  void addSupplier(Supplier supplier) {
    _suppliersBox.put(supplier.id, supplier);
  }

  void updateSupplier(Supplier supplier) {
    supplier.save();
  }

  void deleteSupplier(Supplier supplier) {
    supplier.delete();
  }

  void addPurchase(PurchaseRecord record) {
    _purchasesBox.put(record.id, record);
    
    // Update Inventory
    final item = _inventoryBox.get(record.itemId);
    if (item != null) {
      item.stock += record.qty; // Buying increases stock
      item.save();
    }

    // Update Supplier Balance (if buying on credit)
    final supplier = _suppliersBox.get(record.supplierId);
    if (supplier != null) {
      supplier.balance += (record.purchasePrice * record.qty);
      supplier.save();
    }
  }

  void paySupplier(String supplierId, double amount) {
    final supplier = _suppliersBox.get(supplierId);
    if (supplier != null) {
      supplier.balance -= amount;
      supplier.save();
    }
  }
}
