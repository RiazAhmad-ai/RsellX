import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../dashboard/dashboard_screen.dart';
import '../inventory/inventory_screen.dart';
import '../history/history_screen.dart';
import '../expenses/expense_screen.dart';
import '../../data/models/inventory_model.dart';
import '../inventory/sell_item_sheet.dart';
import '../../shared/widgets/full_scanner_screen.dart';
import '../../shared/widgets/text_scanner_screen.dart';
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
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const CartScreen()),
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

  // === MANUAL SELL DIALOG ===
  void _showManualSellDialog() {
    final codeController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
             // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: AppColors.accent,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.keyboard, color: Colors.white, size: 28),
                  SizedBox(width: 10),
                  Text("Manual Entry", style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  const Text("Enter Product Code / Barcode", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                  const SizedBox(height: 20),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: TextField(
                      controller: codeController,
                      autofocus: true,
                      style: const TextStyle(fontSize: 18, letterSpacing: 1, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                      decoration: const InputDecoration(
                        hintText: "CODE HERE",
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.all(16),
                        prefixIcon: Icon(Icons.qr_code_2, color: AppColors.primary),
                      ),
                      onSubmitted: (_) => _processManualSell(codeController.text),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: () => Navigator.pop(context),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: const Text("Cancel", style: TextStyle(fontSize: 16, color: Colors.grey)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => _processManualSell(codeController.text),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.accent,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            elevation: 2,
                          ),
                          child: const Text("DONE", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _processManualSell(String code) async {
    if (code.trim().isEmpty) return;
    Navigator.pop(context); // Close dialog

    // Search for match in inventory
    final match = context.read<InventoryProvider>().findItemByBarcode(code.trim());
    
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
        // Re-open scanner automatically ? Or manual?
        // Let's just stay on screen for manual
      } else if (result == "VIEW_CART") {
        if (!mounted) return;
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const CartScreen()),
        );
      }
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("❌ No item found with Code: $code"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // === OCR SCANNER FOR SELLING (SWIPE UP) ===
  void _openOcrScanner() async {
    final String? text = await Navigator.push<String>(
      context,
      MaterialPageRoute(
        builder: (context) => const TextScannerScreen(),
      ),
    );

    if (text != null && text.isNotEmpty) {
      final cleanText = text.replaceAll('\n', ' ').trim();
      ScaffoldMessenger.of(context).showSnackBar(
         SnackBar(content: Text("Searching for: $cleanText..."), duration: const Duration(seconds: 1)),
      );
      
      // Find item by Name (OCR usually returns text/name) or Code
      // Since OCR is unreliable for exact strings, we might want to do a "contains" search in provider
      // But currently findItemByBarcode is an exact match.
      // Let's try to match name first loosely if possible, otherwise rely on exact barcode match if it scanned a code as text.
      // For now, let's treat it as a potential Name or Barcode search.
      
      final inventory = context.read<InventoryProvider>();
      InventoryItem? match = inventory.findItemByBarcode(cleanText); // Exact match check first

      // If no barcode match, try searching by name (first match)
      if (match == null) {
          try {
             match = inventory.inventory.firstWhere((item) => item.name.toLowerCase().contains(cleanText.toLowerCase()));
          } catch (e) {
             match = null;
          }
      }

      if (match != null) {
          if (!mounted) return;
          final result = await showModalBottomSheet<String>(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.white,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
            ),
            builder: (context) => SellItemSheet(item: match!),
          );

          if (result == "VIEW_CART") {
            if (!mounted) return;
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const CartScreen()),
            );
          }
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("❌ No item found matching: $cleanText"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
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
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
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
              message: "Tap: Scan | Swipe Up: OCR | Swipe Down: Manual",
              child: GestureDetector(
                // Swipe Detection (Up & Down)
                onVerticalDragEnd: (details) {
                  if (details.primaryVelocity! < 0) { 
                    // Swipe UP -> OCR
                    _openOcrScanner();
                  } else if (details.primaryVelocity! > 0) {
                    // Swipe DOWN -> Manual (Keyboard)
                    ScaffoldMessenger.of(context).showSnackBar(
                       const SnackBar(
                         content: Text("Manual Mode Activated ⌨️"), 
                         duration: Duration(milliseconds: 600),
                         backgroundColor: Colors.redAccent,
                         behavior: SnackBarBehavior.floating,
                       )
                     );
                    _showManualSellDialog();
                  }
                },
                onTap: _openBarcodeScanner,
                child: Stack(
                  alignment: Alignment.topRight,
                  clipBehavior: Clip.none,
                  children: [
                    // Main Circular Button
                    Container(
                      height: 72, 
                      width: 72,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [AppColors.accent, AppColors.accent.withOpacity(0.8)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.accent.withOpacity(0.4),
                            blurRadius: 12,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.keyboard_arrow_up, color: Colors.white.withOpacity(0.7), size: 18),
                          const SizedBox(height: 2),
                          const Icon(Icons.qr_code_scanner, size: 26, color: Colors.white),
                          const SizedBox(height: 2),
                          Icon(Icons.keyboard_arrow_down, color: Colors.white.withOpacity(0.7), size: 18),
                        ],
                      ),
                    ),

                    // Cart Badge (Overlay)
                    if (cartCount > 0)
                      Positioned(
                        top: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                            boxShadow: [
                              BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 4, offset: const Offset(0, 2))
                            ]
                          ),
                          child: Text(
                            "$cartCount",
                            style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w900),
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
