// lib/screens/dashboard_screen.dart
import 'package:flutter/material.dart';
import '../widgets/filter_buttons.dart';
import '../widgets/overview_card.dart';
import '../widgets/alert_card.dart';
import '../widgets/analysis_chart.dart';
import 'settings_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  String _filter = "Monthly";

  // Chart Data Logic
  Map<String, dynamic> get currentChartData {
    if (_filter == "Weekly") {
      return {
        "chartTitle": "Weekly Overview", // Title generic kar diya
        "labels": ["M", "T", "W", "T", "F", "S", "S"],
      };
    } else if (_filter == "Annual") {
      return {
        "chartTitle": "Annual Overview",
        "labels": ["Q1", "Q2", "Q3", "Q4"],
      };
    } else {
      // Monthly
      return {
        "chartTitle": "Monthly Overview",
        "labels": ["W1", "W2", "W3", "W4"],
      };
    }
  }

  @override
  Widget build(BuildContext context) {
    final chartData = currentChartData;

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
                'assets/logo.png',
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
                  "BISMILLAH STORE",
                  style: TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                  ),
                ),
                Text(
                  "Peshawar Branch",
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
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FilterButtons(
                  selectedFilter: _filter,
                  onFilterChanged: (newFilter) {
                    setState(() {
                      _filter = newFilter;
                    });
                  },
                ),

                const SizedBox(height: 20),

                // === FIXED STOCK CARD (Blue) ===
                const OverviewCard(
                  title: "TOTAL STOCK VALUE",
                  amount: "Rs 1,250,000",
                  icon: Icons.inventory_2,
                ),

                const SizedBox(height: 20),

                const AlertCard(),

                const SizedBox(height: 20),

                // === ALL-IN-ONE ANALYTICS CARD (Sales, Profit, Expense) ===
                AnalysisChart(
                  title: chartData['chartTitle'],
                  labels: chartData['labels'],
                ),

                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
