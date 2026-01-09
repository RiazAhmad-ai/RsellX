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
  String? _selectedCategory; // Null means "All"
  String? _selectedSubCategory; // Null means "All"

  int _currentPage = 1;
  static const int _pageSize = 20;
  bool _isLoadingMore = false;
  List<InventoryItem> _displayedItems = [];
  int _lastKnownInventoryCount = 0;

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
       // Filter by Category
      if (_selectedCategory != null && item.category != _selectedCategory) {
        return false;
      }
      // Filter by SubCategory
      if (_selectedSubCategory != null && item.subCategory != _selectedSubCategory) {
        return false;
      }
      // Filter by Search (name, barcode, category, and subcategory)
      final query = _searchQuery.toLowerCase();
      return item.name.toLowerCase().contains(query) ||
          item.barcode.toLowerCase().contains(query) ||
          item.category.toLowerCase().contains(query) ||
          item.subCategory.toLowerCase().contains(query);
    }).toList();

    allItems.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

    if (mounted) {
      setState(() {
        _currentPage = 1;
        _displayedItems = allItems.take(_pageSize).toList();
      });
    }
  }

  void _loadMoreData() {
    if (_isLoadingMore) return;

    final inventoryProvider = context.read<InventoryProvider>();
    final allItems = inventoryProvider.inventory.where((item) {
      if (_selectedCategory != null && item.category != _selectedCategory) {
        return false;
      }
      // Filter by SubCategory
      if (_selectedSubCategory != null && item.subCategory != _selectedSubCategory) {
        return false;
      }
      // Filter by Search (name, barcode, category, and subcategory)
      final query = _searchQuery.toLowerCase();
      return item.name.toLowerCase().contains(query) ||
          item.barcode.toLowerCase().contains(query) ||
          item.category.toLowerCase().contains(query) ||
          item.subCategory.toLowerCase().contains(query);
    }).toList();

    allItems.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

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
    // First remove from displayed list to prevent Dismissible conflict
    setState(() {
      _displayedItems.removeWhere((i) => i.id == item.id);
      _lastKnownInventoryCount--; // Prevent reload trigger
    });
    // Then delete from database
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
    final priceCtrl = TextEditingController(text: item.price.toStringAsFixed(0));
    final stockCtrl = TextEditingController(text: item.stock.toString());
    final barcodeCtrl = TextEditingController(text: item.barcode);
    final categoryCtrl = TextEditingController(text: item.category);
    final subCategoryCtrl = TextEditingController(text: item.subCategory);
    final sizeCtrl = TextEditingController(text: item.size);
    final weightCtrl = TextEditingController(text: item.weight);
    final thresholdCtrl = TextEditingController(text: item.lowStockThreshold.toString());

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
              padding: const EdgeInsets.only(bottom: 24, top: 16, left: 24, right: 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [AppColors.accent.withOpacity(0.8), AppColors.accent],
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
                        child: const Icon(Icons.edit_note, color: Colors.white, size: 28),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("Edit Product", style: AppTextStyles.h2),
                            const SizedBox(height: 4),
                            Text("Update item details below", style: TextStyle(color: Colors.grey[500], fontSize: 13)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),
                  
                  _buildSectionLabel("BARCODE / SKU", Icons.qr_code),
                  const SizedBox(height: 10),
                  _buildStyledTextField(controller: barcodeCtrl, hint: "Item Barcode", icon: Icons.qr_code_2, iconColor: AppColors.primary),
                  
                  const SizedBox(height: 20),
                  
                  _buildSectionLabel("PRODUCT NAME", Icons.inventory_2),
                  const SizedBox(height: 10),
                  _buildStyledTextField(controller: nameCtrl, hint: "Enter product name", icon: Icons.shopping_bag_outlined, iconColor: AppColors.accent),
                  
                  const SizedBox(height: 20),

                  // Category & Sub-Category Row
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildSectionLabel("CATEGORY", Icons.category),
                            const SizedBox(height: 10),
                            _buildStyledTextField(controller: categoryCtrl, hint: "General", icon: Icons.grid_view, iconColor: Colors.purple),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildSectionLabel("SUB-CATEGORY", Icons.account_tree_outlined),
                            const SizedBox(height: 10),
                            _buildStyledTextField(controller: subCategoryCtrl, hint: "N/A", icon: Icons.account_tree, iconColor: Colors.indigo),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  
                  // Size & Weight Row
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildSectionLabel("SIZE", Icons.straighten),
                            const SizedBox(height: 10),
                            _buildStyledTextField(controller: sizeCtrl, hint: "N/A", icon: Icons.format_size, iconColor: Colors.orange),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildSectionLabel("WEIGHT", Icons.scale),
                            const SizedBox(height: 10),
                            _buildStyledTextField(controller: weightCtrl, hint: "e.g. 500g", icon: Icons.scale, iconColor: Colors.teal),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildSectionLabel("PRICE (Rs)", Icons.attach_money),
                            const SizedBox(height: 10),
                            _buildStyledTextField(controller: priceCtrl, hint: "0", icon: Icons.currency_rupee, iconColor: AppColors.success, keyboardType: TextInputType.number),
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
                            _buildStyledTextField(controller: stockCtrl, hint: "0", icon: Icons.numbers, iconColor: AppColors.secondary, keyboardType: TextInputType.number),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  
                  _buildSectionLabel("LOW STOCK ALERT", Icons.warning_amber),
                  const SizedBox(height: 10),
                  _buildStyledTextField(controller: thresholdCtrl, hint: "Alert when stock falls below", icon: Icons.notifications_active_outlined, iconColor: AppColors.warning, keyboardType: TextInputType.number),
                  
                  const SizedBox(height: 32),
                  
                  Row(
                    children: [
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
                                title: const Text("Delete Item?"),
                                content: const Text("This cannot be undone."),
                                actions: [
                                  TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
                                  TextButton(
                                    onPressed: () {
                                      Navigator.pop(ctx);
                                      Navigator.pop(context);
                                      _deleteItem(item);
                                    },
                                    child: const Text("Delete", style: TextStyle(color: Colors.red)),
                                  ),
                                ],
                              ),
                            );
                          },
                          icon: const Icon(Icons.delete_outline, color: AppColors.error, size: 24),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Container(
                        decoration: BoxDecoration(color: AppColors.accent.withOpacity(0.1), borderRadius: BorderRadius.circular(14)),
                        child: IconButton(
                          onPressed: () {
                            Navigator.pop(context);
                            Navigator.push(context, MaterialPageRoute(builder: (context) => BarcodeGeneratorScreen(item: item)));
                          },
                          icon: const Icon(Icons.qr_code_2, color: AppColors.accent, size: 24),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: SizedBox(
                          height: 54,
                          child: ElevatedButton(
                            onPressed: () {
                              if (barcodeCtrl.text.trim().isEmpty) return;
                              item.name = nameCtrl.text;
                              item.price = double.tryParse(priceCtrl.text) ?? item.price;
                              item.stock = int.tryParse(stockCtrl.text) ?? item.stock;
                              item.barcode = barcodeCtrl.text.trim();
                              item.category = categoryCtrl.text.trim().isEmpty ? "General" : categoryCtrl.text.trim();
                              item.subCategory = subCategoryCtrl.text.trim().isEmpty ? "N/A" : subCategoryCtrl.text.trim();
                              item.size = sizeCtrl.text.trim().isEmpty ? "N/A" : sizeCtrl.text.trim();
                              item.weight = weightCtrl.text.trim().isEmpty ? "N/A" : weightCtrl.text.trim();
                              item.lowStockThreshold = int.tryParse(thresholdCtrl.text) ?? item.lowStockThreshold;
                              item.save();
                              Navigator.pop(context);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.success,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            ),
                            child: const Text("UPDATE", style: TextStyle(fontWeight: FontWeight.bold)),
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
    return Row(children: [Icon(icon, size: 14, color: Colors.grey[500]), const SizedBox(width: 6), Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.grey[500], letterSpacing: 1))]);
  }

  Widget _buildStyledTextField({required TextEditingController controller, required String hint, required IconData icon, required Color iconColor, TextInputType keyboardType = TextInputType.text}) {
    return Container(
      decoration: BoxDecoration(color: Colors.grey[50], borderRadius: BorderRadius.circular(14), border: Border.all(color: Colors.grey[200]!)),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
        decoration: InputDecoration(
          hintText: hint,
          prefixIcon: Icon(icon, color: iconColor, size: 20),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.all(16),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Use Consumer to rebuild when inventory changes
    return Consumer<InventoryProvider>(
      builder: (context, inventoryProvider, _) {
        // Check if inventory count changed (item added/deleted)
        final currentInventoryCount = inventoryProvider.inventory.length;
        if (currentInventoryCount != _lastKnownInventoryCount) {
          _lastKnownInventoryCount = currentInventoryCount;
          // Schedule reload after this frame
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) _loadInitialData();
          });
        }
        final settingsProvider = context.watch<SettingsProvider>();
        
        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            title: Text("Stock Inventory", style: AppTextStyles.h2),
            actions: [
              IconButton(
                icon: const Icon(Icons.table_view_rounded, color: AppColors.success),
                onPressed: () {
                  final inventoryProvider = context.read<InventoryProvider>();
                  ReportingService.generateInventoryExcel(
                    shopName: settingsProvider.shopName,
                    items: inventoryProvider.inventory
                  );
                },
              ),
              IconButton(
                icon: const CircleAvatar(backgroundColor: AppColors.accent, child: Icon(Icons.add, color: Colors.white)),
                onPressed: _addNewItemWithBarcode,
              ),
              const SizedBox(width: 16),
            ],
          ),
          body: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                color: Colors.white,
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                        controller: _searchController,
                        onChanged: (val) {
                          setState(() => _searchQuery = val);
                          _loadInitialData();
                        },
                        decoration: InputDecoration(
                          hintText: "Search by Name, Code or Category...",
                          prefixIcon: const Icon(Icons.search),
                          filled: true,
                          fillColor: Colors.grey[100],
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    GestureDetector(
                      onTap: _scanForSearch,
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(color: AppColors.accent, borderRadius: BorderRadius.circular(16)),
                        child: const Icon(Icons.qr_code_scanner, color: Colors.white),
                      ),
                    ),
                  ],
                ),
                // Active Filter Chips
                if (_selectedCategory != null || _selectedSubCategory != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Row(
                      children: [
                        const Text("Filters:", style: TextStyle(color: Colors.grey, fontSize: 12)),
                        const SizedBox(width: 8),
                        if (_selectedCategory != null)
                          Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: InputChip(
                              label: Text(_selectedCategory!, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 12)),
                              backgroundColor: Colors.purple,
                              onDeleted: () {
                                setState(() {
                                  _selectedCategory = null;
                                });
                                _loadInitialData();
                              },
                              deleteIcon: const Icon(Icons.close, size: 14, color: Colors.white),
                              avatar: const Icon(Icons.category, size: 14, color: Colors.white),
                            ),
                          ),
                        if (_selectedSubCategory != null)
                          InputChip(
                            label: Text(_selectedSubCategory!, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 12)),
                            backgroundColor: Colors.indigo,
                            onDeleted: () {
                              setState(() {
                                _selectedSubCategory = null;
                              });
                              _loadInitialData();
                            },
                            deleteIcon: const Icon(Icons.close, size: 14, color: Colors.white),
                            avatar: const Icon(Icons.account_tree, size: 14, color: Colors.white),
                          ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          Expanded(child: _buildItemList()),
        ],
      ),
        );
      },
    );
  }

  // === 5. MANUAL SELL DIALOG ===
  void _showManualSellDialog() {
    final codeController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Manual Sell"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("Enter Item Barcode / Code Number:"),
            const SizedBox(height: 16),
            TextField(
              controller: codeController,
              autofocus: true,
              keyboardType: TextInputType.text, // Alphanumeric support
              decoration: const InputDecoration(
                hintText: "e.g. 1001",
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.qr_code_2),
              ),
              onSubmitted: (_) => _processManualSell(codeController.text),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () => _processManualSell(codeController.text),
            child: const Text("Sell"),
          ),
        ],
      ),
    );
  }

  void _processManualSell(String code) {
    if (code.trim().isEmpty) return;
    
    Navigator.pop(context); // Close dialog
    
    final inventoryProvider = context.read<InventoryProvider>();
    try {
      final match = inventoryProvider.inventory.firstWhere(
        (item) => item.barcode == code.trim(),
      );

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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("❌ Item not found with code: $code"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _buildItemList() {
    if (_displayedItems.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
             Icon(Icons.inventory_2_outlined, size: 60, color: Colors.grey[300]),
             const SizedBox(height: 16),
             Text(
               _selectedCategory != null ? "No items in '$_selectedCategory'" : "No items found",
               style: TextStyle(color: Colors.grey[500]),
             ),
          ],
        ),
      );
    }

    return AnimationLimiter(
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: _displayedItems.length,
        itemBuilder: (context, index) {
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
                  background: _buildDeleteBackground(),
                  onDismissed: (_) => _deleteItem(item),
                  confirmDismiss: (dir) => _confirmDelete(),
                  child: Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16), 
                      side: BorderSide(color: Colors.grey[200]!)
                    ),
                    margin: const EdgeInsets.only(bottom: 12),
                    child: InkWell(
                      onTap: () => _showEditSheet(item),
                      borderRadius: BorderRadius.circular(16),
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Top Row: Icon, Name, Stock Badge
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Product Icon
                                Container(
                                  width: 48, height: 48,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [AppColors.accent.withOpacity(0.2), AppColors.accent.withOpacity(0.1)],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Icon(Icons.inventory_2_rounded, color: AppColors.accent, size: 24),
                                ),
                                const SizedBox(width: 12),
                                // Name and Price
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item.name, 
                                        style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.bold),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          Icon(Icons.currency_rupee, size: 14, color: Colors.grey[600]),
                                          Text(
                                            item.price.toStringAsFixed(0), 
                                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.grey[700])
                                          ),
                                          const SizedBox(width: 12),
                                          Icon(Icons.qr_code_2, size: 14, color: Colors.grey[500]),
                                          const SizedBox(width: 4),
                                          Text(
                                            item.barcode, 
                                            style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                // Stock Badge
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: item.stock < item.lowStockThreshold 
                                        ? AppColors.error.withOpacity(0.1) 
                                        : AppColors.success.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Column(
                                    children: [
                                      Text(
                                        "${item.stock}",
                                        style: TextStyle(
                                          fontSize: 18, 
                                          fontWeight: FontWeight.bold,
                                          color: item.stock < item.lowStockThreshold ? AppColors.error : AppColors.success,
                                        ),
                                      ),
                                      Text(
                                        "Stock",
                                        style: TextStyle(
                                          fontSize: 9, 
                                          color: item.stock < item.lowStockThreshold ? AppColors.error : AppColors.success,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            
                            // Tags Row (Category, SubCategory, Size, Weight)
                            if (item.category != "General" || item.subCategory != "N/A" || item.size != "N/A" || item.weight != "N/A")
                              Padding(
                                padding: const EdgeInsets.only(top: 12),
                                child: Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: [
                                    // CLICKABLE CATEGORY CHIP
                                    if (item.category != "General")
                                      GestureDetector(
                                        onTap: () {
                                          setState(() {
                                            _selectedCategory = item.category;
                                            _selectedSubCategory = null;
                                            _searchController.clear();
                                            _searchQuery = "";
                                          });
                                          _loadInitialData();
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(
                                              content: Text("Filtering: ${item.category}"), 
                                              duration: const Duration(seconds: 1),
                                              behavior: SnackBarBehavior.floating,
                                            ),
                                          );
                                        },
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                          decoration: BoxDecoration(
                                            color: Colors.purple.withOpacity(0.12), 
                                            borderRadius: BorderRadius.circular(8),
                                            border: Border.all(color: Colors.purple.withOpacity(0.25)),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              const Icon(Icons.category, size: 12, color: Colors.purple),
                                              const SizedBox(width: 4),
                                              Text(
                                                item.category, 
                                                style: const TextStyle(fontSize: 11, color: Colors.purple, fontWeight: FontWeight.w600)
                                              ),
                                              const SizedBox(width: 4),
                                              const Icon(Icons.filter_list, size: 10, color: Colors.purple),
                                            ],
                                          ),
                                        ),
                                      ),
                                    
                                    // CLICKABLE SUBCATEGORY CHIP
                                    if (item.subCategory != "N/A")
                                      GestureDetector(
                                        onTap: () {
                                          setState(() {
                                            _selectedSubCategory = item.subCategory;
                                            _searchController.clear();
                                            _searchQuery = "";
                                          });
                                          _loadInitialData();
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(
                                              content: Text("Filtering: ${item.subCategory}"), 
                                              duration: const Duration(seconds: 1),
                                              behavior: SnackBarBehavior.floating,
                                            ),
                                          );
                                        },
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                          decoration: BoxDecoration(
                                            color: Colors.indigo.withOpacity(0.12), 
                                            borderRadius: BorderRadius.circular(8),
                                            border: Border.all(color: Colors.indigo.withOpacity(0.25)),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              const Icon(Icons.account_tree, size: 12, color: Colors.indigo),
                                              const SizedBox(width: 4),
                                              Text(
                                                item.subCategory, 
                                                style: const TextStyle(fontSize: 11, color: Colors.indigo, fontWeight: FontWeight.w600)
                                              ),
                                              const SizedBox(width: 4),
                                              const Icon(Icons.filter_list, size: 10, color: Colors.indigo),
                                            ],
                                          ),
                                        ),
                                      ),
                                    
                                    // Size Tag (Not Clickable)
                                    if (item.size != "N/A")
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                        decoration: BoxDecoration(
                                          color: Colors.orange.withOpacity(0.12), 
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const Icon(Icons.straighten, size: 12, color: Colors.orange),
                                            const SizedBox(width: 4),
                                            Text(
                                              item.size, 
                                              style: const TextStyle(fontSize: 11, color: Colors.orange, fontWeight: FontWeight.w600)
                                            ),
                                          ],
                                        ),
                                      ),
                                    
                                    // Weight Tag (Not Clickable)
                                    if (item.weight != "N/A")
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                        decoration: BoxDecoration(
                                          color: Colors.teal.withOpacity(0.12), 
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const Icon(Icons.scale, size: 12, color: Colors.teal),
                                            const SizedBox(width: 4),
                                            Text(
                                              item.weight, 
                                              style: const TextStyle(fontSize: 11, color: Colors.teal, fontWeight: FontWeight.w600)
                                            ),
                                          ],
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                          ],
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

  Widget _buildDeleteBackground() {
    return Container(
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(16)),
      child: const Icon(Icons.delete, color: Colors.white),
    );
  }

  Future<bool?> _confirmDelete() async {
    return await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Delete?"),
        content: const Text("Permanently delete this item?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Keep")),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text("Delete", style: TextStyle(color: Colors.red))),
        ],
      ),
    );
  }
}
