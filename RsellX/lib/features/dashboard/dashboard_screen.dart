import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../shared/widgets/filter_buttons.dart';
import 'overview_card.dart';
import '../../shared/widgets/alert_card.dart';
import 'analysis_chart.dart';
import 'top_products_chart.dart';
import '../settings/settings_screen.dart';
import 'package:rsellx/providers/inventory_provider.dart';
import 'package:rsellx/providers/sales_provider.dart';
import 'package:rsellx/providers/settings_provider.dart';
import '../../shared/utils/formatting.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../inventory/damage_screen.dart';
import '../barcode/barcode_generator_screen.dart';
import '../cart/cart_screen.dart';
import '../credit/credit_screen.dart';
import 'package:rsellx/providers/expense_provider.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  String _filter = "Weekly";

  void _showImagePreview(String imagePath, String title) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(10),
        child: Stack(
          alignment: Alignment.center,
          children: [
            InteractiveViewer(
              minScale: 0.5,
              maxScale: 4.0,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.file(
                  File(imagePath),
                  fit: BoxFit.contain,
                ),
              ),
            ),
            Positioned(
              top: 0,
              right: 0,
              child: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(
                    color: Colors.black54,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.close, color: Colors.white, size: 24),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final inventoryProvider = context.watch<InventoryProvider>();
    final salesProvider = context.watch<SalesProvider>();
    final settingsProvider = context.watch<SettingsProvider>();

    double totalStockValue = inventoryProvider.getTotalStockValue();
    final analyticsData = salesProvider.getAnalytics(_filter);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        elevation: 0,
        titleSpacing: 24,
        title: Row(
          children: [
            GestureDetector(
              onTap: settingsProvider.logoPath != null && File(settingsProvider.logoPath!).existsSync()
                  ? () => _showImagePreview(settingsProvider.logoPath!, "Shop Logo")
                  : null,
              child: ClipOval(
                child: settingsProvider.logoPath != null && File(settingsProvider.logoPath!).existsSync()
                    ? Image.file(
                        File(settingsProvider.logoPath!),
                        height: 40,
                        width: 40,
                        fit: BoxFit.cover,
                        key: ValueKey(settingsProvider.logoPath),
                      )
                    : Image.asset(
                        'assets/logo.png',
                        height: 40,
                        width: 40,
                        cacheWidth: 150, // Optimize memory usage
                        fit: BoxFit.cover,
                        errorBuilder: (c, o, s) => Container(
                          height: 40,
                          width: 40,
                          decoration: const BoxDecoration(
                            color: Color(0x1AE53935), // AppColors.primary 0.1 opacity
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.storefront, color: AppColors.primary, size: 24),
                        ),
                      ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(settingsProvider.shopName, style: AppTextStyles.h3.copyWith(fontSize: 15), overflow: TextOverflow.ellipsis, maxLines: 1),
                  Text(settingsProvider.address, style: AppTextStyles.label.copyWith(fontSize: 9), overflow: TextOverflow.ellipsis, maxLines: 1),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.menu_book_rounded, color: Colors.black),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const CreditScreen())),
          ),
          Consumer<SalesProvider>(
            builder: (context, sales, _) {
              final cartCount = sales.cartCount;
              return Stack(
                alignment: Alignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.shopping_cart_outlined, color: Colors.black),
                    onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const CartScreen())),
                  ),
                  if (cartCount > 0)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                        child: Text("$cartCount", style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold)),
                      ),
                    ),
                ],
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined, color: Colors.black),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const SettingsScreen())),
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
                  onFilterChanged: (newFilter) => setState(() => _filter = newFilter),
                ),
                const SizedBox(height: 20),
                OverviewCard(
                  title: "TOTAL STOCK VALUE",
                  amount: "Rs ${Formatter.formatCurrency(totalStockValue)}",
                  damageAmount: Formatter.formatCurrency(inventoryProvider.getTotalDamageLoss()),
                  footerText: "Exact Total: Rs ${Formatter.formatCurrency(totalStockValue - inventoryProvider.getTotalDamageLoss())}",
                  icon: Icons.inventory_2,
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: _buildQuickAction(
                        context,
                        title: "Damage Tracker",
                        icon: Icons.broken_image_outlined,
                        color: Colors.red,
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const DamageScreen())),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildQuickAction(
                        context,
                        title: "Barcodes",
                        icon: Icons.qr_code_2,
                        color: Colors.blue,
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const BarcodeGeneratorScreen())),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                const AlertCard(),
                const SizedBox(height: 20),
                AnalysisChart(
                  key: ValueKey("chart_${_filter}_${salesProvider.historyItems.length}"),
                  title: "$_filter Overview",
                  chartData: analyticsData,
                ),
                const SizedBox(height: 20),
                TopProductsChart(data: salesProvider.getTopSellingProducts()),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQuickAction(BuildContext context, {required String title, required IconData icon, required Color color, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [BoxShadow(color: Color(0x08000000), blurRadius: 10, offset: Offset(0, 4))], // 0.03 opacity black
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(height: 8),
            Text(title, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.black87), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
