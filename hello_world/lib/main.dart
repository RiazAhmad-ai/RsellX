import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:camera/camera.dart'; // Camera package
import 'screens/splash_screen.dart';
import 'data/inventory_model.dart'; // Humara naya model
import 'services/ai_service.dart'; // Humara AI Brain

// Global Variable taake camera puri app mein mile
late List<CameraDescription> cameras;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Setup Camera
  try {
    cameras = await availableCameras();
  } on CameraException catch (e) {
    print('Error: $e.code\nError Message: $e.message');
  }

  // 2. Setup Database (Hive)
  await Hive.initFlutter();

  // Register Adapter if not already registered (InventoryItemAdapter is generated)
  // Note: If you face adapter errors, ensure generated file exists and is correct.
  if (!Hive.isAdapterRegistered(0)) {
    Hive.registerAdapter(InventoryItemAdapter());
  }

  // Open Boxes
  await Hive.openBox<InventoryItem>('inventoryBox');
  await Hive.openBox('expensesBox'); // Box for Expenses (List of Maps)
  await Hive.openBox('historyBox');  // Box for History (List of Maps)

  // 3. Load AI Model
  await AIService().loadModel();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'RIAZ AHMAD CROCKERY',
      theme: ThemeData(
        primarySwatch: Colors.red,
        scaffoldBackgroundColor: Colors.white,
        useMaterial3: true,
      ),
      home: const SplashScreen(),
    );
  }
}
