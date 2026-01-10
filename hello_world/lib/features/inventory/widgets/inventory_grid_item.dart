import 'dart:io';
import 'package:flutter/material.dart';
import 'package:rsellx/data/models/inventory_model.dart';
import '../../../core/theme/app_colors.dart';

class InventoryGridItem extends StatelessWidget {
  final InventoryItem item;
  final VoidCallback onTap;
  final VoidCallback onSell;
  final Function(String, String) onImageTap;
  final Function(String, IconData)? onTagTap;

  const InventoryGridItem({
    super.key,
    required this.item,
    required this.onTap,
    required this.onSell,
    required this.onImageTap,
    this.onTagTap,
  });

  @override
  Widget build(BuildContext context) {
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
          Expanded(
            flex: 3,
            child: Stack(
              children: [
                GestureDetector(
                  onTap: item.imagePath != null && File(item.imagePath!).existsSync()
                      ? () => onImageTap(item.imagePath!, item.name)
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
                            cacheWidth: 300,
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
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: InkWell(
                    onTap: onSell,
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
          
          InkWell(
            onTap: onTap,
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: const BoxDecoration(color: Colors.white),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
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
                  Wrap(
                    spacing: 4,
                    runSpacing: 4,
                    children: [
                      _Tag(label: item.category, color: Colors.purple, icon: Icons.category, onTap: onTagTap == null ? null : () => onTagTap!(item.category, Icons.category)),
                      if (item.subCategory != "N/A")
                        _Tag(label: item.subCategory, color: Colors.indigo, icon: Icons.account_tree, onTap: onTagTap == null ? null : () => onTagTap!(item.subCategory, Icons.account_tree)),
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
}

class _Tag extends StatelessWidget {
  final String label;
  final Color color;
  final IconData icon;
  final VoidCallback? onTap;

  const _Tag({required this.label, required this.color, required this.icon, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1), 
          borderRadius: BorderRadius.circular(4),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 10, color: color),
            const SizedBox(width: 3),
            Text(label, style: TextStyle(fontSize: 9, color: color, fontWeight: FontWeight.w600)),
            if (onTap != null) ...[const SizedBox(width: 3), Icon(Icons.filter_list, size: 9, color: color)],
          ],
        ),
      ),
    );
  }
}
