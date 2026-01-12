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
  
  void _invalidateCache() {
    _cache.clear();
  }
  
  @override
  void dispose() {
    _expensesBoxSubscription?.cancel();
    super.dispose();
  }

  Box<ExpenseItem> get _expensesBox => Hive.box<ExpenseItem>('expensesBox');

  List<ExpenseItem> get _allExpenses => _expensesBox.values.toList();

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  List<ExpenseItem> get todayExpenses {
    const key = 'todayExpenses';
    if (!_cache.containsKey(key)) {
      _cache[key] = _allExpenses
          .where((e) => _isSameDay(DateTime.now(), e.date))
          .toList();
    }
    return _cache[key] as List<ExpenseItem>;
  }

  List<ExpenseItem> get yesterdayExpenses {
    const key = 'yesterdayExpenses';
    if (!_cache.containsKey(key)) {
      _cache[key] = _allExpenses
          .where(
            (e) => _isSameDay(
              DateTime.now().subtract(const Duration(days: 1)),
              e.date,
            ),
          )
          .toList();
    }
    return _cache[key] as List<ExpenseItem>;
  }

  List<ExpenseItem> getExpensesForDate(DateTime date) {
    final key = 'expensesForDate_${date.year}_${date.month}_${date.day}';
    if (!_cache.containsKey(key)) {
      _cache[key] = _allExpenses.where((e) => _isSameDay(date, e.date)).toList();
    }
    return _cache[key] as List<ExpenseItem>;
  }

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

  double getTotalExpenses() {
    // Return only today's total
    return todayExpenses.fold(0.0, (sum, item) => sum + item.amount);
  }
  
  // If you need combined total, use this explicit method
  double getTotalExpensesForTodayAndYesterday() {
    return todayExpenses.fold(0.0, (sum, item) => sum + item.amount) +
        yesterdayExpenses.fold(0.0, (sum, item) => sum + item.amount);
  }

  double getTotalExpensesForDate(DateTime date) {
    final key = 'totalExpensesForDate_${date.year}_${date.month}_${date.day}';
    if (!_cache.containsKey(key)) {
      var list = getExpensesForDate(date);
      _cache[key] = list.fold(0.0, (sum, item) => sum + item.amount);
    }
    return _cache[key] as double;
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

