// lib/screens/dashboard_screen.dart
import 'package:flutter/material.dart';
import '../widgets/filter_buttons.dart';
import '../widgets/overview_card.dart';
import '../widgets/alert_card.dart';
import '../widgets/analysis_chart.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  String _filter = "Monthly";

  Map<String, dynamic> get currentData {
    if (_filter == "Weekly") {
      return {
        "cardTitle": "Haftawar Maal",
        "amount": "Rs 82,400",
        "pct": "+5.1% pichlay haftay se",
        "chartTitle": "Weekly Summary",
        "profit": "Rs 12,500",
        "labels": ["M", "T", "W", "T", "F", "S", "S"],
      };
    } else if (_filter == "Annual") {
      return {
        "cardTitle": "Salana Maal",
        "amount": "Rs 4,120,000",
        "pct": "+12% pichlay saal se",
        "chartTitle": "Annual Summary",
        "profit": "Rs 1,200,500",
        "labels": ["Q1", "Q2", "Q3", "Q4"],
      };
    } else {
      return {
        "cardTitle": "Mahana Maal",
        "amount": "Rs 842,500",
        "pct": "+2.4% pichlay mahinay se",
        "chartTitle": "Monthly Summary",
        "profit": "Rs 343,150",
        "labels": ["W1", "W2", "W3", "W4"],
      };
    }
  }

  @override
  Widget build(BuildContext context) {
    final data = currentData;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),

      // === APP BAR CHANGE ===
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        // Title spacing 0 kiya taake logo left side se chipak ke start ho
        titleSpacing: 24,

        // Custom Title (Logo + Name)
        title: Row(
          children: [
            // 1. Logo Circle
            // 1. Custom Image Logo
            ClipOval(
              // Image ko gol katne ke liye
              child: Image.asset(
                'assets/logo.png', // <--- YAHAN APNI FILE KA NAAM CHECK KAREIN
                height: 40, // Size
                width: 40,
                fit: BoxFit.cover, // Image ko pura fit kare
              ),
            ),
            const SizedBox(width: 12), // Beech mein gap
            // 2. Dukan Ka Naam
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "RIAZ AHMAD CROKERY", // Bara Title
                  style: TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                  ),
                ),
                Text(
                  "Jehangira Underpass Shop#21", // Chota subtitle
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

        // Right Side Settings Icon
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined, color: Colors.black),
            onPressed: () {},
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
                    _filter = newFilter;
                  });
                },
              ),

              const SizedBox(height: 20),

              OverviewCard(
                title: data['cardTitle'],
                amount: data['amount'],
                percentage: data['pct'],
              ),

              const SizedBox(height: 20),

              const AlertCard(),

              const SizedBox(height: 20),

              AnalysisChart(
                title: data['chartTitle'],
                profit: data['profit'],
                labels: data['labels'],
              ),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}
