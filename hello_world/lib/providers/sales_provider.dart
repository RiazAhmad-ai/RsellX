import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:rsellx/data/models/inventory_model.dart';
import 'package:rsellx/data/models/sale_model.dart';
import 'package:rsellx/data/models/expense_model.dart';
import 'package:rsellx/data/models/damage_model.dart';
import 'package:rsellx/core/constants/app_constants.dart';

class SalesProvider extends ChangeNotifier {
  // === Cache ===
  List<SaleRecord> _cachedHistory = [];
  bool _historyDirty = true;
  
  // Analytics Cache to prevent re-calc on every build
  final Map<String, Map<String, dynamic>> _analyticsCache = {};
  
  // Stream subscriptions for proper cleanup
  StreamSubscription? _historyBoxSubscription;
  StreamSubscription? _cartBoxSubscription;
  StreamSubscription? _expensesBoxSubscription;
  StreamSubscription? _damageBoxSubscription;

  SalesProvider() {
    _historyBoxSubscription = _historyBox.watch().listen((_) {
      _historyDirty = true;
      _analyticsCache.clear(); // Invalidate analytics cache
      notifyListeners();
    });
    _cartBoxSubscription = _cartBox.watch().listen((_) {
      notifyListeners();
    });
    _expensesBoxSubscription = _expensesBox.watch().listen((_) {
      _analyticsCache.clear(); // Expenses affect analytics too
      notifyListeners();
    });
    _damageBoxSubscription = _damageBox.watch().listen((_) {
      _analyticsCache.clear(); // Damage affects profit too
      notifyListeners();
    });
    
    // Initial Load
    _refreshCache();
  }
  
  @override
  void dispose() {
    _historyBoxSubscription?.cancel();
    _cartBoxSubscription?.cancel();
    _expensesBoxSubscription?.cancel();
    _damageBoxSubscription?.cancel();
    super.dispose();
  }

  Box<SaleRecord> get _historyBox => Hive.box<SaleRecord>('historyBox');
  Box<SaleRecord> get _cartBox => Hive.box<SaleRecord>('cartBox');
  Box<InventoryItem> get _inventoryBox => Hive.box<InventoryItem>('inventoryBox');
  Box<ExpenseItem> get _expensesBox => Hive.box<ExpenseItem>('expensesBox');
  Box<DamageRecord> get _damageBox => Hive.box<DamageRecord>('damageBox');

  // === HISTORY ===
  // Optimized Getter
  List<SaleRecord> get historyItems {
    if (_historyDirty) {
      _refreshCache();
    }
    return _cachedHistory;
  }
  
  void _refreshCache() {
    var list = _historyBox.values.toList();
    // Sorting can be expensive, do it only when necessary
    list.sort((a, b) => b.id.compareTo(a.id));
    _cachedHistory = list;
    _historyDirty = false;
  }

  List<SaleRecord> get _validHistory => historyItems.where((h) => h.status != "Refunded").toList();

  void addHistoryItem(SaleRecord item) {
    _historyBox.put(item.id, item);
    // Listener will handle cache invalidation
  }

  void updateHistoryItem(SaleRecord oldItem, SaleRecord newData) {
    // IMPORTANT: Calculate qtyDiff BEFORE updating oldItem.qty to get correct stock adjustment
    int originalQty = oldItem.qty;
    int qtyDiff = originalQty - newData.qty;
    
    double newProfit = (newData.price - oldItem.actualPrice) * newData.qty;
    oldItem.name = newData.name;
    oldItem.price = newData.price;
    oldItem.qty = newData.qty;
    oldItem.profit = newProfit;
    if (qtyDiff != 0 && oldItem.itemId.isNotEmpty) {
      final invItem = _inventoryBox.get(oldItem.itemId);
      if (invItem != null) {
        invItem.stock += qtyDiff;
        invItem.save();
      }
    }
    oldItem.save();
  }

  void deleteHistoryItem(String id) {
    _historyBox.delete(id);
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
        category: historyItem.category,
        subCategory: historyItem.subCategory,
        size: historyItem.size,
        weight: historyItem.weight,
        imagePath: historyItem.imagePath,
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
  }

  // === CART ===
  List<SaleRecord> get cart => _cartBox.values.toList();
  double get cartTotal => _cartBox.values.fold(0, (sum, item) => sum + (item.price * item.qty));
  int get cartCount => _cartBox.values.fold(0, (sum, item) => sum + item.qty);

  void addToCart(SaleRecord item) {
    _cartBox.put(item.id, item);
    // Deduct from inventory immediately
    final invItem = _inventoryBox.get(item.itemId);
    if (invItem != null) {
      invItem.stock -= item.qty;
      invItem.save();
    }
  }

  /// Adds to cart WITHOUT deducting from inventory (for when UI handles deduction)
  void addToCartSilent(SaleRecord item) {
    _cartBox.put(item.id, item);
  }

