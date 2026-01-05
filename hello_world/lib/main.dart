import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'features/splash/splash_screen.dart';
import 'data/models/inventory_model.dart';
import 'data/models/sale_model.dart';
import 'data/models/expense_model.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Setup Database (Hive)
  try {
    await Hive.initFlutter();

    // Register Adapters
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(InventoryItemAdapter());
    }
    if (!Hive.isAdapterRegistered(1)) {
      Hive.registerAdapter(SaleRecordAdapter());
    }
    if (!Hive.isAdapterRegistered(2)) {
      Hive.registerAdapter(ExpenseItemAdapter());
    }

    // 2. Data Migration (Handle old Map data)
    await _migrateData();

    // 3. Open Boxes (Now safe to open with types)
    await Hive.openBox<InventoryItem>('inventoryBox');
    await Hive.openBox<ExpenseItem>('expensesBox');
    await Hive.openBox<SaleRecord>('historyBox');
    await Hive.openBox('settingsBox');
  } catch (e) {
    print("CRITICAL INITIALIZATION ERROR: $e");
  }

  runApp(const MyApp());
}

Future<void> _migrateData() async {
  // 1. Migrate History
  var historyBox = await Hive.openBox('historyBox');
  for (var key in historyBox.keys) {
    var value = historyBox.get(key);
    if (value is Map) {
      try {
        final sale = SaleRecord(
          id: value['id']?.toString() ?? key.toString(),
          itemId: value['itemId']?.toString() ?? "",
          name: value['name']?.toString() ?? "Unknown",
          price: (value['price'] as num?)?.toDouble() ?? 0.0,
          actualPrice: (value['actualPrice'] as num?)?.toDouble() ?? 0.0,
          qty: (value['qty'] as num?)?.toInt() ?? 1,
          profit: (value['profit'] as num?)?.toDouble() ?? 0.0,
          date: DateTime.tryParse(value['date']?.toString() ?? "") ?? DateTime.now(),
          status: value['status']?.toString() ?? "Sold",
          billId: value['billId']?.toString(),
        );
        await historyBox.put(key, sale);
      } catch (e) {
        print("Failed to migrate history item $key: $e");
      }
    }
  }
  await historyBox.close();

  // 2. Migrate Inventory
  var inventoryBox = await Hive.openBox('inventoryBox');
  for (var key in inventoryBox.keys) {
    var value = inventoryBox.get(key);
    if (value is Map) {
      try {
        final item = InventoryItem(
          id: value['id']?.toString() ?? key.toString(),
          name: value['name']?.toString() ?? "Unknown",
          price: (value['price'] as num?)?.toDouble() ?? 0.0,
          stock: (value['stock'] as num?)?.toInt() ?? 0,
          description: value['description']?.toString(),
          barcode: value['barcode']?.toString() ?? "N/A",
        );
        await inventoryBox.put(key, item);
      } catch (e) {
        print("Failed to migrate inventory item $key: $e");
      }
    }
  }
  await inventoryBox.close();

  // 3. Migrate Expenses
  var expensesBox = await Hive.openBox('expensesBox');
  for (var key in expensesBox.keys) {
    var value = expensesBox.get(key);
    if (value is Map) {
      try {
        final expense = ExpenseItem(
          id: value['id']?.toString() ?? key.toString(),
          title: value['title']?.toString() ?? "Unknown",
          amount: (value['amount'] as num?)?.toDouble() ?? 0.0,
          date: DateTime.tryParse(value['date']?.toString() ?? "") ?? DateTime.now(),
          category: value['category']?.toString() ?? "General",
        );
        await expensesBox.put(key, expense);
      } catch (e) {
        print("Failed to migrate expense item $key: $e");
      }
    }
  }
  await expensesBox.close();
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Retail POS System',
      theme: ThemeData(
        primarySwatch: Colors.red,
        scaffoldBackgroundColor: Colors.white,
        useMaterial3: true,
      ),
      home: const SplashScreen(),
    );
  }
}
