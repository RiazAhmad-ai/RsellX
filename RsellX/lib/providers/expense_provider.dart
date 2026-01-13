import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:rsellx/data/models/expense_model.dart';
import 'package:rsellx/core/utils/app_logger.dart';

class ExpenseProvider extends ChangeNotifier {
  // Stream subscription for proper cleanup
  StreamSubscription? _expensesBoxSubscription;
  
  // === PERFORMANCE CACHING ===
  final Map<String, dynamic> _cache = {};
  
  ExpenseProvider() {
    _initializeListener();
  }
  
  void _initializeListener() {
    try {
      // Ensure box is open before watching
      if (Hive.isBoxOpen('expensesBox')) {
        _expensesBoxSubscription = _expensesBox.watch().listen((_) {
          _invalidateCache(); // Clear cache when data changes
          notifyListeners();
        }, onError: (error) {
          AppLogger.error('ExpenseProvider stream error', error: error);
        });
      }
    } catch (e) {
      AppLogger.error('ExpenseProvider initialization error', error: e);
    }
  }

  @override
  void dispose() {
    _expensesBoxSubscription?.cancel();
    super.dispose();
  }

  Box<ExpenseItem> get _expensesBox => Hive.box<ExpenseItem>('expensesBox');

  List<ExpenseItem> get _allExpenses => _expensesBox.values.toList();
  
  void addExpense(ExpenseItem expense) {
    _expensesBox.put(expense.id, expense);
    _invalidateCache();
  }

  void updateExpense(ExpenseItem expense) {
    expense.save();
    _invalidateCache();
  }

  void deleteExpense(String id) {
    _expensesBox.delete(id);
    _invalidateCache();
  }

  List<ExpenseItem> getExpensesForWeek(DateTime date) {
    final startOfWeek = date.subtract(Duration(days: date.weekday - 1));
    final key = 'expensesForWeek_${startOfWeek.year}_${startOfWeek.month}_${startOfWeek.day}';
    
    if (!_cache.containsKey(key)) {
      DateTime start = DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day, 0, 0, 0);
      DateTime end = DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day + 6, 23, 59, 59);
      
      _cache[key] = _allExpenses.where((e) {
        return (e.date.isAtSameMomentAs(start) || e.date.isAfter(start)) && 
               (e.date.isAtSameMomentAs(end) || e.date.isBefore(end));
      }).toList();
    }
    return _cache[key] as List<ExpenseItem>;
  }

  double getTotalExpensesForWeek(DateTime date) {
    final startOfWeek = date.subtract(Duration(days: date.weekday - 1));
    final key = 'totalExpensesForWeek_${startOfWeek.year}_${startOfWeek.month}_${startOfWeek.day}';
    
    if (!_cache.containsKey(key)) {
      var list = getExpensesForWeek(date);
      _cache[key] = list.fold(0.0, (sum, item) => sum + item.amount);
    }
    return _cache[key] as double;
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  List<ExpenseItem> get todayExpenses => getExpensesForDate(DateTime.now());
  
  List<ExpenseItem> get yesterdayExpenses => 
      getExpensesForDate(DateTime.now().subtract(const Duration(days: 1)));
  
  // === Date Index ===
  final Map<String, List<ExpenseItem>> _dateIndex = {};

  void _invalidateCache() {
    _cache.clear();
    _rebuildDateIndex();
  }
  
  void _rebuildDateIndex() {
    _dateIndex.clear();
    for (var item in _allExpenses) {
       final dateKey = "${item.date.year}-${item.date.month}-${item.date.day}";
       if (!_dateIndex.containsKey(dateKey)) {
         _dateIndex[dateKey] = [];
       }
       _dateIndex[dateKey]!.add(item);
    }
  }

  List<ExpenseItem> getExpensesForDate(DateTime date) {
    if (_dateIndex.isEmpty && _allExpenses.isNotEmpty) _rebuildDateIndex();
    final dateKey = "${date.year}-${date.month}-${date.day}";
    return _dateIndex[dateKey] ?? [];
  }

  double getTotalExpensesForDate(DateTime date) {
    // Optimized total calculation using index
    var list = getExpensesForDate(date);
    return list.fold(0.0, (sum, item) => sum + item.amount);
  }

  // Optimize other methods if needed, but date lookup is the most critical for charts
  
  List<ExpenseItem> getExpensesForYear(DateTime date) {
    final key = 'expensesForYear_${date.year}';
    if (!_cache.containsKey(key)) {
      _cache[key] = _allExpenses.where((e) => e.date.year == date.year).toList();
    }
    return _cache[key] as List<ExpenseItem>;
  }

  double getTotalExpensesForYear(DateTime date) {
    final key = 'totalExpensesForYear_${date.year}';
    if (!_cache.containsKey(key)) {
      var list = getExpensesForYear(date);
      _cache[key] = list.fold(0.0, (sum, item) => sum + item.amount);
    }
    return _cache[key] as double;
  }

  List<ExpenseItem> getExpensesForMonth(DateTime date) {
    final key = 'expensesForMonth_${date.year}_${date.month}';
    if (!_cache.containsKey(key)) {
      _cache[key] = _allExpenses.where((e) => e.date.month == date.month && e.date.year == date.year).toList();
    }
    return _cache[key] as List<ExpenseItem>;
  }

  double getTotalExpensesForMonth(DateTime date) {
    final key = 'totalExpensesForMonth_${date.year}_${date.month}';
    if (!_cache.containsKey(key)) {
      var list = getExpensesForMonth(date);
      _cache[key] = list.fold(0.0, (sum, item) => sum + item.amount);
    }
    return _cache[key] as double;
  }

  Future<void> clearAllData() async {
    await _expensesBox.clear();
    _invalidateCache();
  }
}

