// lib/features/dashboard/dashboard_screen.dart
import 'package:flutter/material.dart';
import '../../shared/widgets/filter_buttons.dart';
import 'overview_card.dart';
import '../../shared/widgets/alert_card.dart';
import 'analysis_chart.dart';
import '../settings/settings_screen.dart';
import '../../data/repositories/data_store.dart';
import '../../shared/utils/formatting.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';

import '../cart/cart_screen.dart';

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
      backgroundColor: AppColors.background,
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
                    color: AppColors.primary.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.storefront,
                    color: AppColors.primary,
                    size: 24,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    DataStore().shopName,
                    style: AppTextStyles.h3.copyWith(fontSize: 15),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                  Text(
                    DataStore().address,
                    style: AppTextStyles.label.copyWith(fontSize: 9),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          ListenableBuilder(
            listenable: DataStore(),
            builder: (context, _) {
              final cartCount = DataStore().cart.length;
              return Stack(
                alignment: Alignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.shopping_cart_outlined, color: Colors.black),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const CartScreen()),
                      );
                    },
                  ),
                  if (cartCount > 0)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                        child: Text(
                          "$cartCount",
                          style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
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