  void removeFromCart(int index) {
    final item = _cartBox.getAt(index);
    if (item != null) {
      // Restore stock
      final invItem = _inventoryBox.get(item.itemId);
      if (invItem != null) {
        invItem.stock += item.qty;
        invItem.save();
      }
    }
    _cartBox.deleteAt(index);
  }

  /// Update cart item quantity (increment/decrement)
  /// Returns true if successful, false if not enough stock
  bool updateCartItemQty(int index, int delta) {
    final item = _cartBox.getAt(index);
    if (item == null) return false;

    final invItem = _inventoryBox.get(item.itemId);
    int newQty = item.qty + delta;

    // Cannot go below 1
    if (newQty < 1) return false;

    // Check stock for increment
    if (delta > 0) {
      if (invItem == null || invItem.stock < delta) return false;
      // Deduct from inventory
      invItem.stock -= delta;
      invItem.save();
    } else if (delta < 0) {
      // Restore stock when decrementing
      if (invItem != null) {
        invItem.stock += (-delta);
        invItem.save();
      }
    }

    // Update cart item
    item.qty = newQty;
    item.profit = (item.price - item.actualPrice) * newQty;
    item.save();
    notifyListeners();
    return true;
  }

  /// Get available stock for a cart item (current inventory stock)
  int getAvailableStock(int index) {
    final item = _cartBox.getAt(index);
    if (item == null) return 0;
    final invItem = _inventoryBox.get(item.itemId);
    return invItem?.stock ?? 0;
  }

  void clearCart() {
    for (var item in _cartBox.values) {
      final invItem = _inventoryBox.get(item.itemId);
      if (invItem != null) {
        invItem.stock += item.qty;
        invItem.save();
      }
    }
    _cartBox.clear();
  }

