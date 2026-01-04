// lib/features/dashboard/dashboard_screen.dart
import 'package:flutter/material.dart';
import '../../shared/widgets/filter_buttons.dart';
import 'overview_card.dart';
import '../../shared/widgets/alert_card.dart';
import 'analysis_chart.dart';
import '../settings/settings_screen.dart';
import '../../data/repositories/data_store.dart';
import '../../shared/utils/formatting.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  // Default filter logic
  String _filter = "Weekly";

  @override
  void initState() {
    super.initState();
    // Refresh screen when data changes
    DataStore().addListener(_onDataChange);
  }

  @override
  void dispose() {
    DataStore().removeListener(_onDataChange);
    super.dispose();
  }

  void _onDataChange() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    // 1. Calculate Total Stock Value (Real Data)
    double totalStockValue = DataStore().getTotalStockValue();

    // 2. Get Analytics Data (Real Data from History & Expenses)
    final analyticsData = DataStore().getAnalytics(_filter);

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
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  DataStore().shopName,
                  style: const TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                  ),
                ),
                Text(
                  DataStore().address,
                  style: const TextStyle(
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
                // === FILTER BUTTONS ===
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
                OverviewCard(
                  title: "TOTAL STOCK VALUE",
                  amount:
                      "Rs ${Formatter.formatCurrency(totalStockValue)}", // DYNAMIC
                  icon: Icons.inventory_2,
                ),

                const SizedBox(height: 20),

                // === ALERT CARD (Low Stock) ===
                const AlertCard(),

                const SizedBox(height: 20),

                // === ALL-IN-ONE ANALYTICS CARD (Sales, Profit, Expense) ===
                // Updated to accept 'chartData' map
                AnalysisChart(
                  title: "$_filter Overview",
                  chartData: analyticsData, // <--- Passing Real Data Here
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
