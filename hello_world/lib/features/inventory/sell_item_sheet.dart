// lib/features/inventory/sell_item_sheet.dart
import 'package:flutter/material.dart';
import 'package:rsellx/providers/sales_provider.dart';
import 'package:provider/provider.dart';
import '../../data/models/inventory_model.dart';
import '../../data/models/sale_model.dart';
import '../../shared/utils/formatting.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';

class SellItemSheet extends StatefulWidget {
  final InventoryItem item;

  const SellItemSheet({super.key, required this.item});

  @override
  State<SellItemSheet> createState() => _SellItemSheetState();
}

class _SellItemSheetState extends State<SellItemSheet> {
  late TextEditingController _salePriceController;
  late TextEditingController _qtyController;
  double _profit = 0.0;
  int _sellQty = 1;

  @override
  void initState() {
    super.initState();
    _salePriceController = TextEditingController(text: "");
    _qtyController = TextEditingController(text: "1");
    _calculateProfit();
  }

  void _calculateProfit() {
    double salePrice = double.tryParse(_salePriceController.text) ?? 0.0;
    setState(() {
      _profit = (salePrice - widget.item.price) * _sellQty;
    });
  }

  void _addToCart() {
    if (_salePriceController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter Sale Price!"), backgroundColor: Colors.red),
      );
      return;
    }

    final double salePrice = double.tryParse(_salePriceController.text) ?? widget.item.price;
    
    if (widget.item.stock >= _sellQty) {
      final sale = SaleRecord(
        id: "sale_${DateTime.now().millisecondsSinceEpoch}",
        itemId: widget.item.id,
        name: widget.item.name,
        price: salePrice,
        actualPrice: widget.item.price,
        qty: _sellQty,
        profit: (salePrice - widget.item.price) * _sellQty,
        date: DateTime.now(),
        category: widget.item.category,
        size: widget.item.size,
      );

      context.read<SalesProvider>().addToCart(sale);
      Navigator.pop(context, "ADD_MORE");
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Insufficient stock for this quantity!")),
      );
    }
  }

  void _confirmSell() {
    if (_salePriceController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter Sale Price!"), backgroundColor: Colors.red),
      );
      return;
    }

    final double salePrice = double.tryParse(_salePriceController.text) ?? widget.item.price;
    
    if (widget.item.stock >= _sellQty) {
      final sale = SaleRecord(
        id: "sale_${DateTime.now().millisecondsSinceEpoch}",
        itemId: widget.item.id,
        name: widget.item.name,
        price: salePrice,
        actualPrice: widget.item.price,
        qty: _sellQty,
        profit: (salePrice - widget.item.price) * _sellQty,
        date: DateTime.now(),
        category: widget.item.category,
        size: widget.item.size,
      );

      context.read<SalesProvider>().addToCart(sale);
      Navigator.pop(context, "VIEW_CART");
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Insufficient stock for this quantity!")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.shopping_cart_checkout,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.item.name,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    "Stock Remaining: ${widget.item.stock}",
                    style: TextStyle(
                      color: widget.item.stock < widget.item.lowStockThreshold ? Colors.red : Colors.grey,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      if (widget.item.category != "General")
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(color: Colors.purple.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
                          child: Text(widget.item.category, style: const TextStyle(fontSize: 11, color: Colors.purple, fontWeight: FontWeight.bold)),
                        ),
                      if (widget.item.size != "N/A")
                        Container(
                           padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                           decoration: BoxDecoration(color: Colors.orange.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
                           child: Text("Size: ${widget.item.size}", style: const TextStyle(fontSize: 11, color: Colors.orange, fontWeight: FontWeight.bold)),
                        ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Cost Price (Purchase)",
                  style: TextStyle(
                    color: Colors.grey,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  "Rs ${Formatter.formatCurrency(widget.item.price)}",
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black54,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          
          // === QUANTITY SELECTOR ===
          const Text(
            "Select Quantity",
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              IconButton(
                onPressed: _sellQty > 1 ? () {
                  setState(() {
                    _sellQty--;
                    _qtyController.text = _sellQty.toString();
                  });
                  _calculateProfit();
                } : null,
                icon: const Icon(Icons.remove_circle_outline, size: 32, color: Colors.red),
              ),
              Container(
                width: 80,
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: TextField(
                  controller: _qtyController,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  onChanged: (val) {
                    int? newQty = int.tryParse(val);
                    if (newQty != null) {
                      if (newQty > widget.item.stock) {
                        newQty = widget.item.stock;
                        _qtyController.text = newQty.toString();
                      }
                      setState(() {
                        _sellQty = newQty!;
                      });
                      _calculateProfit();
                    }
                  },
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ),
              IconButton(
                onPressed: _sellQty < widget.item.stock ? () {
                  setState(() {
                    _sellQty++;
                    _qtyController.text = _sellQty.toString();
                  });
                  _calculateProfit();
                } : null,
                icon: const Icon(Icons.add_circle_outline, size: 32, color: Colors.green),
              ),
              const Spacer(),
              Text(
                "Max: ${widget.item.stock}",
                style: const TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 16),

          TextField(
            controller: _salePriceController,
            autofocus: true,
            keyboardType: TextInputType.number,
            onChanged: (val) => _calculateProfit(),
            style: AppTextStyles.h2,
            decoration: InputDecoration(
              labelText: "Sale Price (Per Item)",
              labelStyle: TextStyle(color: AppColors.accent),
              prefixText: "Rs ",
              filled: true,
              fillColor: AppColors.accent.withOpacity(0.05),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppColors.accent, width: 2),
              ),
            ),
          ),
          const SizedBox(height: 12),
          if (_profit != 0 && _salePriceController.text.isNotEmpty)
            Align(
              alignment: Alignment.centerRight,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: _profit > 0 ? Colors.green[50] : Colors.red[50],
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _profit > 0
                      ? "Profit: +Rs ${Formatter.formatCurrency(_profit)}"
                      : "Loss: -Rs ${Formatter.formatCurrency(_profit.abs())}",
                  style: TextStyle(
                    color: _profit > 0 ? Colors.green : Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 56,
                  child: OutlinedButton(
                    onPressed: widget.item.stock > 0 ? _addToCart : null,
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.secondary, width: 2),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text(
                      "ADD TO CART",
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.secondary),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: SizedBox(
                  height: 56,
                  child: ElevatedButton(
                    onPressed: widget.item.stock > 0 ? _confirmSell : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.secondary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      "CHECKOUT",
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
