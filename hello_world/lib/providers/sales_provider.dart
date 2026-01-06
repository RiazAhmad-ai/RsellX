import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:rsellx/data/models/inventory_model.dart';
import 'package:rsellx/data/models/sale_model.dart';
import 'package:rsellx/data/models/expense_model.dart';

class SalesProvider extends ChangeNotifier {
  SalesProvider() {
    _historyBox.watch().listen((_) {
      notifyListeners();
    });
    _cartBox.watch().listen((_) {
      notifyListeners();
    });
    _expensesBox.watch().listen((_) {
      notifyListeners();
    });
  }

  Box<SaleRecord> get _historyBox => Hive.box<SaleRecord>('historyBox');
  Box<SaleRecord> get _cartBox => Hive.box<SaleRecord>('cartBox');
  Box<InventoryItem> get _inventoryBox => Hive.box<InventoryItem>('inventoryBox');
  Box<ExpenseItem> get _expensesBox => Hive.box<ExpenseItem>('expensesBox');

  // === HISTORY ===
  List<SaleRecord> get historyItems {
    var list = _historyBox.values.toList();
    list.sort((a, b) => b.id.compareTo(a.id));
    return list;
  }

  List<SaleRecord> get _validHistory => historyItems.where((h) => h.status != "Refunded").toList();

  void addHistoryItem(SaleRecord item) {
    _historyBox.put(item.id, item);
    notifyListeners();
  }

  void updateHistoryItem(SaleRecord oldItem, SaleRecord newData) {
    double newProfit = (newData.price - oldItem.actualPrice) * newData.qty;
    oldItem.name = newData.name;
    oldItem.price = newData.price;
    oldItem.qty = newData.qty;
    oldItem.profit = newProfit;

    int qtyDiff = oldItem.qty - newData.qty;
    if (qtyDiff != 0 && oldItem.itemId.isNotEmpty) {
      final invItem = _inventoryBox.get(oldItem.itemId);
      if (invItem != null) {
        invItem.stock += qtyDiff;
        invItem.save();
      }
    }
    oldItem.save();
    notifyListeners();
  }

  void deleteHistoryItem(String id) {
    _historyBox.delete(id);
    notifyListeners();
  }

  void refundSale(SaleRecord historyItem, {int? refundQty}) {
    if (historyItem.status == "Refunded") return;

    int totalQty = historyItem.qty;
    int qtyToRefund = refundQty ?? totalQty;
    if (qtyToRefund > totalQty) qtyToRefund = totalQty;

    if (qtyToRefund < totalQty) {
      int remainingQty = totalQty - qtyToRefund;
      historyItem.qty = remainingQty;
      historyItem.profit = (historyItem.price - historyItem.actualPrice) * remainingQty;
      historyItem.save();

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
      historyItem.status = "Refunded";
      historyItem.profit = 0.0;
      historyItem.save();
    }

    if (historyItem.itemId.isNotEmpty) {
      final inventoryItem = _inventoryBox.get(historyItem.itemId);
      if (inventoryItem != null) {
        inventoryItem.stock += qtyToRefund;
        inventoryItem.save();
      }
    }
    notifyListeners();
  }

  // === CART ===
  List<SaleRecord> get cart => _cartBox.values.toList();
  double get cartTotal => _cartBox.values.fold(0, (sum, item) => sum + (item.price * item.qty));
  int get cartCount => _cartBox.values.fold(0, (sum, item) => sum + item.qty);

  void addToCart(SaleRecord item) {
    _cartBox.put(item.id, item);
    notifyListeners();
  }

  void removeFromCart(int index) {
    _cartBox.deleteAt(index);
    notifyListeners();
  }

  void clearCart() {
    _cartBox.clear();
    notifyListeners();
  }

