import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:rsellx/core/utils/fuzzy_search.dart';
import 'package:rsellx/data/models/inventory_model.dart';
import 'package:rsellx/data/models/sale_model.dart';
import 'package:rsellx/providers/sales_provider.dart';
import 'package:rsellx/providers/inventory_provider.dart';
import 'package:rsellx/features/inventory/sell_item_sheet.dart';
import 'package:provider/provider.dart';
import '../../features/cart/cart_screen.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/image_path_helper.dart';

/// RESULT WRAPPER FOR MULTIPLE ACTIONS
class SearchActionResult {
  final InventoryItem item;
  final String action; // 'ADD' or 'SELL'
  SearchActionResult(this.item, this.action);
}

/// SUPER SMART & FAST SEARCH COMMAND CENTER
Future<SearchActionResult?> showSmartSearchInput(
  BuildContext context, {
  required List<InventoryItem> inventory, // Keep for initial call compatibility
}) async {
  final TextEditingController controller = TextEditingController();

  return await showModalBottomSheet<SearchActionResult>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    isDismissible: true,
    enableDrag: true,
    builder: (context) {
      // Use Consumer to get live inventory updates
      return Consumer<InventoryProvider>(
        builder: (context, inventoryProvider, child) {
          final liveInventory = inventoryProvider.inventory; // Live data
          
          return StatefulBuilder(
            builder: (context, setModalState) {
              final query = controller.text.toLowerCase().trim();
              
              // --- HYPER-SMART SEARCH ENGINE ---
              List<InventoryItem> results = [];
              
              if (query.isNotEmpty) {
                final scored = liveInventory.map((item) {
              int score = 0;
              final name = item.name.toLowerCase();
              final barcode = item.barcode.toLowerCase();
              final category = item.category.toLowerCase();
              final subCategory = item.subCategory.toLowerCase();
              final size = item.size.toLowerCase();
              final weight = item.weight.toLowerCase();

              // 1. EXACT MATCHES (Top Priority)
              if (name == query || barcode == query) score += 100;
              else if (category == query || subCategory == query) score += 80;

              // 2. STARTS WITH (High Priority)
              else if (name.startsWith(query) || barcode.startsWith(query)) score += 60;
              else if (category.startsWith(query) || subCategory.startsWith(query)) score += 50;
              
              // 3. CONTAINS MATCHES (Medium Priority)
              else if (name.contains(query)) score += 40;
              else if (barcode.contains(query)) score += 35;
              else if (category.contains(query) || subCategory.contains(query)) score += 30;
              else if (size.contains(query) || weight.contains(query)) score += 20;
              
              // 4. FUZZY SEARCH (Typo Tolerance)
              if (query.length >= 3 && score < 40) {
                double nameSim = FuzzySearch.similarity(name, query);
                double catSim = FuzzySearch.similarity(category, query);
                double maxSim = nameSim > catSim ? nameSim : catSim;
                
                if (maxSim > 0.6) {
                  score += (maxSim * 45).toInt();
                }
              }

              return _ScoredItem(item, score);
            }).where((si) => si.score > 0).toList();

            scored.sort((a, b) => b.score.compareTo(a.score));
            results = scored.map((si) => si.item).toList();
          }

          return Container(
            height: MediaQuery.of(context).size.height * 0.85,
            padding: const EdgeInsets.only(top: 16),
            decoration: const BoxDecoration(
              color: Color(0xFFF8F9FA),
              borderRadius: BorderRadius.vertical(top: Radius.circular(35)),
            ),
            child: Column(
              children: [
                // Handle
                Container(
                  width: 40,
                  height: 5,
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10)),
                ),
                
                // Search Box
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                  child: TextField(
                    controller: controller,
                    autofocus: true,
                    onChanged: (val) => setModalState(() {}),
                    decoration: InputDecoration(
                      hintText: 'Search Name, Category, Barcode...',
                      prefixIcon: const Icon(Icons.search, color: AppColors.accent),
                      suffixIcon: query.isNotEmpty 
                        ? IconButton(icon: const Icon(Icons.close), onPressed: () { controller.clear(); setModalState(() {}); })
                        : null,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(25),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(vertical: 15),
                    ),
                  ),
                ),

                // Results Counter
                if (query.isNotEmpty)...[
                   Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 30),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "FOUND ${results.length} MATCHES",
                          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.grey, letterSpacing: 1.5),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.blue.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Row(
                            children: [
                               Icon(Icons.swipe_right_rounded, color: Colors.blue, size: 10),
                               SizedBox(width: 4),
                               Text("SWIPE TO ADD", style: TextStyle(color: Colors.blue, fontSize: 8, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                ],

                // Unified Results List
                Expanded(
                  child: query.isEmpty
                    ? _buildInitialState()
                    : results.isEmpty 
                      ? _buildEmptyState(query)
                      : ListView.builder(
                          itemCount: results.length,
                          physics: const BouncingScrollPhysics(),
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemBuilder: (context, index) {
                            final item = results[index];
                            final isBestMatch = index == 0;
                            return _buildSearchItem(context, item, isBestMatch, setModalState);
                          },
                        ),
                ),
              ],
            ),
          );
        },
      );
        },
      );
    },
  );
}

