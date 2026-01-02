// lib/screens/dashboard_screen.dart
import 'package:flutter/material.dart';
import '../widgets/filter_buttons.dart'; // Import kiya
import '../widgets/overview_card.dart'; // Import kiya
import '../widgets/alert_card.dart'; // Import kiya

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          "Dashboard",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.grey),
            onPressed: () {},
          ),
        ],
      ),
      body: const SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              FilterButtons(), // Chota sa code
              SizedBox(height: 20),
              OverviewCard(), // Clean code
              SizedBox(height: 20),
              AlertCard(), // Clean code
            ],
          ),
        ),
      ),
    );
  }
}
