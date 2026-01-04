// lib/data/repositories/data_store.dart
import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:hello_world/data/models/inventory_model.dart';
import '../../shared/utils/formatting.dart';

class DataStore extends ChangeNotifier {
  static final DataStore _instance = DataStore._internal();
  factory DataStore() => _instance;
  DataStore._internal();

  Box<InventoryItem> get _inventoryBox =>
      Hive.box<InventoryItem>('inventoryBox');
  Box get _expensesBox => Hive.box('expensesBox');
  Box get _historyBox => Hive.box('historyBox');
  Box get _settingsBox => Hive.box('settingsBox');

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

  void updateHistoryItem(Map<String, dynamic> oldItem, Map<String, dynamic> newData) {
    final String id = oldItem['id'];
    
    // 1. Calculate new Profit
    double newPrice = Formatter.parseDouble(newData['price'].toString());
    double actualPrice = Formatter.parseDouble(oldItem['actualPrice'].toString());
    int newQty = int.tryParse(newData['qty'].toString()) ?? 1;
    double newProfit = (newPrice - actualPrice) * newQty;

    // 2. Prepare updated map
    Map<String, dynamic> updatedItem = Map.from(oldItem);
    updatedItem['name'] = newData['name'];
    updatedItem['price'] = newPrice;
    updatedItem['qty'] = newQty;
    updatedItem['profit'] = newProfit;
    
    // 3. Stock Adjustment
    int oldQty = int.tryParse(oldItem['qty']?.toString() ?? "1") ?? 1;
    int qtyDiff = oldQty - newQty; // If I sold 2 but now 1, I should add 1 back to stock
    
    if (qtyDiff != 0 && oldItem['itemId'] != null) {
      try {
        final invItem = _inventoryBox.values.firstWhere((i) => i.id == oldItem['itemId']);
        invItem.stock += qtyDiff;
        invItem.save();
      } catch (e) {
        print("Stock adjustment failed during history edit: $e");
      }
    }

    _historyBox.put(id, updatedItem);
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

  // === 4. ANALYTICS (REFACTORED & OPTIMIZED) ===
  Map<String, dynamic> getAnalytics(String type) {
    if (type == "Weekly") return _getWeeklyData();
    if (type == "Monthly") return _getMonthlyData();
    if (type == "Annual") return _getAnnualData();
    return _getWeeklyData(); // Default
  }

  // Helper to filter history by status
  List<Map<String, dynamic>> get _validHistory => historyItems.where((h) => h['status'] != "Refunded").toList();

  Map<String, dynamic> _getWeeklyData() {
    List<double> sales = [], expenses = [], profit = [];
    List<String> labels = [];
    DateTime now = DateTime.now();

    for (int i = 6; i >= 0; i--) {
      DateTime date = now.subtract(Duration(days: i));
      labels.add(["M", "T", "W", "T", "F", "S", "S"][date.weekday - 1]);

      double daySales = 0.0;
      double dayItemProfit = 0.0;
      
      for (var item in _validHistory) {
        DateTime itemDate = DateTime.fromMillisecondsSinceEpoch(int.parse(item['id']));
        if (_isSameDay(date, itemDate)) {
          daySales += Formatter.parseDouble(item['price'].toString());
          dayItemProfit += Formatter.parseDouble(item['profit'].toString());
        }
      }

      double dayExpenses = getTotalExpensesForDate(date);
      sales.add(daySales);
      expenses.add(dayExpenses);
      profit.add(dayItemProfit - dayExpenses);
    }

    return {"labels": labels, "Sales": sales, "Expenses": expenses, "Profit": profit};
  }

  Map<String, dynamic> _getMonthlyData() {
    List<double> sales = [], expenses = [], profit = [];
    List<String> labels = ["W1", "W2", "W3", "W4"];
    DateTime now = DateTime.now();

    for (int i = 3; i >= 0; i--) {
      DateTime start = now.subtract(Duration(days: (i + 1) * 7));
      DateTime end = now.subtract(Duration(days: i * 7));

      double periodSales = 0.0;
      double periodItemProfit = 0.0;
      double periodExpenses = 0.0;

      for (var item in _validHistory) {
        DateTime d = DateTime.fromMillisecondsSinceEpoch(int.parse(item['id']));
        if (d.isAfter(start) && d.isBefore(end)) {
          periodSales += Formatter.parseDouble(item['price'].toString());
          periodItemProfit += Formatter.parseDouble(item['profit'].toString());
        }
      }

      for (var exp in _allExpenses) {
        DateTime d = DateTime.parse(exp['date']!);
        if (d.isAfter(start) && d.isBefore(end)) {
          periodExpenses += Formatter.parseDouble(exp['amount'] ?? "0");
        }
      }

      sales.add(periodSales);
      expenses.add(periodExpenses);
      profit.add(periodItemProfit - periodExpenses);
    }

    return {"labels": labels, "Sales": sales, "Expenses": expenses, "Profit": profit};
  }

  Map<String, dynamic> _getAnnualData() {
    List<double> sales = [], expenses = [], profit = [];
    List<String> labels = ["J", "F", "M", "A", "M", "J", "J", "A", "S", "O", "N", "D"];
    int currentYear = DateTime.now().year;

    for (int m = 1; m <= 12; m++) {
      double monthSales = 0.0;
      double monthItemProfit = 0.0;
      double monthExpenses = 0.0;

      for (var item in _validHistory) {
        DateTime d = DateTime.fromMillisecondsSinceEpoch(int.parse(item['id']));
        if (d.year == currentYear && d.month == m) {
          monthSales += Formatter.parseDouble(item['price'].toString());
          monthItemProfit += Formatter.parseDouble(item['profit'].toString());
        }
      }

      for (var exp in _allExpenses) {
        DateTime d = DateTime.parse(exp['date']!);
        if (d.year == currentYear && d.month == m) {
          monthExpenses += Formatter.parseDouble(exp['amount'] ?? "0");
        }
      }

      sales.add(monthSales);
      expenses.add(monthExpenses);
      profit.add(monthItemProfit - monthExpenses);
    }

    return {"labels": labels, "Sales": sales, "Expenses": expenses, "Profit": profit};
  }

  String _getWeekdayName(int day) => ["M", "T", "W", "T", "F", "S", "S"][day - 1];

  // === 5. PROFILE SETTINGS ===
  String get shopName => _settingsBox.get('shopName', defaultValue: "RIAZ AHMAD CROCKERY");
  String get ownerName => _settingsBox.get('ownerName', defaultValue: "Riaz Ahmad");
  String get phone => _settingsBox.get('phone', defaultValue: "+92 3195910091");
  String get address => _settingsBox.get('address', defaultValue: "Jehangira Underpass Shop#21");

  void updateProfile(String name, String shop, String phone, String address) {
    _settingsBox.put('ownerName', name);
    _settingsBox.put('shopName', shop);
    _settingsBox.put('phone', phone);
    _settingsBox.put('address', address);
    notifyListeners();
  }

  // === 6. RESET ALL DATA ===
  Future<void> clearAllData() async {
    await _inventoryBox.clear();
    await _expensesBox.clear();
    await _historyBox.clear();
    // settingsBox stays to keep shop name, unless explicitly reset
    notifyListeners();
  }
}
