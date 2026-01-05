// lib/data/repositories/data_store.dart
import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:hello_world/data/models/inventory_model.dart';
import 'package:hello_world/data/models/sale_model.dart';
import 'package:hello_world/data/models/expense_model.dart';
import '../../shared/utils/formatting.dart';

class DataStore extends ChangeNotifier {
  static final DataStore _instance = DataStore._internal();
  factory DataStore() => _instance;
  DataStore._internal();

  Box<InventoryItem> get _inventoryBox =>
      Hive.box<InventoryItem>('inventoryBox');
  Box<ExpenseItem> get _expensesBox => Hive.box<ExpenseItem>('expensesBox');
  Box<SaleRecord> get _historyBox => Hive.box<SaleRecord>('historyBox');
  Box get _settingsBox => Hive.box('settingsBox');

  // === BACKUP LOGIC (REAL DATA) ===
  Map<String, dynamic> generateBackupPayload() {
    return {
      'backup_date': DateTime.now().toIso8601String(),
      'shop_name': shopName,
      'owner_name': ownerName,
      'phone': phone,
      'address': address,
      'inventory_count': _inventoryBox.length,
      'inventory': _inventoryBox.values.map((item) => {
        'id': item.id,
        'name': item.name,
        'price': item.price,
        'stock': item.stock,
        'description': item.description,
        'barcode': item.barcode,
      }).toList(),
      'history': _historyBox.values.map((h) => {
        'id': h.id,
        'itemId': h.itemId,
        'name': h.name,
        'price': h.price,
        'actualPrice': h.actualPrice,
        'qty': h.qty,
        'profit': h.profit,
        'date': h.date.toIso8601String(),
        'status': h.status,
      }).toList(),
      'expenses': _expensesBox.values.map((e) => {
        'id': e.id,
        'title': e.title,
        'amount': e.amount,
        'date': e.date.toIso8601String(),
        'category': e.category,
      }).toList(),
    };
  }

  Future<void> restoreFromBackup(Map<String, dynamic> data) async {
    // 1. Clear current boxes
    await _inventoryBox.clear();
    await _historyBox.clear();
    await _expensesBox.clear();

    // 2. Restore Inventory
    final List<dynamic> inv = data['inventory'] ?? [];
    for (var itemData in inv) {
      final item = InventoryItem(
        id: itemData['id'],
        name: itemData['name'],
        price: (itemData['price'] as num).toDouble(),
        stock: (itemData['stock'] as num).toInt(),
        description: itemData['description'],
        barcode: itemData['barcode'] ?? "N/A",
      );
      await _inventoryBox.put(item.id, item);
    }

    // 3. Restore History & Expenses
    final List<dynamic> hist = data['history'] ?? [];
    for (var h in hist) {
      final sale = SaleRecord(
        id: h['id'],
        itemId: h['itemId'] ?? "",
        name: h['name'],
        price: (h['price'] as num).toDouble(),
        actualPrice: (h['actualPrice'] as num).toDouble(),
        qty: (h['qty'] as num).toInt(),
        profit: (h['profit'] as num).toDouble(),
        date: DateTime.tryParse(h['date']?.toString() ?? "") ?? DateTime.now(),
        status: h['status'] ?? "Sold",
      );
      await _historyBox.put(sale.id, sale);
    }

    final List<dynamic> exp = data['expenses'] ?? [];
    for (var e in exp) {
      final expense = ExpenseItem(
        id: e['id'],
        title: e['title'],
        amount: (e['amount'] as num).toDouble(),
        date: DateTime.tryParse(e['date']?.toString() ?? "") ?? DateTime.now(),
        category: e['category'] ?? "General",
      );
      await _expensesBox.put(expense.id, expense);
    }

    // 4. Restore Profile
    await updateProfile(
      data['owner_name'] ?? ownerName,
      data['shop_name'] ?? shopName,
      data['phone'] ?? phone,
      data['address'] ?? address,
    );

    notifyListeners();
  }

  // === 1. INVENTORY (STILL USES HIVE) ===
  List<InventoryItem> get inventory => _inventoryBox.values.toList();

