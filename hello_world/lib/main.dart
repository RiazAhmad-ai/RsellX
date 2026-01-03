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
  Hive.registerAdapter(InventoryItemAdapter()); // Generated adapter
  await Hive.openBox<InventoryItem>('inventoryBox'); // Box kholna

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