  Future<void> checkoutCart({double discount = 0.0}) async {
    final String billId = "bill_${DateTime.now().millisecondsSinceEpoch}";
    final items = _cartBox.values.toList();
    final now = DateTime.now();

    for (var item in items) {
      // Create a FRESH copy of the record to move it to History
      final historyRecord = SaleRecord(
        id: "hist_${item.id}_${now.millisecondsSinceEpoch}",
        itemId: item.itemId,
        name: item.name,
        price: item.price,
        actualPrice: item.actualPrice,
        qty: item.qty,
        profit: item.profit,
        date: now,
        status: "Sold",
        billId: billId,
      );
      
      await _historyBox.put(historyRecord.id, historyRecord);
      
      // Update inventory stock
      final invItem = _inventoryBox.get(item.itemId);
      if (invItem != null) {
        invItem.stock -= item.qty;
        invItem.save();
      }
    }
    
    // Record Discount if any
    if (discount > 0) {
      final discountRecord = SaleRecord(
        id: "disc_${billId}_${now.millisecondsSinceEpoch}",
        itemId: "DISCOUNT",
        name: "Discount Applied",
        price: -discount, // Negative Price
        actualPrice: 0,
        qty: 1,
        profit: -discount, // Loss
        date: now,
        status: "Sold",
        billId: billId,
      );
      await _historyBox.put(discountRecord.id, discountRecord);
    }
    
    // Clear cart and notify all home screen listeners
    await _cartBox.clear();
    notifyListeners();
  }

  // === ANALYTICS ===
  Map<String, dynamic> getAnalytics(String type) {
    if (type == "Weekly") return _getWeeklyData();
    if (type == "Monthly") return _getMonthlyData();
    if (type == "Annual") return _getAnnualData();
    return _getWeeklyData();
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

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

      double dayExpenses = _expensesBox.values
          .where((e) => _isSameDay(date, e.date))
          .fold(0.0, (sum, item) => sum + item.amount);
      
      sales.add(daySales);
      expenses.add(dayExpenses);
      profit.add(dayItemProfit - dayExpenses);
    }
    return {
      "labels": labels, 
      "Sales": sales, 
      "Expenses": expenses, 
      "Profit": profit,
    };
  }

  Map<String, dynamic> _getMonthlyData() {
    List<double> sales = [], expenses = [], profit = [];
    List<String> labels = ["W1", "W2", "W3", "W4"];
    DateTime now = DateTime.now();

    for (int i = 3; i >= 0; i--) {
      // Period of 7 days
      DateTime end = now.subtract(Duration(days: i * 7));
      DateTime start = end.subtract(const Duration(days: 7));

      double periodSales = 0.0;
      double periodItemProfit = 0.0;
      double periodExpenses = 0.0;

      for (var item in _validHistory) {
        if (item.date.isAfter(start) && item.date.isBefore(end.add(const Duration(seconds: 1)))) {
          periodSales += (item.price * item.qty);
          periodItemProfit += item.profit;
        }
      }

      for (var exp in _expensesBox.values) {
        if (exp.date.isAfter(start) && exp.date.isBefore(end.add(const Duration(seconds: 1)))) {
          periodExpenses += exp.amount;
        }
      }

      sales.add(periodSales);
      expenses.add(periodExpenses);
      profit.add(periodItemProfit - periodExpenses);
    }
    return {
      "labels": labels, 
      "Sales": sales, 
      "Expenses": expenses, 
      "Profit": profit,
    };
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

      for (var exp in _expensesBox.values) {
        if (exp.date.year == currentYear && exp.date.month == m) {
          monthExpenses += exp.amount;
        }
      }

      sales.add(monthSales);
      expenses.add(monthExpenses);
      profit.add(monthItemProfit - monthExpenses);
    }
    return {
      "labels": labels, 
      "Sales": sales, 
      "Expenses": expenses, 
      "Profit": profit,
    };
  }

  List<Map<String, dynamic>> getTopSellingProducts({int limit = 5}) {
    final Map<String, int> productSales = {};
    for (var sale in _validHistory) {
      productSales[sale.name] = (productSales[sale.name] ?? 0) + sale.qty;
    }
    var sortedEntries = productSales.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return sortedEntries.take(limit).map((e) => {
      'name': e.key,
      'qty': e.value,
    }).toList();
  }

  Future<void> clearAllData() async {
    await _historyBox.clear();
    await _cartBox.clear();
    notifyListeners();
  }
}
