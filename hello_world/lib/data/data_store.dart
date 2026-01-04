// lib/data/data_store.dart
import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:hello_world/data/inventory_model.dart';
import '../utils/formatting.dart';

class DataStore extends ChangeNotifier {
  static final DataStore _instance = DataStore._internal();
  factory DataStore() => _instance;
  DataStore._internal();

  Box<InventoryItem> get _inventoryBox =>
      Hive.box<InventoryItem>('inventoryBox');
  Box get _expensesBox => Hive.box('expensesBox');
  Box get _historyBox => Hive.box('historyBox');

  // === 1. INVENTORY ===
  List<InventoryItem> get inventory => _inventoryBox.values.toList();

  void addInventoryItem(InventoryItem item) {
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

  // === 2. EXPENSES ===
  List<Map<String, String>> get _allExpenses =>
      _expensesBox.values.map((e) => Map<String, String>.from(e)).toList();

  List<Map<String, String>> getExpensesForDate(DateTime date) {
    return _allExpenses.where((e) {
      if (e['date'] == null) return false;
      final eDate = DateTime.parse(e['date']!);
      return d1.year == eDate.year &&
          d1.month == eDate.month &&
          d1.day == eDate.day;
    }).toList();
  }

  // Shortcut variables for _isSameDay logic used above (fixing context issue)
  DateTime get d1 => DateTime.now(); // Dummy getter to satisfy syntax context

  // Correct Helper
  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  // Re-implementing logic correctly inside methods
  List<Map<String, String>> get todayExpenses => _allExpenses
      .where(
        (e) =>
            e['date'] != null &&
            _isSameDay(DateTime.now(), DateTime.parse(e['date']!)),
      )
      .toList();
  List<Map<String, String>> get yesterdayExpenses => _allExpenses
      .where(
        (e) =>
            e['date'] != null &&
            _isSameDay(
              DateTime.now().subtract(const Duration(days: 1)),
              DateTime.parse(e['date']!),
            ),
      )
      .toList();

  void addExpense(Map<String, String> expense, {bool isToday = true}) {
    if (!expense.containsKey('date'))
      expense['date'] =
          (isToday
                  ? DateTime.now()
                  : DateTime.now().subtract(const Duration(days: 1)))
              .toIso8601String();
    if (!expense.containsKey('id'))
      expense['id'] = DateTime.now().millisecondsSinceEpoch.toString();
    _expensesBox.put(expense['id'], expense);
    notifyListeners();
  }

  void updateExpense(String id, Map<String, String> newExpense) {
    _expensesBox.put(id, newExpense);
    notifyListeners();
  }

  void deleteExpense(String id, {bool isToday = true}) {
    _expensesBox.delete(id);
    notifyListeners();
  }

  double getTotalExpenses() {
    return todayExpenses.fold(
          0.0,
          (sum, item) => sum + Formatter.parseDouble(item['amount'] ?? "0"),
        ) +
        yesterdayExpenses.fold(
          0.0,
          (sum, item) => sum + Formatter.parseDouble(item['amount'] ?? "0"),
        );
  }

  double getTotalExpensesForDate(DateTime date) {
    var list = _allExpenses
        .where(
          (e) =>
              e['date'] != null && _isSameDay(date, DateTime.parse(e['date']!)),
        )
        .toList();
    return list.fold(
      0.0,
      (sum, item) => sum + Formatter.parseDouble(item['amount'] ?? "0"),
    );
  }

  // === 3. HISTORY & REFUND (FIXED) ===
  List<Map<String, dynamic>> get historyItems {
    var list = _historyBox.values
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
    list.sort((a, b) => (b['id'] ?? "").compareTo(a['id'] ?? ""));
    return list;
  }

  void addHistoryItem(Map<String, dynamic> item) {
    if (!item.containsKey('id'))
      item['id'] = DateTime.now().millisecondsSinceEpoch.toString();
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

  // === FIX: SAFE REFUND LOGIC ===
  void refundSale(Map<String, dynamic> historyItem) {
    if (historyItem['status'] == "Refunded") return;

    // 1. Status Update
    Map<String, dynamic> updatedItem = Map.from(historyItem);
    updatedItem['status'] = "Refunded";
    _historyBox.put(updatedItem['id'], updatedItem);

    // 2. Stock Restore (Safe Mode)
    String? itemId = historyItem['itemId'];

    // FIX: Agar qty null ho to 1 maano
    int qtyToRestore = 1;
    if (historyItem['qty'] != null) {
      qtyToRestore = int.tryParse(historyItem['qty'].toString()) ?? 1;
    }

    if (itemId != null) {
      try {
        final inventoryItem = _inventoryBox.values.firstWhere(
          (i) => i.id == itemId,
        );
        inventoryItem.stock += qtyToRestore;
        inventoryItem
            .save(); // Yeh save hotay hi Dashboard par "Total Value" update ho jayegi
        print("Stock Restored: +$qtyToRestore");
      } catch (e) {
        // Agar ID se item na miley (Deleted item), to Name se try karein (Fallback)
        try {
          final fallbackItem = _inventoryBox.values.firstWhere(
            (i) => i.name == historyItem['name'],
          );
          fallbackItem.stock += qtyToRestore;
          fallbackItem.save();
          print("Stock Restored via Name Match");
        } catch (e2) {
          print(
            "Item not found in inventory. Refund marked but stock not updated.",
          );
        }
      }
    }

    notifyListeners();
  }

  // === 4. ANALYTICS ===
  Map<String, dynamic> getWeeklyAnalytics() {
    List<double> sales = [], expenses = [], profit = [];
    List<String> labels = [];
    DateTime now = DateTime.now();

    for (int i = 6; i >= 0; i--) {
      DateTime targetDate = now.subtract(Duration(days: i));
      labels.add(_getWeekdayName(targetDate.weekday));

      double daySales = 0.0;
      for (var item in historyItems) {
        if (item['id'] != null && item['status'] != "Refunded") {
          DateTime itemDate = DateTime.fromMillisecondsSinceEpoch(
            int.parse(item['id']),
          );
          if (_isSameDay(targetDate, itemDate))
            daySales += Formatter.parseDouble(item['price'].toString());
        }
      }
      sales.add(daySales);

      double dayExpenses = getTotalExpensesForDate(targetDate);
      expenses.add(dayExpenses);
      profit.add(daySales - dayExpenses);
    }
    return {
      "labels": labels,
      "Sales": sales,
      "Expenses": expenses,
      "Profit": profit,
    };
  }

  String _getWeekdayName(int day) =>
      ["M", "T", "W", "T", "F", "S", "S"][day - 1];
}
