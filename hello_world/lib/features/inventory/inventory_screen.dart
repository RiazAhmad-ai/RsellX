import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:rsellx/providers/inventory_provider.dart';
import 'package:rsellx/providers/settings_provider.dart';
import '../../shared/widgets/full_scanner_screen.dart';
import '../../data/models/inventory_model.dart';
import '../../core/services/reporting_service.dart';
import 'add_item_sheet.dart';
import 'sell_item_sheet.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import '../barcode/barcode_generator_screen.dart';

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  String _searchQuery = "";

  int _currentPage = 1;
  static const int _pageSize = 20;
  bool _isLoadingMore = false;
  List<InventoryItem> _displayedItems = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadInitialData();
    });
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _loadMoreData();
    }
  }

  void _loadInitialData() {
    final inventoryProvider = context.read<InventoryProvider>();
    final allItems = inventoryProvider.inventory.where((item) {
      final query = _searchQuery.toLowerCase();
      // Simple fuzzy search (can be improved further)
      return item.name.toLowerCase().contains(query) ||
          item.barcode.toLowerCase().contains(query);
    }).toList();

    // Sort by name by default
    allItems.sort(
      (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
    );

    setState(() {
      _currentPage = 1;
      _displayedItems = allItems.take(_pageSize).toList();
    });
  }

  void _loadMoreData() {
    if (_isLoadingMore) return;

    final inventoryProvider = context.read<InventoryProvider>();
    final allItems = inventoryProvider.inventory.where((item) {
      final query = _searchQuery.toLowerCase();
      return item.name.toLowerCase().contains(query) ||
          item.barcode.toLowerCase().contains(query);
    }).toList();

    allItems.sort(
      (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
    );

    if (_displayedItems.length >= allItems.length) return;

    setState(() => _isLoadingMore = true);

    Future.delayed(const Duration(milliseconds: 300), () {
      if (!mounted) return;

      final nextItems = allItems
          .skip(_currentPage * _pageSize)
          .take(_pageSize)
          .toList();
      setState(() {
        _displayedItems.addAll(nextItems);
        _currentPage++;
        _isLoadingMore = false;
      });
    });
  }

  // === 1. ADD ITEM (Open Sheet) ===
  void _addNewItemWithBarcode() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      builder: (context) => const AddItemSheet(),
    );
  }

  // === 2. BARCODE SEARCH & SELL ===
  Future<void> _scanForSearch() async {
    final String? barcode = await Navigator.push<String>(
      context,
      MaterialPageRoute(
        builder: (context) =>
            const FullScannerScreen(title: "Inventory Search"),
      ),
    );

    if (barcode == null) return;

    final inventoryProvider = context.read<InventoryProvider>();
    try {
      final match = inventoryProvider.inventory.firstWhere(
        (item) => item.barcode == barcode,
      );

      if (!mounted) return;
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.white,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
        ),
        builder: (context) => SellItemSheet(item: match),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("❌ Item not found with code: $barcode"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // === 3. DELETE ITEM ===
  void _deleteItem(InventoryItem item) {
    item.delete();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Item Deleted"),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // === 4. EDIT ITEM SHEET ===
  void _showEditSheet(InventoryItem item) {
    final nameCtrl = TextEditingController(text: item.name);
    final priceCtrl = TextEditingController(
      text: item.price.toStringAsFixed(0),
    );
    final stockCtrl = TextEditingController(text: item.stock.toString());
    final barcodeCtrl = TextEditingController(text: item.barcode);
    final thresholdCtrl = TextEditingController(
      text: item.lowStockThreshold.toString(),
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.85,
          ),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
          ),
          child: SingleChildScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            child: Padding(
              padding: const EdgeInsets.only(
                bottom: 24,
                top: 16,
                left: 24,
                right: 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Handle Bar
                  Center(
                    child: Container(
                      width: 50,
                      height: 5,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Header with Item Icon
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              AppColors.accent.withOpacity(0.8),
                              AppColors.accent,
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.accent.withOpacity(0.3),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.edit_note,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("Edit Product", style: AppTextStyles.h2),
                            const SizedBox(height: 4),
                            Text(
                              "Update item details below",
                              style: TextStyle(
                                color: Colors.grey[500],
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 28),

                  // Barcode Section
                  _buildSectionLabel("BARCODE / SKU", Icons.qr_code),
                  const SizedBox(height: 10),
                  _buildStyledTextField(
                    controller: barcodeCtrl,
                    hint: "Item Barcode",
                    icon: Icons.qr_code_2,
                    iconColor: AppColors.primary,
                  ),

                  const SizedBox(height: 20),

                  // Product Name Section
                  _buildSectionLabel("PRODUCT NAME", Icons.inventory_2),
                  const SizedBox(height: 10),
                  _buildStyledTextField(
                    controller: nameCtrl,
                    hint: "Enter product name",
                    icon: Icons.shopping_bag_outlined,
                    iconColor: AppColors.accent,
                  ),

                  const SizedBox(height: 20),

                  // Price & Stock Row
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildSectionLabel(
                              "PRICE (Rs)",
                              Icons.attach_money,
                            ),
                            const SizedBox(height: 10),
                            _buildStyledTextField(
                              controller: priceCtrl,
                              hint: "0",
                              icon: Icons.currency_rupee,
                              iconColor: AppColors.success,
                              keyboardType: TextInputType.number,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildSectionLabel("STOCK QTY", Icons.inventory),
                            const SizedBox(height: 10),
                            _buildStyledTextField(
                              controller: stockCtrl,
                              hint: "0",
                              icon: Icons.numbers,
                              iconColor: AppColors.secondary,
                              keyboardType: TextInputType.number,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Low Stock Alert
                  _buildSectionLabel("LOW STOCK ALERT", Icons.warning_amber),
                  const SizedBox(height: 10),
                  _buildStyledTextField(
                    controller: thresholdCtrl,
                    hint: "Alert when stock falls below",
                    icon: Icons.notifications_active_outlined,
                    iconColor: AppColors.warning,
                    keyboardType: TextInputType.number,
                  ),

                  const SizedBox(height: 32),

                  // Action Buttons Row
                  Row(
                    children: [
                      // Delete Button
                      Container(
                        decoration: BoxDecoration(
                          color: AppColors.error.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: IconButton(
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(24),
                                ),
                                title: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: AppColors.error.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: const Icon(
                                        Icons.delete_forever,
                                        color: AppColors.error,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Text(
                                      "Delete Item?",
                                      style: AppTextStyles.h3,
                                    ),
                                  ],
                                ),
                                content: const Text(
                                  "This action cannot be undone. The item will be permanently removed.",
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(ctx),
                                    child: Text(
                                      "Cancel",
                                      style: TextStyle(
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  ),
                                  ElevatedButton(
                                    onPressed: () {
                                      Navigator.pop(ctx);
                                      Navigator.pop(context);
                                      _deleteItem(item);
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.error,
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                    child: const Text(
                                      "Delete",
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                          icon: const Icon(
                            Icons.delete_outline,
                            color: AppColors.error,
                            size: 24,
                          ),
                          tooltip: "Delete Item",
                        ),
                      ),

                      const SizedBox(width: 10),

                      // Print Barcode Button
                      Container(
                        decoration: BoxDecoration(
                          color: AppColors.accent.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: IconButton(
                          onPressed: () {
                            Navigator.pop(context);
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    BarcodeGeneratorScreen(item: item),
                              ),
                            );
                          },
                          icon: const Icon(
                            Icons.qr_code_2,
                            color: AppColors.accent,
                            size: 24,
                          ),
                          tooltip: "Print Barcode",
                        ),
                      ),

                      const SizedBox(width: 16),

                      // Update Button
                      Expanded(
                        child: Container(
                          height: 54,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                AppColors.success,
                                AppColors.success.withOpacity(0.8),
                              ],
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                            ),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.success.withOpacity(0.35),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: ElevatedButton.icon(
                            onPressed: () {
                              if (barcodeCtrl.text.trim().isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text("Barcode is required!"),
                                    behavior: SnackBarBehavior.floating,
                                    backgroundColor: AppColors.error,
                                  ),
                                );
                                return;
                              }
                              item.name = nameCtrl.text;
                              item.price =
                                  double.tryParse(priceCtrl.text) ?? item.price;
                              item.stock =
                                  int.tryParse(stockCtrl.text) ?? item.stock;
                              item.barcode = barcodeCtrl.text.trim();
                              item.lowStockThreshold =
                                  int.tryParse(thresholdCtrl.text) ??
                                  item.lowStockThreshold;
                              item.save();
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Row(
                                    children: [
                                      Icon(
                                        Icons.check_circle,
                                        color: Colors.white,
                                      ),
                                      SizedBox(width: 12),
                                      Text("Item Updated Successfully!"),
                                    ],
                                  ),
                                  behavior: SnackBarBehavior.floating,
                                  backgroundColor: AppColors.success,
                                ),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                            icon: const Icon(
                              Icons.check_circle_outline,
                              size: 22,
                            ),
                            label: const Text(
                              "UPDATE",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionLabel(String label, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 14, color: Colors.grey[500]),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: Colors.grey[500],
            letterSpacing: 1,
          ),
        ),
      ],
    );
  }

  Widget _buildStyledTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    required Color iconColor,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(
            color: Colors.grey[400],
            fontWeight: FontWeight.normal,
          ),
          prefixIcon: Container(
            margin: const EdgeInsets.all(10),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final inventoryProvider = context.watch<InventoryProvider>();
    final settingsProvider = context.watch<SettingsProvider>();

    // Auto-refresh displayed items if inventory changes externally
    // (This is a simplified way to sync, could be optimized)
    _displayedItems = inventoryProvider.inventory
        .where((item) {
          final query = _searchQuery.toLowerCase();
          return item.name.toLowerCase().contains(query) ||
              item.barcode.toLowerCase().contains(query);
        })
        .toList()
        .take(_currentPage * _pageSize)
        .toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        elevation: 0,
        title: Text("Stock Inventory", style: AppTextStyles.h2),
        actions: [
          IconButton(
            icon: const Icon(Icons.qr_code_2, color: AppColors.primary),
            tooltip: "Generate Barcodes",
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const BarcodeGeneratorScreen(),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(
              Icons.table_view_rounded,
              color: AppColors.success,
            ),
            onPressed: () {
              ReportingService.generateInventoryExcel(
                shopName: settingsProvider.shopName,
                items: inventoryProvider.inventory,
              );
            },
          ),
          IconButton(
            icon: const CircleAvatar(
              backgroundColor: AppColors.accent,
              child: Icon(Icons.add, color: Colors.white),
            ),
            onPressed: _addNewItemWithBarcode,
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: Column(
        children: [
          // BARCODE SEARCH BAR
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    onChanged: (val) => setState(() => _searchQuery = val),
                    decoration: InputDecoration(
                      hintText: "Search by Name or Code...",
                      prefixIcon: const Icon(Icons.search),
                      filled: true,
                      fillColor: Colors.grey[100],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                GestureDetector(
                  onTap: _scanForSearch,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.accent,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(
                      Icons.qr_code_scanner,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ITEM LIST
          Expanded(child: _buildItemList()),
        ],
      ),
    );
  }

  Widget _buildItemList() {
    if (_displayedItems.isEmpty && _searchQuery.isEmpty) {
      return const Center(child: Text("No items found. Scan or Add new."));
    }

    if (_displayedItems.isEmpty && _searchQuery.isNotEmpty) {
      return const Center(child: Text("No items match your search."));
    }

    return AnimationLimiter(
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _displayedItems.length + (_isLoadingMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == _displayedItems.length) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
            );
          }

          final item = _displayedItems[index];
          return AnimationConfiguration.staggeredList(
            position: index,
            duration: const Duration(milliseconds: 375),
            child: SlideAnimation(
              verticalOffset: 50.0,
              child: FadeInAnimation(
                child: Dismissible(
                  key: Key(item.id),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(Icons.delete, color: Colors.white),
                  ),
                  onDismissed: (direction) => _deleteItem(item),
                  confirmDismiss: (direction) async {
                    return await showDialog(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text("Delete?"),
                        content: const Text(
                          "Are you sure you want to delete this item?",
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx, false),
                            child: const Text("Keep"),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(ctx, true),
                            child: const Text(
                              "Delete",
                              style: TextStyle(color: Colors.red),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                  child: Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(color: Colors.grey[200]!),
                    ),
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ListTile(
                      onTap: () => _showEditSheet(item),
                      leading: Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: AppColors.accent.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.inventory_2_outlined,
                          color: AppColors.accent,
                        ),
                      ),
                      title: Text(
                        item.name,
                        style: AppTextStyles.bodyLarge.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      subtitle: Text(
                        "Rs ${item.price.toStringAsFixed(0)} | Code: ${item.barcode}",
                        style: AppTextStyles.bodySmall,
                      ),
                      trailing: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: item.stock < item.lowStockThreshold
                              ? AppColors.error.withOpacity(0.1)
                              : AppColors.success.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          "${item.stock} Left",
                          style: AppTextStyles.label.copyWith(
                            color: item.stock < item.lowStockThreshold
                                ? AppColors.error
                                : AppColors.success,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
