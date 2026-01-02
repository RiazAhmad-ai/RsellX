// lib/screens/dashboard_screen.dart
import 'package:flutter/material.dart';
import '../widgets/filter_buttons.dart';
import '../widgets/overview_card.dart';
import '../widgets/alert_card.dart';
import '../widgets/analysis_chart.dart';
import 'settings_screen.dart'; // Settings screen import

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  String _filter = "Monthly";

  // Ab yeh data sirf CHART ke liye use hoga
  Map<String, dynamic> get currentChartData {
    if (_filter == "Weekly") {
      return {
        "chartTitle": "Weekly Sales",
        "profit": "Rs 12,500",
        "labels": ["M", "T", "W", "T", "F", "S", "S"],
      };
    } else if (_filter == "Annual") {
      return {
        "chartTitle": "Annual Sales",
        "profit": "Rs 1,200,500",
        "labels": ["Q1", "Q2", "Q3", "Q4"],
      };
    } else {
      // Monthly
      return {
        "chartTitle": "Monthly Sales",
        "profit": "Rs 343,150",
        "labels": ["W1", "W2", "W3", "W4"],
      };
    }
  }

  @override
  Widget build(BuildContext context) {
    final chartData = currentChartData; // Sirf Chart ka data nikala

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        titleSpacing: 24,
        title: Row(
          children: [
            ClipOval(
              child: Image.asset(
                'assets/logo.png', // Aapka Logo
                height: 40,
                width: 40,
                fit: BoxFit.cover,
                errorBuilder: (c, o, s) => Container(
                  height: 40,
                  width: 40,
                  decoration: BoxDecoration(
                    color: Colors.red[50],
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.storefront,
                    color: Colors.red,
                    size: 24,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "RIAZ AHMAD CROKERY",
                  style: TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                  ),
                ),
                Text(
                  "Jehangira Underpass Shop#21",
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined, color: Colors.black),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsScreen()),
              );
            },
          ),
          const SizedBox(width: 10),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              FilterButtons(
                selectedFilter: _filter,
                onFilterChanged: (newFilter) {
                  setState(() {
                    _filter = newFilter; // Sirf Chart update hoga
                  });
                },
              ),

              const SizedBox(height: 20),

              // === FIXED OVERVIEW CARD (Total Inventory) ===
              // === FIXED OVERVIEW CARD (No Percentage) ===
              const OverviewCard(
                title: "TOTAL STOCK VALUE",
                amount: "Rs 1,250,000",
                // percentage: "..." <--- YEH LINE DELETE KAR DI
              ),

              const SizedBox(height: 20),

              const AlertCard(),

              const SizedBox(height: 20),

              // === DYNAMIC CHART (Filter se change hoga) ===
              AnalysisChart(
                title:
                    chartData['chartTitle'], // Weekly/Monthly yahan change hoga
                profit: chartData['profit'],
                labels: chartData['labels'],
              ),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}
