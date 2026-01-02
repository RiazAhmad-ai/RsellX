// lib/main.dart
import 'package:flutter/material.dart';
import 'screens/dashboard_screen.dart'; // Screen import ki

void main() {
  runApp(const CrockeryApp());
}

class CrockeryApp extends StatelessWidget {
  const CrockeryApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Crockery Manager',
      theme: ThemeData(useMaterial3: true, primarySwatch: Colors.red),
      home: const DashboardScreen(),
    );
  }
}