  void addInventoryItem(InventoryItem item) {
    _inventoryBox.put(item.id, item);
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
  List<ExpenseItem> get _allExpenses => _expensesBox.values.toList();

  List<ExpenseItem> getExpensesForDate(DateTime date) {
    return _allExpenses.where((e) => _isSameDay(date, e.date)).toList();
  }


  // Correct Helper
  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  // Re-implementing logic correctly inside methods
  List<ExpenseItem> get todayExpenses => _allExpenses
      .where((e) => _isSameDay(DateTime.now(), e.date))
      .toList();
  List<ExpenseItem> get yesterdayExpenses => _allExpenses
      .where(
        (e) => _isSameDay(
          DateTime.now().subtract(const Duration(days: 1)),
          e.date,
        ),
      )
      .toList();

  void addExpense(ExpenseItem expense) {
    _expensesBox.put(expense.id, expense);
    notifyListeners();
  }

  void updateExpense(ExpenseItem expense) {
    expense.save();
    notifyListeners();
  }

  void deleteExpense(String id, {bool isToday = true}) {
    _expensesBox.delete(id);
    notifyListeners();
  }

  double getTotalExpenses() {
    return todayExpenses.fold(0.0, (sum, item) => sum + item.amount) +
        yesterdayExpenses.fold(0.0, (sum, item) => sum + item.amount);
  }

  double getTotalExpensesForDate(DateTime date) {
    var list = _allExpenses.where((e) => _isSameDay(date, e.date)).toList();
    return list.fold(0.0, (sum, item) => sum + item.amount);
  }

  // === 3. HISTORY & REFUND (FIXED) ===
  List<SaleRecord> get historyItems {
    var list = _historyBox.values.toList();
    list.sort((a, b) => b.id.compareTo(a.id));
    return list;
  }

  void addHistoryItem(SaleRecord item) {
    _historyBox.put(item.id, item);
    notifyListeners();
  }

  void updateHistoryItem(SaleRecord oldItem, SaleRecord newData) {
    // 1. Calculate new Profit
    double newProfit = (newData.price - oldItem.actualPrice) * newData.qty;

    // 2. Prepare updated data
    oldItem.name = newData.name;
    oldItem.price = newData.price;
    oldItem.qty = newData.qty;
    oldItem.profit = newProfit;

    // 3. Stock Adjustment
    int qtyDiff = oldItem.qty - newData.qty;

    if (qtyDiff != 0 && oldItem.itemId.isNotEmpty) {
      try {
        final invItem = _inventoryBox.values.firstWhere((i) => i.id == oldItem.itemId);
        invItem.stock += qtyDiff;
        invItem.save();
      } catch (e) {
        print("Stock adjustment failed during history edit: $e");
      }
    }

    oldItem.save();
    notifyListeners();
  }

  void deleteHistoryItem(String id) {
    _historyBox.delete(id);
    notifyListeners();
  }

  // === FIX: SAFE REFUND LOGIC (Supports Partial) ===
  void refundSale(SaleRecord historyItem, {int? refundQty}) {
    if (historyItem.status == "Refunded") return;

    int totalQty = historyItem.qty;
    int qtyToRefund = refundQty ?? totalQty;
    if (qtyToRefund > totalQty) qtyToRefund = totalQty;

    if (qtyToRefund < totalQty) {
      // 1. Partial Refund: Update original to show remaining items
      int remainingQty = totalQty - qtyToRefund;
      historyItem.qty = remainingQty;
      historyItem.profit = (historyItem.price - historyItem.actualPrice) * remainingQty;
      historyItem.save();

      // 2. Create new record for the refunded part
      final refundPart = SaleRecord(
        id: "${historyItem.id}_ref_${DateTime.now().millisecondsSinceEpoch}",
        itemId: historyItem.itemId,
        name: historyItem.name,
        price: historyItem.price,
        actualPrice: historyItem.actualPrice,
        qty: qtyToRefund,
        profit: 0.0,
        date: DateTime.now(),
        status: "Refunded",
      );
      _historyBox.put(refundPart.id, refundPart);
    } else {
      // Full Refund
      historyItem.status = "Refunded";
      historyItem.profit = 0.0;
      historyItem.save();
    }

    // 3. Stock Restore logic
    if (historyItem.itemId.isNotEmpty) {
      try {
        final inventoryItem = _inventoryBox.values.firstWhere((i) => i.id == historyItem.itemId);
        inventoryItem.stock += qtyToRefund;
        inventoryItem.save();
      } catch (e) {
        print("Stock restore failed: $e");
      }
    }

    notifyListeners();
  }

  // === 4. ANALYTICS (REFACTORED & OPTIMIZED) ===
  Map<String, dynamic> getAnalytics(String type) {
    if (type == "Weekly") return _getWeeklyData();
    if (type == "Monthly") return _getMonthlyData();
    if (type == "Annual") return _getAnnualData();
    return _getWeeklyData();
  }

  List<SaleRecord> get _validHistory => historyItems.where((h) => h.status != "Refunded").toList();

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
        if (_isSameDay(date, item.date)) {
          daySales += (item.price * item.qty);
          dayItemProfit += item.profit;
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
        if (item.date.isAfter(start) && item.date.isBefore(end)) {
          periodSales += (item.price * item.qty);
          periodItemProfit += item.profit;
        }
      }

      for (var exp in _allExpenses) {
        if (exp.date.isAfter(start) && exp.date.isBefore(end)) {
          periodExpenses += exp.amount;
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
        if (item.date.year == currentYear && item.date.month == m) {
          monthSales += (item.price * item.qty);
          monthItemProfit += item.profit;
        }
      }

      for (var exp in _allExpenses) {
        if (exp.date.year == currentYear && exp.date.month == m) {
          monthExpenses += exp.amount;
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

  Future<void> updateProfile(String name, String shop, String phone, String address) async {
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

  // === 7. CART SYSTEM (IN-MEMORY) ===
  final List<SaleRecord> _cart = [];
  List<SaleRecord> get cart => List.unmodifiable(_cart);

  void addToCart(SaleRecord item) {
    _cart.add(item);
    notifyListeners();
  }

  void removeFromCart(int index) {
    if (index >= 0 && index < _cart.length) {
      _cart.removeAt(index);
      notifyListeners();
    }
  }

  void clearCart() {
    _cart.clear();
    notifyListeners();
  }

  double get cartTotal => _cart.fold(0, (sum, item) => sum + (item.price * item.qty));
  int get cartCount => _cart.fold(0, (sum, item) => sum + item.qty);

  Future<void> checkoutCart() async {
    final String billId = "bill_${DateTime.now().millisecondsSinceEpoch}";
    
    for (var item in _cart) {
      item.billId = billId;
      // 1. Save to History
      _historyBox.put(item.id, item);

      // 2. Adjust Stock
      try {
        final invItem = _inventoryBox.values.firstWhere((i) => i.id == item.itemId);
        invItem.stock -= item.qty;
        invItem.save();
      } catch (e) {
        print("Stock update failed for cart item ${item.name}: $e");
      }
    }
    _cart.clear();
    notifyListeners();
  }
}
