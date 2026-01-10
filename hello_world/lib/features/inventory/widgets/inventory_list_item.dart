import 'dart:io';
import 'package:flutter/material.dart';
import 'package:rsellx/data/models/inventory_model.dart';
import '../../../core/theme/app_colors.dart';

class InventoryListItem extends StatelessWidget {
  final InventoryItem item;
  final VoidCallback onTap;
  final VoidCallback onSell;
  final Function(String, String) onImageTap;
  final Function(String, IconData)? onTagTap;

  const InventoryListItem({
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
      elevation: 1,
      shadowColor: Colors.black.withOpacity(0.05),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14), 
        side: BorderSide(color: lowStock ? AppColors.error.withOpacity(0.3) : Colors.grey[200]!)
      ),
      margin: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Left: Image + SELL Button
              Column(
                children: [
                  GestureDetector(
                    onTap: item.imagePath != null && File(item.imagePath!).existsSync()
                        ? () => onImageTap(item.imagePath!, item.name)
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
                                cacheWidth: 120,
                              )
                            : Icon(Icons.inventory_2_rounded, color: Colors.grey[400], size: 26),
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  GestureDetector(
                    onTap: onSell,
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
                    Text(
                      item.name, 
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black87),
                      maxLines: 1, 
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
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
                    Wrap(
                      spacing: 4,
                      runSpacing: 4,
                      children: [
                        if (item.category != "General") _Tag(label: item.category, color: Colors.purple, icon: Icons.category, onTap: onTagTap == null ? null : () => onTagTap!(item.category, Icons.category)),
                        if (item.subCategory != "N/A") _Tag(label: item.subCategory, color: Colors.indigo, icon: Icons.account_tree, onTap: onTagTap == null ? null : () => onTagTap!(item.subCategory, Icons.account_tree)),
                        if (item.size != "N/A") _Tag(label: item.size, color: Colors.orange, icon: Icons.straighten),
                        if (item.weight != "N/A") _Tag(label: item.weight, color: Colors.teal, icon: Icons.scale),
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
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: color.withOpacity(0.12), 
          borderRadius: BorderRadius.circular(6), 
          border: Border.all(color: color.withOpacity(0.2))
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 10, color: color),
            const SizedBox(width: 4),
            Text(label, style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.w600)),
            if (onTap != null) ...[const SizedBox(width: 4), Icon(Icons.filter_list, size: 10, color: color)],
          ],
        ),
      ),
    );
  }
}
