import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:hello_world/data/inventory_model.dart';
import '../utils/formatting.dart';

class DataStore extends ChangeNotifier {
  // Singleton
  static final DataStore _instance = DataStore._internal();
  factory DataStore() => _instance;
  DataStore._internal();

  // Hive Boxes
  Box<InventoryItem> get _inventoryBox => Hive.box<InventoryItem>('inventoryBox');
  Box get _expensesBox => Hive.box('expensesBox');
  Box get _historyBox => Hive.box('historyBox');

  // === INVENTORY DATA ===
  List<InventoryItem> get inventory => _inventoryBox.values.toList();

  void addInventoryItem(InventoryItem item) {
    _inventoryBox.add(item);
    notifyListeners();
  }

  // Legacy support if UI passes Map
  void addInventoryItemFromMap(Map<String, dynamic> itemMap) {
    final item = InventoryItem(
        id: itemMap['id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
        name: itemMap['name'],
        price: Formatter.parseDouble(itemMap['price'].toString()),
        stock: Formatter.parseInt(itemMap['stock'].toString()),
        embeddings: [], // Initialize empty if not provided
    );
    _inventoryBox.add(item);
    notifyListeners();
  }

  void updateInventoryItem(InventoryItem item) {
    item.save();
    notifyListeners();
  }

  void deleteInventoryItem(InventoryItem item) {
    item.delete();
    notifyListeners();
  }

  // Method used by InventoryScreen mainly via direct box access, but good to have here.

  double getTotalStockValue() {
    double total = 0.0;
    for (var item in _inventoryBox.values) {
      total += (item.price * item.stock);
    }
    return total;
  }

  int getLowStockCount() {
    return _inventoryBox.values.where((item) => item.stock < 5).length;
  }

  // === EXPENSE DATA ===

  List<Map<String, String>> get _allExpenses {
      // Return typed list
      return _expensesBox.values.map((e) => Map<String, String>.from(e)).toList();
  }

  List<Map<String, String>> get todayExpenses {
    final now = DateTime.now();
    final todayStr = "${now.year}-${now.month}-${now.day}";
    return _allExpenses.where((e) {
        if (e['date'] == null) return false;
        final date = DateTime.parse(e['date']!);
        return "${date.year}-${date.month}-${date.day}" == todayStr;
    }).toList();
  }

  List<Map<String, String>> get yesterdayExpenses {
    final now = DateTime.now().subtract(const Duration(days: 1));
    final yesterdayStr = "${now.year}-${now.month}-${now.day}";
    return _allExpenses.where((e) {
        if (e['date'] == null) return false;
        final date = DateTime.parse(e['date']!);
        return "${date.year}-${date.month}-${date.day}" == yesterdayStr;
    }).toList();
  }

  void addExpense(Map<String, String> expense, {bool isToday = true}) {
    // Add date field if missing
    if (!expense.containsKey('date')) {
        final date = isToday ? DateTime.now() : DateTime.now().subtract(const Duration(days: 1));
        expense['date'] = date.toIso8601String();
    }
    // Ensure ID
    if (!expense.containsKey('id')) {
        expense['id'] = DateTime.now().millisecondsSinceEpoch.toString();
    }

    _expensesBox.put(expense['id'], expense);
    notifyListeners();
  }

  void updateExpense(String id, Map<String, String> newExpense, {bool isToday = true}) {
     // Ensure date is preserved or updated
     if (!newExpense.containsKey('date')) {
         final existing = _expensesBox.get(id);
         if (existing != null) {
             newExpense['date'] = existing['date'];
         } else {
             final date = isToday ? DateTime.now() : DateTime.now().subtract(const Duration(days: 1));
             newExpense['date'] = date.toIso8601String();
         }
     }
    _expensesBox.put(id, newExpense);
    notifyListeners();
  }

  void deleteExpense(String id, {bool isToday = true}) {
    _expensesBox.delete(id);
    notifyListeners();
  }

  double getTotalExpenses() {
    double total = 0.0;
    for (var item in todayExpenses) {
      total += Formatter.parseDouble(item['amount'] ?? "0");
    }
    for (var item in yesterdayExpenses) {
      total += Formatter.parseDouble(item['amount'] ?? "0");
    }
    return total;
  }

  // === HISTORY DATA ===

  List<Map<String, dynamic>> get historyItems {
      var list = _historyBox.values.map((e) => Map<String, dynamic>.from(e)).toList();

      // Sort by ID descending (Latest first)
      list.sort((a, b) => (b['id'] ?? "").compareTo(a['id'] ?? ""));
      return list;
  }

  void addHistoryItem(Map<String, dynamic> item) {
    if (!item.containsKey('id')) {
        item['id'] = DateTime.now().millisecondsSinceEpoch.toString();
    }
    _historyBox.put(item['id'], item);
    notifyListeners();
  }

  void updateHistoryItem(String id, Map<String, dynamic> item) {
    _historyBox.put(id, item);
    notifyListeners();
  }

  void deleteHistoryItem(String id) {
    _historyBox.delete(id);
    notifyListeners();
  }

  double getTotalSales() {
    double total = 0.0;
     for (var item in historyItems) {
      if (item['status'] != "Refunded") {
         total += Formatter.parseDouble(item['price'].toString());
      }
    }
    return total;
  }
}