Widget _buildInitialState() {
  return Column(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      Icon(Icons.manage_search_rounded, size: 80, color: Colors.blue.withOpacity(0.1)),
      const SizedBox(height: 16),
      const Text("Hyper-Smart Search", style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 18)),
      const SizedBox(height: 8),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Text(
          "Find products by Name, Barcode, Category, Sub-category, or even Size/Weight!",
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.grey[500], fontSize: 13),
        ),
      ),
      const SizedBox(height: 20),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.amber.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.lightbulb_outline, color: Colors.amber, size: 16),
            SizedBox(width: 8),
            Text("Tip: Swipe right on a product to Cart", style: TextStyle(color: Colors.amber, fontWeight: FontWeight.bold, fontSize: 11)),
          ],
        ),
      ),
    ],
  );
}

Widget _buildSearchItem(BuildContext context, InventoryItem item, bool isBestMatch, StateSetter setModalState) {
  bool lowStock = item.stock < item.lowStockThreshold;

  return Dismissible(
    key: Key("search_item_${item.id}_${DateTime.now().millisecondsSinceEpoch}"),
    direction: DismissDirection.startToEnd,
    background: Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.blue,
        borderRadius: BorderRadius.circular(20),
      ),
      alignment: Alignment.centerLeft,
      padding: const EdgeInsets.only(left: 25),
      child: const Row(
        children: [
          Icon(Icons.add_shopping_cart_rounded, color: Colors.white, size: 28),
          SizedBox(width: 15),
          Text("QUICK ADD", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 1)),
        ],
      ),
    ),
    confirmDismiss: (direction) async {
      // Quick add without closing modal
      _quickAddToCart(context, item, setModalState);
      return false; // Don't dismiss the card
    },
    child: Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: isBestMatch ? AppColors.accent.withOpacity(0.3) : Colors.transparent, width: 2),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Left: Image + SELL Button
            Column(
              children: [
                GestureDetector(
                  onTap: () {
                    if (item.imagePath != null && ImagePathHelper.exists(item.imagePath!)) {
                      _showImagePreview(context, item.imagePath!, item.name);
                    }
                  },
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      width: 55,
                      height: 55,
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        border: Border.all(color: Colors.grey[200]!),
                      ),
                      child: item.imagePath != null && ImagePathHelper.exists(item.imagePath!)
                        ? Image.file(ImagePathHelper.getFile(item.imagePath!), fit: BoxFit.cover)
                        : const Icon(Icons.inventory_2_rounded, color: Colors.grey, size: 24),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: () async {
                    // Play beep sound
                    final audioPlayer = AudioPlayer();
                    audioPlayer.play(AssetSource('scanner_beep.mp3'));
                    
                    // Open sell sheet WITHOUT closing search modal
                    final result = await showModalBottomSheet<String>(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.white,
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
                      ),
                      builder: (context) => SellItemSheet(item: item),
                    );

                    if (result == "VIEW_CART") {
                      if (context.mounted) {
                        Navigator.pop(context); // Close search modal
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
                    }
                  },
                  child: Container(
                    width: 55,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.success,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Column(
                      children: [
                        Icon(Icons.shopping_cart_checkout, color: Colors.white, size: 14),
                        Text("SELL", style: TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 15),
            
            // Middle: Product Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          item.name,
                          style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (isBestMatch)
                         const Icon(Icons.stars_rounded, color: Colors.amber, size: 16),
                    ],
                  ),
                  const SizedBox(height: 5),
                  Text(
                    "Rs ${item.price.toStringAsFixed(0)}",
                    style: const TextStyle(color: AppColors.success, fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  const SizedBox(height: 4),
                  if (item.barcode != "N/A")
                    Row(
                      children: [
                        Icon(Icons.qr_code_2, size: 12, color: Colors.grey[400]),
                        const SizedBox(width: 4),
                        Text(item.barcode, style: TextStyle(fontSize: 10, color: Colors.grey[500])),
                      ],
                    ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 4,
                    runSpacing: 4,
                    children: [
                      if (item.category != "General") _Tag(label: item.category, color: Colors.purple, icon: Icons.category),
                      if (item.subCategory != "N/A") _Tag(label: item.subCategory, color: Colors.indigo, icon: Icons.account_tree),
                      if (item.size != "N/A") _Tag(label: item.size, color: Colors.orange, icon: Icons.straighten),
                      if (item.weight != "N/A") _Tag(label: item.weight, color: Colors.teal, icon: Icons.scale),
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
                    color: lowStock ? Colors.red.withOpacity(0.08) : Colors.green.withOpacity(0.08),
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
                          color: lowStock ? Colors.red : Colors.green,
                        ),
                      ),
                      Text(
                        "Stock",
                        style: TextStyle(
                          fontSize: 8,
                          fontWeight: FontWeight.bold,
                          color: lowStock ? Colors.red : Colors.green,
                        ),
                      ),
                    ],
                  ),
                ),
                // OUT OF STOCK overlay when stock is 0
                if (item.stock <= 0)
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
                            "OUT OF\nSTOCK",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 8,
                              fontWeight: FontWeight.bold,
                              height: 1.1,
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
      ),
    ),
  );
}

