import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rsellx/features/splash/splash_screen.dart';
import 'package:rsellx/core/theme/app_theme.dart';
import 'package:rsellx/core/services/database_service.dart';
import 'package:rsellx/core/services/logger_service.dart';

import 'package:rsellx/providers/inventory_provider.dart';
import 'package:rsellx/providers/expense_provider.dart';
import 'package:rsellx/providers/sales_provider.dart';
import 'package:rsellx/providers/settings_provider.dart';
import 'package:rsellx/providers/backup_provider.dart';
import 'package:rsellx/providers/credit_provider.dart';

void main() {
  runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();
    
    // Initialize Database
    await DatabaseService.init();

    runApp(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => InventoryProvider()),
          ChangeNotifierProvider(create: (_) => ExpenseProvider()),
          ChangeNotifierProvider(create: (_) => SalesProvider()),
          ChangeNotifierProvider(create: (_) => SettingsProvider()),
          ChangeNotifierProvider(create: (_) => BackupProvider()),
          ChangeNotifierProvider(create: (_) => CreditProvider()),
        ],
        child: const MyApp(),
      ),
    );
  }, (error, stack) {
    AppLogger.error("Unhandled Exception", error: error, stackTrace: stack);
  });
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'RsellX',
      theme: AppTheme.lightTheme,
      themeMode: ThemeMode.light, 
      home: const SplashScreen(),
      builder: (context, widget) {
        ErrorWidget.builder = (FlutterErrorDetails details) {
          return Scaffold(
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline, color: Colors.red, size: 80),
                    const SizedBox(height: 24),
                    const Text("Something went wrong", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    const Text(
                      "An unexpected error occurred. Please try restarting the app.",
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey, fontSize: 16),
                    ),
                    const SizedBox(height: 32),
                    ElevatedButton.icon(
                      onPressed: () => Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(builder: (context) => const SplashScreen()),
                        (route) => false,
                      ),
                      icon: const Icon(Icons.refresh),
                      label: const Text("RESTART APP"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueAccent,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        };
        return widget!;
      },
    );
  }
}
