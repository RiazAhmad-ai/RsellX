import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../dashboard/dashboard_screen.dart';
import '../inventory/inventory_screen.dart';
import '../history/history_screen.dart';
import '../expenses/expense_screen.dart';
import '../../data/models/inventory_model.dart';
import '../inventory/sell_item_sheet.dart';
import '../../shared/widgets/full_scanner_screen.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../cart/cart_screen.dart';
import '../../data/repositories/data_store.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    const DashboardScreen(), // 0: Home
    const InventoryScreen(), // 1: Stock
    const ExpenseScreen(), // 2: Expenses
    const HistoryScreen(), // 3: History
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  // === BARCODE SCANNER FOR SELLING ===
  void _openBarcodeScanner() async {
    final String? barcode = await Navigator.push<String>(
      context,
      MaterialPageRoute(
        builder: (context) => const FullScannerScreen(title: "Scan to Sell"),
      ),
    );

    if (barcode == null) return;

    // Search for match in inventory
    final box = Hive.box<InventoryItem>('inventoryBox');
    try {
      final match = box.values.firstWhere((item) => item.barcode == barcode);
      
      if (!mounted) return;
      final result = await showModalBottomSheet<String>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.white,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
        ),
        builder: (context) => SellItemSheet(item: match),
      );

      if (result == "ADD_MORE") {
        // Re-open scanner automatically
        _openBarcodeScanner();
      } else if (result == "VIEW_CART") {
        if (!mounted) return;
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const CartScreen()),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("❌ No item found with Barcode: $barcode"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_selectedIndex],

      // Floating Barcode Scanner Button
      floatingActionButton: ListenableBuilder(
        listenable: DataStore(),
        builder: (context, _) {
          final cartCount = DataStore().cart.length;
          return SizedBox(
            height: 65,
            width: 65,
            child: FloatingActionButton(
              onPressed: _openBarcodeScanner,
              backgroundColor: AppColors.accent,
              shape: const CircleBorder(),
              elevation: 4,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  const Icon(Icons.qr_code_scanner, size: 30, color: Colors.white),
                  if (cartCount > 0)
                    Positioned(
                      top: -10,
                      right: -10,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          "$cartCount",
                          style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,

      // === CHANGE 2: Buttons ki jagah badal di ===
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 8.0,
        color: Colors.white,
        elevation: 20,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildTabItem(
              icon: Icons.dashboard_outlined,
              activeIcon: Icons.dashboard,
              label: "Home",
              index: 0,
            ),
            _buildTabItem(
              icon: Icons.inventory_2_outlined,
              activeIcon: Icons.inventory_2,
              label: "Stock",
              index: 1,
            ),
            const SizedBox(width: 48),
            _buildTabItem(
              icon: Icons.wallet_outlined,
              activeIcon: Icons.wallet,
              label: "Expenses",
              index: 2,
            ),
            _buildTabItem(
              icon: Icons.history,
              activeIcon: Icons.history,
              label: "History",
              index: 3,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabItem({
    required IconData icon,
    required IconData activeIcon,
    required String label,
    required int index,
  }) {
    bool isActive = _selectedIndex == index;
    return InkWell(
      onTap: () => _onItemTapped(index),
      borderRadius: BorderRadius.circular(30),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isActive ? activeIcon : icon,
            color: isActive ? AppColors.accent : AppColors.textSecondary,
            size: 24,
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: AppTextStyles.label.copyWith(
              color: isActive ? AppColors.accent : AppColors.textSecondary,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}
