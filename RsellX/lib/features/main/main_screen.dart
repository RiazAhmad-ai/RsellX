import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../dashboard/dashboard_screen.dart';
import '../inventory/inventory_screen.dart';
import '../history/history_screen.dart';
import '../expenses/expense_screen.dart';
import '../../data/models/inventory_model.dart';
import '../inventory/sell_item_sheet.dart';
import '../../shared/widgets/full_scanner_screen.dart';
import '../../core/utils/smart_search_input.dart';
import '../../core/utils/image_path_helper.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../cart/cart_screen.dart';
import 'package:provider/provider.dart';
import '../../providers/sales_provider.dart';
import '../../providers/inventory_provider.dart';

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
    const ExpenseScreen(),   // 2: Expenses
    const HistoryScreen(),   // 3: History
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
    final match = context.read<InventoryProvider>().findItemByBarcode(barcode);
    
    if (match != null) {
      
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
        // Small delay for smooth transition after bottom sheet pops
        await Future.delayed(const Duration(milliseconds: 150));
        Navigator.push(
          context,
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) => const CartScreen(),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return FadeTransition(opacity: animation, child: child);
            },
            transitionDuration: const Duration(milliseconds: 300),
          ),
        );
      }
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("❌ No item found with Barcode: $barcode"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // === MANUAL SELL DIALOG (REMOVED) ===


  // === MANUAL TEXT INPUT (SWIPE UP) ===
  // === SUPER SMART MANUAL SEARCH (Unified) ===
  Future<void> _openManualTextInput() async {
    final inventoryProvider = Provider.of<InventoryProvider>(context, listen: false);
    
    await showSmartSearchInput(
      context,
      inventory: inventoryProvider.inventory,
    );
    
    // No action needed - modal handles everything internally
    // Modal stays open until user explicitly closes it
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PopScope(
        canPop: false,
        onPopInvoked: (didPop) async {
          if (didPop) return;
          final shouldExit = await showDialog<bool>(
            context: context,
            builder: (context) => Dialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              elevation: 0,
              backgroundColor: Colors.transparent,
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x1A000000), // 0.1 opacity black
                      blurRadius: 20,
                      offset: Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.red[50],
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.power_settings_new_rounded, color: Colors.redAccent, size: 40),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      "Exit App?",
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      "Are you sure you want to exit the application?",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 15,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 28),
                    Row(
                      children: [
                        Expanded(
                          child: TextButton(
                            onPressed: () => Navigator.of(context).pop(false),
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            ),
                            child: Text("Cancel", style: TextStyle(color: Colors.grey[700], fontSize: 16)),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () => Navigator.of(context).pop(true),
                            style: ElevatedButton.styleFrom(
                              elevation: 2,
                              backgroundColor: Colors.redAccent,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            ),
                            child: const Text("Exit", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );

          if (shouldExit ?? false) {
             SystemNavigator.pop();
          }
        },
        child: _screens[_selectedIndex],
      ),

      // Floating Barcode Scanner Button
      floatingActionButton: Builder(
        builder: (context) {
          final cartCount = context.watch<SalesProvider>().cart.length;
          return SizedBox(
            height: 80, // Increased size for better visibility
            width: 80,
            child: Tooltip(
              message: "Tap: Scan | Swipe Up: Manual Entry",
              child: GestureDetector(
                // Swipe Detection (Up & Down)
                onVerticalDragEnd: (details) {
                  if (details.primaryVelocity! < 0) { 
                    // Swipe UP -> Manual Text Input
                    _openManualTextInput();
                  }
                },
                onTap: _openBarcodeScanner,
                child: Stack(
                  alignment: Alignment.topRight,
                  clipBehavior: Clip.none,
                  children: [
                    // Main Circular Button (Premium Design)
                    Container(
                      height: 75,
                      width: 75,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0x4D3B82F6), // AppColors.accent 0.3 opacity
                            blurRadius: 15,
                            offset: const Offset(0, 8),
                            spreadRadius: 2,
                          ),
                          const BoxShadow(
                            color: Color(0x1AFFFFFF), // 0.1 opacity white
                            blurRadius: 0,
                            offset: Offset(0, -2),
                          ),
                        ],
                      ),
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: const LinearGradient(
                            colors: [
                              Color(0xFF6366F1), // Indigo
                              Color(0xFF3B82F6), // Blue
                              Color(0xFF2563EB), // Deep Blue
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          border: Border.all(
                            color: const Color(0x40FFFFFF), // 0.25 opacity white
                            width: 2.5,
                          ),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Upward Indicator for Swipe
                            Container(
                              padding: const EdgeInsets.all(2),
                              decoration: const BoxDecoration(
                                color: Color(0x33FFFFFF), // 0.2 opacity white
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.keyboard_arrow_up_rounded, color: Colors.white, size: 18),
                            ),
                            const SizedBox(height: 5),
                            const Icon(
                              Icons.qr_code_scanner_rounded, 
                              size: 30, 
                              color: Colors.white,
                              shadows: [
                                Shadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2)),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Cart Badge (Premium Overlay)
                    if (cartCount > 0)
                      Positioned(
                        top: -2,
                        right: -2,
                        child: Container(
                          height: 26,
                          width: 26,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2.5),
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0x33000000), // 0.2 opacity black
                                blurRadius: 6,
                                offset: Offset(0, 3)
                              )
                            ]
                          ),
                          child: Text(
                            "$cartCount",
                            style: const TextStyle(
                              color: Colors.white, 
                              fontSize: 10, 
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Roboto',
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,

      // === CHANGE 2: Buttons ki jagah badal di ===
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 10.0,
        color: Colors.white,
        elevation: 25,
        surfaceTintColor: Colors.white,
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
              fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          if (isActive)
            Container(
              margin: const EdgeInsets.only(top: 2),
              height: 4,
              width: 4,
              decoration: const BoxDecoration(
                color: AppColors.accent,
                shape: BoxShape.circle,
              ),
            )
          else
            const SizedBox(height: 6),
        ],
      ),
    );
  }
}
