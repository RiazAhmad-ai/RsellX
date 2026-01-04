import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:hello_world/data/inventory_model.dart'; // Make sure path is correct
import '../utils/formatting.dart';

class DataStore extends ChangeNotifier {
  // Singleton Pattern
  static final DataStore _instance = DataStore._internal();
  factory DataStore() => _instance;
  DataStore._internal();

  // Hive Boxes
  Box<InventoryItem> get _inventoryBox =>
      Hive.box<InventoryItem>('inventoryBox');
  Box get _expensesBox => Hive.box('expensesBox');
  Box get _historyBox => Hive.box('historyBox');

  // ============================
  // === 1. INVENTORY LOGIC ===
  // ============================

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

  // FIXED: Yeh function wapis add kiya hai AlertCard ke liye
  int getLowStockCount() {
    return _inventoryBox.values.where((item) => item.stock < 5).length;
  }

  // ============================
  // === 2. EXPENSE LOGIC ===
  // ============================

  // Helper: Saaray expenses laata hai
  List<Map<String, String>> get _allExpenses {
    return _expensesBox.values.map((e) => Map<String, String>.from(e)).toList();
  }

  // Specific Date ke Expenses (Calendar ke liye)
  List<Map<String, String>> getExpensesForDate(DateTime date) {
    return _allExpenses.where((e) {
      if (e['date'] == null) return false;
      final eDate = DateTime.parse(e['date']!);
      return _isSameDay(date, eDate);
    }).toList();
  }

  // Specific Date ka Total
  double getTotalExpensesForDate(DateTime date) {
    double total = 0.0;
    List<Map<String, String>> list = getExpensesForDate(date);
    for (var item in list) {
      total += Formatter.parseDouble(item['amount'] ?? "0");
    }
    return total;
  }

  // Shortcuts for Today/Yesterday
  List<Map<String, String>> get todayExpenses =>
      getExpensesForDate(DateTime.now());
  List<Map<String, String>> get yesterdayExpenses =>
      getExpensesForDate(DateTime.now().subtract(const Duration(days: 1)));

  // FIXED: 'isToday' parameter wapis add kiya hai
  void addExpense(Map<String, String> expense, {bool isToday = true}) {
    // Agar date nahi hai to khud daalo
    if (!expense.containsKey('date')) {
      final date = isToday
          ? DateTime.now()
          : DateTime.now().subtract(const Duration(days: 1));
      expense['date'] = date.toIso8601String();
    }
    // Agar ID nahi hai to banao
    if (!expense.containsKey('id')) {
      expense['id'] = DateTime.now().millisecondsSinceEpoch.toString();
    }

    _expensesBox.put(expense['id'], expense);
    notifyListeners();
  }

  void updateExpense(
    String id,
    Map<String, String> newExpense, {
    bool isToday = true,
  }) {
    // Date preserve karo agar edit mein nahi aayi
    if (!newExpense.containsKey('date')) {
      final existing = _expensesBox.get(id);
      if (existing != null) {
        newExpense['date'] = existing['date'];
      } else {
        final date = isToday
            ? DateTime.now()
            : DateTime.now().subtract(const Duration(days: 1));
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

  // Total Expenses (Today + Yesterday) - Dashboard ke liye
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

  // ============================
  // === 3. HISTORY & SALES ===
  // ============================

  List<Map<String, dynamic>> get historyItems {
    var list = _historyBox.values
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
    // Latest pehle
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

  // ============================
  // === 4. ANALYTICS (Charts) ===
  // ============================

  Map<String, dynamic> getWeeklyAnalytics() {
    List<double> sales = [];
    List<double> expenses = [];
    List<double> profit = [];
    List<String> labels = [];
    DateTime now = DateTime.now();

    for (int i = 6; i >= 0; i--) {
      DateTime targetDate = now.subtract(Duration(days: i));
      labels.add(_getWeekdayName(targetDate.weekday));

      double daySales = 0.0;
      for (var item in historyItems) {
        if (item['id'] != null) {
          DateTime itemDate = DateTime.fromMillisecondsSinceEpoch(
            int.parse(item['id']),
          );
          if (_isSameDay(targetDate, itemDate) &&
              item['status'] != "Refunded") {
            daySales += Formatter.parseDouble(item['price'].toString());
          }
        }
      }
      sales.add(daySales);

      double dayExpenses = 0.0;
      for (var exp in _allExpenses) {
        if (exp['date'] != null) {
          DateTime expDate = DateTime.parse(exp['date']!);
          if (_isSameDay(targetDate, expDate)) {
            dayExpenses += Formatter.parseDouble(exp['amount'] ?? "0");
          }
        }
      }
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

  // === HELPERS ===
  bool _isSameDay(DateTime d1, DateTime d2) {
    return d1.year == d2.year && d1.month == d2.month && d1.day == d2.day;
  }

  String _getWeekdayName(int day) {
    const days = ["M", "T", "W", "T", "F", "S", "S"];
    return days[day - 1];
  }
}