  Future<void> checkoutCart({double discount = 0.0}) async {
    final String billId = "bill_${DateTime.now().millisecondsSinceEpoch}";
    final items = _cartBox.values.toList();
    final now = DateTime.now();

    try {
      // Batch all put operations for atomicity
      final List<Future<void>> putOperations = [];

      for (var item in items) {
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
          category: item.category,
          subCategory: item.subCategory,
          size: item.size,
          weight: item.weight,
          imagePath: item.imagePath,
        );
        
        putOperations.add(_historyBox.put(historyRecord.id, historyRecord));
        
        // Stock already deducted during addToCart/qty increment
      }
      
      if (discount > 0) {
        final discountRecord = SaleRecord(
          id: "disc_${billId}_${now.millisecondsSinceEpoch}",
          itemId: "DISCOUNT",
          name: "Discount Applied",
          price: -discount,
          actualPrice: 0,
          qty: 1,
          profit: -discount,
          date: now,
          status: "Sold",
          billId: billId,
        );
        putOperations.add(_historyBox.put(discountRecord.id, discountRecord));
      }
      
      // Wait for ALL operations to complete before clearing cart
      await Future.wait(putOperations);
      
      // Only clear cart if all history records saved successfully
      await _cartBox.clear();
      
    } catch (e, stackTrace) {
      // Log error but don't clear cart - user can retry
      if (kDebugMode) {
        print("Checkout failed: $e");
        print(stackTrace);
      }
      rethrow; // Let UI handle the error
    }
  }

  // === ANALYTICS (OPTIMIZED) ===
  Map<String, dynamic> getAnalytics(String type) {
    // Return cached if available
    if (_analyticsCache.containsKey(type)) {
      return _analyticsCache[type]!;
    }
    
    // Compute and cache
    Map<String, dynamic> result;
    if (type == "Weekly") result = _getWeeklyData();
    else if (type == "Monthly") result = _getMonthlyData();
    else if (type == "Annual") result = _getAnnualData();
    else result = _getWeeklyData();

    _analyticsCache[type] = result;
    return result;
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  Map<String, dynamic> _getWeeklyData() {
    // Pre-allocate arrays for better performance
    List<double> sales = List.filled(7, 0.0);
    List<double> expenses = List.filled(7, 0.0);
    List<double> profit = List.filled(7, 0.0);
    List<double> damage = List.filled(7, 0.0);
    List<String> labels = [];
    DateTime now = DateTime.now();
    
    // SINGLE PASS through history - O(n) instead of O(n×7)
    for (var item in _validHistory) {
      int daysDiff = now.difference(item.date).inDays;
      if (daysDiff >= 0 && daysDiff < 7) {
        int index = 6 - daysDiff;
        sales[index] += (item.price * item.qty);
        profit[index] += item.profit;
      }
    }

    // SINGLE PASS through expenses - O(m) instead of O(m×7)
    for (var exp in _expensesBox.values) {
      int daysDiff = now.difference(exp.date).inDays;
      if (daysDiff >= 0 && daysDiff < 7) {
        int index = 6 - daysDiff;
        expenses[index] += exp.amount;
        profit[index] -= exp.amount;
      }
    }

    // SINGLE PASS through damage - O(p) instead of O(p×7)
    for (var dmg in _damageBox.values) {
      int daysDiff = now.difference(dmg.date).inDays;
      if (daysDiff >= 0 && daysDiff < 7) {
        int index = 6 - daysDiff;
        damage[index] += dmg.lossAmount;
        profit[index] -= dmg.lossAmount;
      }
    }
    
    // Generate labels
    for (int i = 6; i >= 0; i--) {
      DateTime date = now.subtract(Duration(days: i));
      labels.add(AppConstants.weekLabels[date.weekday - 1]);
    }

    double totalSales = sales.fold(0, (a, b) => a + b);
    double totalExp = expenses.fold(0, (a, b) => a + b);
    double totalDmg = damage.fold(0, (a, b) => a + b);

    return {
      "labels": labels, 
      "Sales": sales, 
      "Expenses": expenses, 
      "Profit": profit,
      "Damage": damage,
      "totalSales": totalSales,
      "totalExpenses": totalExp,
      "totalDamage": totalDmg,
    };
  }

  Map<String, dynamic> _getMonthlyData() {
    // Pre-allocate arrays
    List<double> sales = List.filled(4, 0.0);
    List<double> expenses = List.filled(4, 0.0);
    List<double> profit = List.filled(4, 0.0);
    List<double> damage = List.filled(4, 0.0);
    List<String> labels = AppConstants.weekGroups;
    DateTime now = DateTime.now();
    
    // Helper to find week index (0-3) from date
    int getWeekIndex(DateTime date) {
      int daysDiff = now.difference(date).inDays;
      if (daysDiff < 0 || daysDiff >= 28) return -1;
      return 3 - (daysDiff ~/ 7);
    }

    // SINGLE PASS through history
    for (var item in _validHistory) {
      int weekIndex = getWeekIndex(item.date);
      if (weekIndex >= 0) {
        sales[weekIndex] += (item.price * item.qty);
        profit[weekIndex] += item.profit;
      }
    }

    // SINGLE PASS through expenses
    for (var exp in _expensesBox.values) {
      int weekIndex = getWeekIndex(exp.date);
      if (weekIndex >= 0) {
        expenses[weekIndex] += exp.amount;
        profit[weekIndex] -= exp.amount;
      }
    }

    // SINGLE PASS through damage
    for (var dmg in _damageBox.values) {
      int weekIndex = getWeekIndex(dmg.date);
      if (weekIndex >= 0) {
        damage[weekIndex] += dmg.lossAmount;
        profit[weekIndex] -= dmg.lossAmount;
      }
    }

    double totalSales = sales.fold(0, (a, b) => a + b);
    double totalExp = expenses.fold(0, (a, b) => a + b);
    double totalDmg = damage.fold(0, (a, b) => a + b);

    return {
      "labels": labels, 
      "Sales": sales, 
      "Expenses": expenses, 
      "Profit": profit,
      "Damage": damage,
      "totalSales": totalSales,
      "totalExpenses": totalExp,
      "totalDamage": totalDmg,
    };
  }

  Map<String, dynamic> _getAnnualData() {
    // Pre-allocate arrays for 12 months
    List<double> sales = List.filled(12, 0.0);
    List<double> expenses = List.filled(12, 0.0);
    List<double> profit = List.filled(12, 0.0);
    List<double> damage = List.filled(12, 0.0);
    List<String> labels = AppConstants.yearLabels;
    int currentYear = DateTime.now().year;

    // SINGLE PASS with month-based indexing
    for (var item in _validHistory) {
      if (item.date.year == currentYear) {
        int monthIndex = item.date.month - 1;
        sales[monthIndex] += (item.price * item.qty);
        profit[monthIndex] += item.profit;
      }
    }

    for (var exp in _expensesBox.values) {
      if (exp.date.year == currentYear) {
        int monthIndex = exp.date.month - 1;
        expenses[monthIndex] += exp.amount;
        profit[monthIndex] -= exp.amount;
      }
    }

    for (var dmg in _damageBox.values) {
      if (dmg.date.year == currentYear) {
        int monthIndex = dmg.date.month - 1;
        damage[monthIndex] += dmg.lossAmount;
        profit[monthIndex] -= dmg.lossAmount;
      }
    }

    double totalSales = sales.fold(0, (a, b) => a + b);
    double totalExp = expenses.fold(0, (a, b) => a + b);
    double totalDmg = damage.fold(0, (a, b) => a + b);

    return {
      "labels": labels, 
      "Sales": sales, 
      "Expenses": expenses, 
      "Profit": profit,
      "Damage": damage,
      "totalSales": totalSales,
      "totalExpenses": totalExp,
      "totalDamage": totalDmg,
    };
  }

  List<Map<String, dynamic>> getTopSellingProducts({int limit = 5}) {
    // This could also be cached if needed, but for now it's okay.
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
    // Cache clearing is handled by listener
  }
}
