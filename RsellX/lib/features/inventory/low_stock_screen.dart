import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:provider/provider.dart';
import '../../core/utils/image_path_helper.dart';
import 'package:rsellx/providers/inventory_provider.dart';
import 'package:rsellx/data/models/inventory_model.dart';
import '../../core/theme/app_colors.dart';

class LowStockScreen extends StatefulWidget {
  const LowStockScreen({super.key});

  @override
  State<LowStockScreen> createState() => _LowStockScreenState();
}

class _LowStockScreenState extends State<LowStockScreen> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _audioPlayer.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _showOrderSheet(InventoryItem item) {
    final TextEditingController qtyController = TextEditingController();
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          top: 24,
          bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.add_shopping_cart, color: AppColors.accent, size: 28),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    "Add Stock",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  if (item.imagePath != null && ImagePathHelper.exists(item.imagePath!))
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.file(
                        ImagePathHelper.getFile(item.imagePath!),
                        width: 50,
                        height: 50,
                        fit: BoxFit.cover,
                      ),
                    )
                  else
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.inventory_2, color: Colors.grey),
                    ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.name,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "Current Stock: ${item.stock}",
                          style: TextStyle(
                            color: item.stock <= 0 ? Colors.red : Colors.orange,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              "Quantity to Add",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: qtyController,
              autofocus: true,
              keyboardType: TextInputType.number,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              decoration: InputDecoration(
                hintText: "Enter quantity",
                prefixIcon: const Icon(Icons.add_circle_outline, color: AppColors.accent),
                filled: true,
                fillColor: const Color(0x0D448AFF),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.accent, width: 2),
                ),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: () {
                  final qtyToAdd = int.tryParse(qtyController.text) ?? 0;
                  if (qtyToAdd <= 0) {
                    HapticFeedback.heavyImpact();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Please enter a valid quantity!"),
                        backgroundColor: Colors.red,
                        duration: Duration(milliseconds: 600),
                      ),
                    );
                    return;
                  }

                  // Update stock
                  item.stock += qtyToAdd;
                  item.save();

                  // Play success beep
                  _audioPlayer.play(AssetSource('scanner_beep.mp3'));
                  HapticFeedback.lightImpact();

                  Navigator.pop(context);

                  ScaffoldMessenger.of(context).clearSnackBars();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Row(
                        children: [
                          const Icon(Icons.check_circle, color: Colors.white),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              "$qtyToAdd units added to ${item.name}!\nNew Stock: ${item.stock}",
                            ),
                          ),
                        ],
                      ),
                      backgroundColor: Colors.green,
                      duration: const Duration(milliseconds: 800),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  "UPDATE STOCK",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showImagePreview(String imagePath, String title) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close, color: Colors.white, size: 30),
                ),
              ],
            ),
            ClipRRect(
              borderRadius: BorderRadius.circular(30),
              child: Image.file(
                ImagePathHelper.getFile(imagePath),
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final inventoryProvider = context.watch<InventoryProvider>();
    
    // Filter items with stock < lowStockThreshold
    List<InventoryItem> lowStockItems = inventoryProvider.inventory.where((item) {
      return item.stock < item.lowStockThreshold;
    }).toList();

    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      lowStockItems = lowStockItems.where((item) {
        return item.name.toLowerCase().contains(query) ||
               item.barcode.toLowerCase().contains(query) ||
               item.category.toLowerCase().contains(query) ||
               item.subCategory.toLowerCase().contains(query) ||
               item.brand.toLowerCase().contains(query) ||
               item.color.toLowerCase().contains(query) ||
               item.size.toLowerCase().contains(query) ||
               item.itemType.toLowerCase().contains(query) ||
               item.unit.toLowerCase().contains(query);
      }).toList();
    }

    // Sort: OUT OF STOCK items first, then by stock ascending
    lowStockItems.sort((a, b) {
      if (a.stock <= 0 && b.stock > 0) return -1;
      if (a.stock > 0 && b.stock <= 0) return 1;
      return a.stock.compareTo(b.stock);
    });

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Low Stock Items",
          style: TextStyle(color: Colors.red, fontWeight: FontWeight.w900),
        ),
      ),
      body: lowStockItems.isEmpty && _searchQuery.isEmpty
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_circle_outline, size: 80, color: Colors.green),
                  SizedBox(height: 16),
                  Text(
                    "All stock is sufficient!",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.green),
                  ),
                ],
              ),
            )
          : Column(
              children: [
                // Search Bar
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: TextField(
                      controller: _searchController,
                      onChanged: (value) => setState(() => _searchQuery = value),
                      decoration: InputDecoration(
                        hintText: "Search by name, barcode, brand, color...",
                        hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
                        prefixIcon: Icon(Icons.search, color: Colors.grey[500]),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() => _searchQuery = '');
                                },
                                icon: Icon(Icons.close, color: Colors.grey[500]),
                              )
                            : null,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      ),
                    ),
                  ),
                ),
                // Results
                Expanded(
                  child: lowStockItems.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.search_off, size: 60, color: Colors.grey[400]),
                              const SizedBox(height: 16),
                              Text(
                                "No items found for '$_searchQuery'",
                                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: lowStockItems.length + 1, // +1 for header
                          itemBuilder: (context, index) {
                            if (index == 0) {
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.red[50],
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: const Color(0x4DF44336)),
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(Icons.info_outline, color: Colors.red, size: 20),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Text(
                                            "${lowStockItems.length} items need attention",
                                            style: const TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.red,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                ],
                              );
                            }
                            final item = lowStockItems[index - 1];
                            return _buildDetailedLowStockItem(item);
                          },
                        ),
                ),
              ],
            ),
    );
  }

  Widget _buildDetailedLowStockItem(item) {
    bool outOfStock = item.stock <= 0;
    
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: outOfStock ? Colors.red : const Color(0x80FF9800),
          width: outOfStock ? 2 : 1,
        ),
      ),
      child: InkWell(
        onTap: () => _showOrderSheet(item),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Left: Image
                  GestureDetector(
                    onTap: item.imagePath != null && ImagePathHelper.exists(item.imagePath!)
                        ? () => _showImagePreview(item.imagePath!, item.name)
                        : null,
                    child: Container(
                      width: 70,
                      height: 70,
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey[300]!, width: 1),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(11),
                        child: item.imagePath != null && ImagePathHelper.exists(item.imagePath!)
                            ? Image.file(
                                ImagePathHelper.getFile(item.imagePath!),
                                fit: BoxFit.cover,
                                width: 70,
                                height: 70,
                              )
                            : Icon(Icons.inventory_2_rounded, color: Colors.grey[400], size: 32),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  
                  // Middle: Product Details
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.name,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            const Text(
                              "Rs ",
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: AppColors.success,
                              ),
                            ),
                            Text(
                              item.price.toStringAsFixed(0),
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: AppColors.success,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        if (item.barcode != "N/A")
                          Row(
                            children: [
                              Icon(Icons.qr_code_2, size: 12, color: Colors.grey[500]),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  item.barcode,
                                  style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 4,
                          runSpacing: 4,
                          children: [
                            if (item.category != "General")
                              _buildTag(item.category, Colors.purple, Icons.category),
                            if (item.subCategory != "N/A")
                              _buildTag(item.subCategory, Colors.indigo, Icons.account_tree),
                            if (item.brand != "N/A")
                              _buildTag(item.brand, Colors.blue, Icons.verified),
                            if (item.color != "N/A")
                              _buildTag(item.color, Colors.pink, Icons.palette),
                            if (item.size != "N/A")
                              _buildTag(item.size, Colors.orange, Icons.straighten),
                            if (item.weight != "N/A")
                              _buildTag(item.weight, Colors.teal, Icons.scale),
                            if (item.itemType != "N/A")
                              _buildTag(item.itemType, Colors.cyan, Icons.style),
                            if (item.unit != "Piece")
                              _buildTag(item.unit, Colors.deepPurple, Icons.inventory),
                          ],
                        ),
                      ],
                    ),
                  ),
                  
                  // Right: Stock Badge with OUT OF STOCK overlay
                  Stack(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        decoration: BoxDecoration(
                          color: outOfStock 
                              ? const Color(0x1AFF0000) 
                              : const Color(0x1AFF9800),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              "${item.stock}",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: outOfStock ? Colors.red : Colors.orange,
                              ),
                            ),
                            Text(
                              "Stock",
                              style: TextStyle(
                                fontSize: 8,
                                fontWeight: FontWeight.bold,
                                color: outOfStock ? Colors.red : Colors.orange,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // OUT OF STOCK overlay
                      if (outOfStock)
                        Positioned.fill(
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.red,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Center(
                              child: Padding(
                                padding: EdgeInsets.all(4.0),
                                child: Text(
                                  "OUT\nOF\nSTOCK",
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 7,
                                    fontWeight: FontWeight.bold,
                                    height: 1.0,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // ORDER Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _showOrderSheet(item),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: outOfStock ? Colors.red : AppColors.accent,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: const Icon(Icons.add_shopping_cart, size: 18),
                  label: Text(
                    outOfStock ? "ORDER NOW (Urgent)" : "Add Stock",
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTag(String label, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 9, color: color),
          const SizedBox(width: 3),
          Text(
            label,
            style: TextStyle(
              fontSize: 9,
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