void _quickAddToCart(BuildContext context, InventoryItem item, StateSetter setModalState) {
  // Check stock availability
  if (item.stock <= 0) {
    HapticFeedback.heavyImpact();
    
    // Play error sound
    final audioPlayer = AudioPlayer();
    audioPlayer.play(AssetSource('scanner_beep.mp3'));
    
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text("${item.name} is out of stock!")),
          ],
        ),
        duration: const Duration(milliseconds: 600),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.only(bottom: 20, left: 20, right: 20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
    return;
  }

  // Create sale record
  final record = SaleRecord(
    id: "sale_${DateTime.now().millisecondsSinceEpoch}",
    itemId: item.id,
    name: item.name,
    price: item.price,
    actualPrice: item.price,
    qty: 1,
    profit: 0.0,
    date: DateTime.now(),
    status: "Cart",
    category: item.category,
    subCategory: item.subCategory,
    size: item.size,
    weight: item.weight,
    imagePath: item.imagePath,
  );

  // Add to cart
  context.read<SalesProvider>().addToCart(record);
  
  // Play success beep
  final audioPlayer = AudioPlayer();
  audioPlayer.play(AssetSource('scanner_beep.mp3'));
  
  HapticFeedback.lightImpact();
  ScaffoldMessenger.of(context).clearSnackBars();
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Row(
        children: [
          const Icon(Icons.check_circle, color: Colors.white),
          const SizedBox(width: 12),
          Expanded(child: Text("${item.name} added to cart!")),
        ],
      ),
      backgroundColor: Colors.green,
      duration: const Duration(milliseconds: 400),
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.only(bottom: 20, left: 20, right: 20),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ),
  );
}

class _Tag extends StatelessWidget {
  final String label;
  final Color color;
  final IconData icon;

  const _Tag({required this.label, required this.color, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.1)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 9, color: color),
          const SizedBox(width: 3),
          Text(label, style: TextStyle(fontSize: 9, color: color, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

void _showImagePreview(BuildContext context, String imagePath, String title) {
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
          Flexible(
            child: InteractiveViewer(
              minScale: 0.5,
              maxScale: 4.0,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(30),
                child: Image.file(
                  ImagePathHelper.getFile(imagePath),
                  fit: BoxFit.contain,
                ),
              ),
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

Widget _buildEmptyState(String query) {
  return Column(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      Icon(Icons.search_off_rounded, size: 60, color: Colors.grey[300]),
      const SizedBox(height: 16),
      Text("No matches for \"$query\"", style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
    ],
  );
}

class _ScoredItem {
  final InventoryItem item;
  final int score;
  _ScoredItem(this.item, this.score);
}
