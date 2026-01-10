import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:path_provider/path_provider.dart';
import 'package:rsellx/providers/inventory_provider.dart';
import 'package:rsellx/providers/settings_provider.dart';
import '../../shared/widgets/full_scanner_screen.dart';
import '../../shared/widgets/text_scanner_screen.dart';
import '../../data/models/inventory_model.dart';
import '../../core/services/reporting_service.dart';
import 'add_item_sheet.dart';
import 'sell_item_sheet.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import '../barcode/barcode_generator_screen.dart';
import '../../shared/widgets/cart_badge.dart';
import '../cart/cart_screen.dart';
import '../../data/models/sale_model.dart';
import '../../providers/sales_provider.dart';

enum InventoryViewType { list, grid }

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
  InventoryViewType _viewType = InventoryViewType.list;

  int _currentPage = 1;
  static const int _pageSize = 20;
  bool _isLoadingMore = false;
  List<InventoryItem> _displayedItems = [];
  int _lastKnownInventoryCount = 0;
  
  // Store provider reference to avoid context.read in dispose
  InventoryProvider? _inventoryProvider;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    
    // Listen to inventory changes to keep the screen updated in real-time
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _inventoryProvider = context.read<InventoryProvider>();
        _inventoryProvider?.addListener(_onInventoryChanged);
        _loadInitialData();
      }
    });
  }

  void _onInventoryChanged() {
    if (mounted) {
      // Re-apply filters which also re-loads initial data from the provider
      _loadInitialData(); // Using _loadInitialData as _applyFilters is not defined and _loadInitialData performs the filtering.
    }
  }

  @override
  void dispose() {
    // Use stored reference instead of context.read to prevent crash after unmount
    _inventoryProvider?.removeListener(_onInventoryChanged);
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

  /// Helper method to get filtered and sorted items (DRY principle)
  List<InventoryItem> _getFilteredItems() {
    final inventoryProvider = _inventoryProvider ?? context.read<InventoryProvider>();
    final query = _searchQuery.toLowerCase();
    
    final filteredItems = inventoryProvider.inventory.where((item) {
      // Filter by Category
      if (_selectedCategory != null && item.category != _selectedCategory) {
        return false;
      }
      // Filter by SubCategory
      if (_selectedSubCategory != null && item.subCategory != _selectedSubCategory) {
        return false;
      }
      // Filter by Search (name, barcode, category, and subcategory)
      return item.name.toLowerCase().contains(query) ||
          item.barcode.toLowerCase().contains(query) ||
          item.category.toLowerCase().contains(query) ||
          item.subCategory.toLowerCase().contains(query);
    }).toList();

    // Sort alphabetically by name
    filteredItems.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    
    return filteredItems;
  }

  void _loadInitialData() {
    final allItems = _getFilteredItems();

    if (mounted) {
      setState(() {
        _currentPage = 1;
        _displayedItems = allItems.take(_pageSize).toList();
      });
    }
  }

  void _loadMoreData() {
    if (_isLoadingMore) return;

    final allItems = _getFilteredItems();

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
            const FullScannerScreen(title: "Scan to Search"),
      ),
    );

    if (barcode == null || barcode.isEmpty) return;

    setState(() {
      _searchQuery = barcode;
      _searchController.text = barcode;
    });
    
    _loadInitialData(); // Apply search filter

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("🔍 Searching for: $barcode"),
        duration: const Duration(seconds: 2),
        backgroundColor: AppColors.accent,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // === 2a. TEXT / HANDWRITING SEARCH ===
  Future<void> _scanTextForSearch() async {
    final String? scannedText = await Navigator.push<String>(
      context,
      MaterialPageRoute(
        builder: (context) => const TextScannerScreen(),
      ),
    );

    if (scannedText == null || scannedText.isEmpty) return;
    
    // Clean up newlines for search query
    String foundText = scannedText.replaceAll('\n', ' ');
    
    setState(() {
      _searchQuery = foundText;
      _searchController.text = foundText;
    });
    
    _loadInitialData(); // Trigger search

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Found: $foundText"),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
      ),
    );
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
    String? editImagePath = item.imagePath;
    final imagePicker = ImagePicker();

    Future<String> saveImageToAppDir(String tempPath) async {
      final appDir = await getApplicationDocumentsDirectory();
      final fileName = 'product_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final savedImage = await File(tempPath).copy('${appDir.path}/$fileName');
      return savedImage.path;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          
          void pickImage() {
            showModalBottomSheet(
              context: context,
              backgroundColor: Colors.white,
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              builder: (ctx) => SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text("Change Product Image", style: AppTextStyles.h3),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          GestureDetector(
                            onTap: () async {
                              Navigator.pop(ctx);
                              final XFile? image = await imagePicker.pickImage(
                                source: ImageSource.camera,
                                imageQuality: 70,
                                maxWidth: 800,
                              );
                              if (image != null) {
                                final savedPath = await saveImageToAppDir(image.path);
                                setModalState(() {
                                  editImagePath = savedPath;
                                });
                              }
                            },
                            child: Column(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: AppColors.accent.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: const Icon(Icons.camera_alt, color: AppColors.accent, size: 32),
                                ),
                                const SizedBox(height: 8),
                                const Text("Camera", style: TextStyle(color: AppColors.accent, fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                          GestureDetector(
                            onTap: () async {
                              Navigator.pop(ctx);
                              final XFile? image = await imagePicker.pickImage(
                                source: ImageSource.gallery,
                                imageQuality: 70,
                                maxWidth: 800,
                              );
                              if (image != null) {
                                final savedPath = await saveImageToAppDir(image.path);
                                setModalState(() {
                                  editImagePath = savedPath;
                                });
                              }
                            },
                            child: Column(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: AppColors.success.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: const Icon(Icons.photo_library, color: AppColors.success, size: 32),
                                ),
                                const SizedBox(height: 8),
                                const Text("Gallery", style: TextStyle(color: AppColors.success, fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                          if (editImagePath != null)
                            GestureDetector(
                              onTap: () {
                                Navigator.pop(ctx);
                                setModalState(() {
                                  editImagePath = null;
                                });
                              },
                              child: Column(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: AppColors.error.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: const Icon(Icons.delete, color: AppColors.error, size: 32),
                                  ),
                                  const SizedBox(height: 8),
                                  const Text("Remove", style: TextStyle(color: AppColors.error, fontWeight: FontWeight.bold)),
                                ],
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
            );
          }

          return GestureDetector(
            onTap: () => FocusScope.of(context).unfocus(),
            child: Padding(
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
                    physics: const BouncingScrollPhysics(),
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
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Product Image (Editable)
                          GestureDetector(
                            onTap: pickImage,
                            child: Container(
                              width: 70,
                              height: 70,
                              decoration: BoxDecoration(
                                gradient: editImagePath == null
                                    ? LinearGradient(
                                        colors: [AppColors.accent.withOpacity(0.8), AppColors.accent],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      )
                                    : null,
                                borderRadius: BorderRadius.circular(16),
                                border: editImagePath != null
                                    ? Border.all(color: AppColors.success, width: 2)
                                    : null,
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.accent.withOpacity(0.3),
                                    blurRadius: 12,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                                image: editImagePath != null && File(editImagePath!).existsSync()
                                    ? DecorationImage(
                                        image: FileImage(File(editImagePath!)),
                                        fit: BoxFit.cover,
                                      )
                                    : null,
                              ),
                              child: Stack(
                                children: [
                                  if (editImagePath == null || !File(editImagePath!).existsSync())
                                    const Center(
                                      child: Icon(Icons.inventory_2, color: Colors.white, size: 28),
                                    ),
                                  Positioned(
                                    bottom: 4,
                                    right: 4,
                                    child: Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(8),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withOpacity(0.1),
                                            blurRadius: 4,
                                          ),
                                        ],
                                      ),
                                      child: Icon(Icons.camera_alt, color: AppColors.accent, size: 14),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text("Edit Product", style: AppTextStyles.h2),
                                const SizedBox(height: 4),
                                Text("Tap image to change photo", style: TextStyle(color: Colors.grey[500], fontSize: 12)),
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
                              item.imagePath = editImagePath;
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
                  ],
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


  // === 5. IMAGE PREVIEW (WITH ZOOM) ===
  void _showImagePreview(String imagePath, String productName) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(10), // Minimal padding for max view
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Zoomable Image
            InteractiveViewer(
              minScale: 0.5,
              maxScale: 4.0,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  color: Colors.white,
                ),
                padding: const EdgeInsets.all(4), // White border effect
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.file(
                    File(imagePath),
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),
            
            // Name Label (Bottom)
            Positioned(
              bottom: 20,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  productName,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
            ),

            // Close Button (Top Right)
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
        // Trigger a refresh if the inventory has changed since we last loaded it.
        // We use a listener in initState now or just check a hash/timestamp if needed.
        // For simplicity, we can load initial data whenever the provider notifies, 
        // but we must be careful not to create an infinite loop.
        // A better way is to listen to the provider in initState.
        
        final settingsProvider = context.watch<SettingsProvider>();
        
        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            title: Text("Stock Inventory", style: AppTextStyles.h2),
            actions: [
              IconButton(
                icon: Icon(
                  _viewType == InventoryViewType.list ? Icons.grid_view_rounded : Icons.view_list_rounded,
                  color: AppColors.accent,
                ),
                tooltip: _viewType == InventoryViewType.list ? "Switch to Grid" : "Switch to List",
                onPressed: () {
                  setState(() {
                    _viewType = _viewType == InventoryViewType.list 
                        ? InventoryViewType.grid 
                        : InventoryViewType.list;
                  });
                },
              ),
              CartBadge(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const CartScreen()),
                ),
              ),
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
                    const SizedBox(width: 8),
                    // TEXT SCANNER
                    GestureDetector(
                      onTap: _scanTextForSearch,
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(color: Colors.indigo, borderRadius: BorderRadius.circular(16)),
                        child: const Icon(Icons.document_scanner, color: Colors.white),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // QR SCANNER
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

  void _addToCart(InventoryItem item) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    
    // Check if item is available in stock
    if (item.stock <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("❌ Out of stock!"),
          duration: Duration(milliseconds: 800),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final salesProvider = context.read<SalesProvider>();
    
    // Check if item already exists in cart
    final cartList = salesProvider.cart;
    final existingItem = cartList.cast<SaleRecord?>().firstWhere(
      (c) => c?.itemId == item.id, 
      orElse: () => null
    );
    
    if (existingItem != null) {
      // Increment existing cart entry
      existingItem.qty += 1;
      existingItem.profit = (existingItem.price - existingItem.actualPrice) * existingItem.qty;
      existingItem.imagePath = item.imagePath; // Ensure image is synced
      existingItem.save(); 
      
      // Deduct from inventory stock (this triggers UI update via listener)
      item.stock -= 1;
      item.save(); 
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("🛒 ${item.name} x${existingItem.qty}"),
          duration: const Duration(milliseconds: 600),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else {
      // Add new cart entry
      final cartItem = SaleRecord(
        id: "cart_${item.id}_${DateTime.now().millisecondsSinceEpoch}",
        itemId: item.id,
        name: item.name,
        price: item.price,
        actualPrice: item.price, 
        qty: 1,
        profit: 0.0,
        date: DateTime.now(),
        status: "Cart",
        category: item.category,
        size: item.size,
        subCategory: item.subCategory,
        weight: item.weight,
        imagePath: item.imagePath,
      );
      
      // Deduct from inventory stock first to ensure immediate UI feedback
      item.stock -= 1;
      item.save(); 
      
      // Add to sales provider (Note: SalesProvider also has deduction logic, 
      // but since item is already updated/saved, it will see the new value or we can clean up provider logic)
      salesProvider.addToCartSilent(cartItem);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("🛒 ${item.name} added!"),
          duration: const Duration(milliseconds: 600),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _showSellSheet(InventoryItem item) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      builder: (context) => SellItemSheet(item: item),
    );
  }

  Widget _buildItemList() {
    if (_displayedItems.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
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

    if (_viewType == InventoryViewType.grid) {
      return AnimationLimiter(
        child: GridView.builder(
          controller: _scrollController,
          padding: const EdgeInsets.all(16),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 0.62, // Taller cards for more content space
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemCount: _displayedItems.length,
          itemBuilder: (context, index) {
            final item = _displayedItems[index];
            return AnimationConfiguration.staggeredGrid(
              position: index,
              duration: const Duration(milliseconds: 375),
              columnCount: 2,
              child: ScaleAnimation(
                child: FadeInAnimation(
                  child: Dismissible(
                    key: Key("grid_${item.id}"),
                    direction: DismissDirection.horizontal,
                    dismissThresholds: const {
                      DismissDirection.startToEnd: 0.15, // 15% swipe only (Fast)
                      DismissDirection.endToStart: 0.4,
                    },
                    background: _buildCartBackground(),
                    secondaryBackground: _buildDeleteBackground(),
                    confirmDismiss: (direction) async {
                      if (direction == DismissDirection.startToEnd) {
                        _addToCart(item);
                        return false;
                      }
                      return await _confirmDelete();
                    },
                    onDismissed: (direction) {
                      if (direction == DismissDirection.endToStart) {
                        _deleteItem(item);
                      }
                    },
                    child: _buildGridItem(item),
                  ),
                ),
              ),
            );
          },
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
                  direction: DismissDirection.horizontal,
                  dismissThresholds: const {
                    DismissDirection.startToEnd: 0.15, // 15% swipe only (Fast)
                    DismissDirection.endToStart: 0.4,
                  },
                  background: _buildCartBackground(),
                  secondaryBackground: _buildDeleteBackground(),
                  onDismissed: (direction) {
                    if (direction == DismissDirection.endToStart) {
                      _deleteItem(item);
                    }
                  },
                  confirmDismiss: (direction) async {
                    if (direction == DismissDirection.startToEnd) {
                      _addToCart(item);
                      return false;
                    }
                    return await _confirmDelete();
                  },
                  child: _viewType == InventoryViewType.list 
                    ? _buildListItem(item) 
                    : _buildListItem(item), // Fallback, though builder handles grid separately below
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildListItem(InventoryItem item) {
    bool lowStock = item.stock < item.lowStockThreshold;
    return Card(
      elevation: 1,
      shadowColor: Colors.black.withOpacity(0.05),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14), 
        side: BorderSide(color: lowStock ? AppColors.error.withOpacity(0.3) : Colors.grey[200]!)
      ),
      margin: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        onTap: () => _showEditSheet(item),
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Left: Image + SELL Button
              Column(
                children: [
                  // Product Image
                  GestureDetector(
                    onTap: item.imagePath != null && File(item.imagePath!).existsSync()
                        ? () => _showImagePreview(item.imagePath!, item.name)
                        : null,
                    child: Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.grey[300]!, width: 1),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(9),
                        child: item.imagePath != null && File(item.imagePath!).existsSync()
                            ? Image.file(
                                File(item.imagePath!),
                                fit: BoxFit.cover,
                                width: 60,
                                height: 60,
                                filterQuality: FilterQuality.high,
                              )
                            : Icon(Icons.inventory_2_rounded, color: Colors.grey[400], size: 26),
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  // SELL Button (Below Image)
                  GestureDetector(
                    onTap: () => _showSellSheet(item),
                    child: Container(
                      width: 60,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: AppColors.success,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.shopping_cart_checkout, color: Colors.white, size: 16),
                          SizedBox(height: 2),
                          Text("SELL", style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 12),
              
              // Middle: Product Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Product Name
                    Text(
                      item.name, 
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black87),
                      maxLines: 1, 
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    
                    // Price
                    Row(
                      children: [
                        Text("Rs ", style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.grey[600])),
                        Text(
                          item.price.toStringAsFixed(0), 
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.success),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    
                    // Barcode
                    if (item.barcode != "N/A")
                      Row(
                        children: [
                          Icon(Icons.qr_code_2, size: 12, color: Colors.grey[500]),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              item.barcode, 
                              style: TextStyle(fontSize: 10, color: Colors.grey[500]),
                              maxLines: 1, 
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    const SizedBox(height: 6),
                    
                    // Category Tags
                    Wrap(
                      spacing: 4,
                      runSpacing: 4,
                      children: [
                        if (item.category != "General") _buildCompactTag(item.category, Colors.purple, Icons.category, true),
                        if (item.subCategory != "N/A") _buildCompactTag(item.subCategory, Colors.indigo, Icons.account_tree, true),
                        if (item.size != "N/A") _buildCompactTag(item.size, Colors.orange, Icons.straighten, false),
                        if (item.weight != "N/A") _buildCompactTag(item.weight, Colors.teal, Icons.scale, false),
                      ],
                    ),
                  ],
                ),
              ),
              
              // Right: Stock
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: lowStock ? AppColors.error.withOpacity(0.1) : AppColors.success.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    Text(
                      "${item.stock}", 
                      style: TextStyle(
                        fontSize: 18, 
                        fontWeight: FontWeight.bold, 
                        color: lowStock ? AppColors.error : AppColors.success,
                      ),
                    ),
                    Text(
                      "Stock", 
                      style: TextStyle(
                        fontSize: 8, 
                        color: lowStock ? AppColors.error : AppColors.success,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGridItem(InventoryItem item) {
    bool lowStock = item.stock < item.lowStockThreshold;
    return Card(
      elevation: 2,
      clipBehavior: Clip.antiAlias,
      shadowColor: Colors.black.withOpacity(0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16), 
        side: BorderSide(color: lowStock ? AppColors.error.withOpacity(0.3) : Colors.grey[200]!, width: lowStock ? 2 : 1)
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image Section with Better Quality
          Expanded(
            flex: 3,
            child: Stack(
              children: [
                GestureDetector(
                  onTap: item.imagePath != null && File(item.imagePath!).existsSync()
                      ? () => _showImagePreview(item.imagePath!, item.name)
                      : null,
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      border: Border(bottom: BorderSide(color: Colors.grey[200]!, width: 1)),
                    ),
                    child: item.imagePath != null && File(item.imagePath!).existsSync()
                        ? Image.file(
                            File(item.imagePath!),
                            fit: BoxFit.cover,
                            width: double.infinity,
                            height: double.infinity,
                            filterQuality: FilterQuality.high,
                            cacheWidth: 300, // Cache at higher resolution for clearer display
                          )
                        : Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.inventory_2_outlined, size: 36, color: Colors.grey[350]),
                                const SizedBox(height: 4),
                                Text("No Image", style: TextStyle(fontSize: 10, color: Colors.grey[400])),
                              ],
                            ),
                          ),
                  ),
                ),
                // Quick Actions: SELL
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: InkWell(
                    onTap: () => _showSellSheet(item),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppColors.success,
                        borderRadius: const BorderRadius.only(topLeft: Radius.circular(16)),
                        boxShadow: [
                          BoxShadow(color: AppColors.success.withOpacity(0.3), blurRadius: 4),
                        ],
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.shopping_cart_checkout, size: 14, color: Colors.white),
                          SizedBox(width: 4),
                          Text("SELL", style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Info Section (Compact & Clear)
          InkWell(
            onTap: () => _showEditSheet(item),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Product Name
                  Text(
                    item.name,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  
                  // Price Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Text("Rs ", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.success)),
                          Text(
                            item.price.toStringAsFixed(0),
                            style: const TextStyle(color: AppColors.success, fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                        ],
                      ),
                      // Stock indicator (small inline)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: lowStock ? AppColors.error.withOpacity(0.1) : AppColors.success.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.inventory_2, size: 10, color: lowStock ? AppColors.error : AppColors.success),
                            const SizedBox(width: 3),
                            Text(
                              "${item.stock}",
                              style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: lowStock ? AppColors.error : AppColors.success),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  
                  // Category Tags
                  Wrap(
                    spacing: 4,
                    runSpacing: 4,
                    children: [
                      _buildCompactTag(item.category, Colors.purple, Icons.category, true),
                      if (item.subCategory != "N/A")
                        _buildCompactTag(item.subCategory, Colors.indigo, Icons.account_tree, true),
                    ],
                  ),
                  const SizedBox(height: 6),
                  
                  // Barcode
                  if (item.barcode != "N/A")
                    Row(
                      children: [
                        Icon(Icons.qr_code_2, size: 11, color: Colors.grey[400]),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            item.barcode,
                            style: TextStyle(color: Colors.grey[500], fontSize: 9, fontFamily: 'monospace'),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Removed _buildDetailedItem as per request


  Widget _buildCompactTag(String label, Color color, IconData icon, bool clickable) {
    return GestureDetector(
      onTap: clickable ? () {
        setState(() {
          if (icon == Icons.category) _selectedCategory = label;
          if (icon == Icons.account_tree) _selectedSubCategory = label;
          _searchController.clear();
          _searchQuery = "";
        });
        _loadInitialData();
      } : null,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(6), border: Border.all(color: color.withOpacity(0.2))),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 10, color: color),
            const SizedBox(width: 4),
            Text(label, style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.w600)),
            if (clickable) ...[const SizedBox(width: 3), Icon(Icons.filter_list, size: 9, color: color)],
          ],
        ),
      ),
    );
  }

  Widget _buildDetailedTag(String title, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(6)),
      child: Text("$title: $label", style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildStockBadge(InventoryItem item) {
    bool lowStock = item.stock < item.lowStockThreshold;
    return Column(
      children: [
        Text("${item.stock}", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: lowStock ? AppColors.error : AppColors.success)),
        Text("STOCKS", style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: lowStock ? AppColors.error : AppColors.success, letterSpacing: 0.5)),
      ],
    );
  }

  Widget _buildDeleteBackground() {
    bool isGrid = _viewType == InventoryViewType.grid;
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.error,
        borderRadius: BorderRadius.circular(16),
      ),
      alignment: Alignment.centerRight,
      padding: EdgeInsets.symmetric(horizontal: isGrid ? 15 : 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          if (!isGrid) ...[
            const Text("DELETE", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 1)),
            const SizedBox(width: 12),
          ],
          const Icon(Icons.delete_sweep_rounded, color: Colors.white, size: 28),
        ],
      ),
    );
  }

  Widget _buildCartBackground() {
    bool isGrid = _viewType == InventoryViewType.grid;
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.accent,
        borderRadius: BorderRadius.circular(16),
      ),
      alignment: Alignment.centerLeft,
      padding: EdgeInsets.symmetric(horizontal: isGrid ? 15 : 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          const Icon(Icons.add_shopping_cart_rounded, color: Colors.white, size: 28),
          if (!isGrid) ...[
            const SizedBox(width: 12),
            const Text("ADD TO CART", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 1)),
          ],
        ],
      ),
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
