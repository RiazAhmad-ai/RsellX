import 'package:flutter/material.dart';
import '../widgets/filter_buttons.dart';
import '../widgets/overview_card.dart';
import '../widgets/alert_card.dart';
import '../widgets/analysis_chart.dart';

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
            // <--- Yahan saari cheezein ek ke baad ek hain
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const FilterButtons(), // 1. Upar Buttons

              const SizedBox(height: 20),

              const OverviewCard(), // 2. Main Card

              const SizedBox(height: 20),

              const AlertCard(), // <--- 3. ALERT KO YAHAN UPAR LE AAYE

              const SizedBox(height: 20),

              const AnalysisChart(), // 4. Chart ab sabse neeche chala gaya
            ],
          ),
        ),
      ),
    );
  }
}
