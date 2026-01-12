// lib/features/inventory/sell_item_sheet.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:rsellx/providers/sales_provider.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:provider/provider.dart';
import '../../data/models/inventory_model.dart';
import '../../data/models/sale_model.dart';
import '../../shared/utils/formatting.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/image_path_helper.dart';

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
  final AudioPlayer _audioPlayer = AudioPlayer();

  @override
  void initState() {
    super.initState();
    _salePriceController = TextEditingController(text: "");
    _qtyController = TextEditingController(text: "1");
    _audioPlayer.setSource(AssetSource('scanner_beep.mp3'));
    _calculateProfit();
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    _qtyController.dispose();
    _salePriceController.dispose();
    super.dispose();
  }

  void _calculateProfit() {
    double salePrice = double.tryParse(_salePriceController.text) ?? 0.0;
    setState(() {
      _profit = (salePrice - widget.item.price) * _sellQty;
    });
  }

  void _addToCart() {
    if (_salePriceController.text.isEmpty) {
      HapticFeedback.mediumImpact();
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please enter Sale Price!"), 
          backgroundColor: Colors.red,
          duration: Duration(milliseconds: 600),
          behavior: SnackBarBehavior.floating,
        ),
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
        status: "Cart", // Cart status until checkout
        category: widget.item.category,
        subCategory: widget.item.subCategory,
        size: widget.item.size,
        weight: widget.item.weight,
        imagePath: widget.item.imagePath,
      );

      context.read<SalesProvider>().addToCart(sale);
      _audioPlayer.stop().then((_) => _audioPlayer.play(AssetSource('scanner_beep.mp3')));
      Navigator.pop(context, "ADD_MORE");
    } else {
      HapticFeedback.heavyImpact();
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Insufficient stock!"),
          backgroundColor: Colors.orange,
          duration: Duration(milliseconds: 600),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _confirmSell() {
    HapticFeedback.mediumImpact();
    if (_salePriceController.text.isEmpty) {
      HapticFeedback.mediumImpact();
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please enter Sale Price!"), 
          backgroundColor: Colors.red,
          duration: Duration(milliseconds: 600),
          behavior: SnackBarBehavior.floating,
        ),
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
        status: "Cart", // Cart status until checkout
        category: widget.item.category,
        subCategory: widget.item.subCategory,
        size: widget.item.size,
        weight: widget.item.weight,
        imagePath: widget.item.imagePath,
      );

      context.read<SalesProvider>().addToCart(sale);
      _audioPlayer.stop().then((_) => _audioPlayer.play(AssetSource('scanner_beep.mp3')));
      Navigator.pop(context, "VIEW_CART");
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Insufficient stock for this quantity!")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Container(
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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
              // Product Image / Icon
              GestureDetector(
                onTap: () {
                   if (widget.item.imagePath != null && ImagePathHelper.exists(widget.item.imagePath!)) {
                     showDialog(
                       context: context,
                       builder: (context) => Dialog(
                         backgroundColor: Colors.transparent,
                         insetPadding: const EdgeInsets.all(10),
                         child: Stack(
                           alignment: Alignment.center,
                           children: [
                             InteractiveViewer(
                               minScale: 0.5,
                               maxScale: 4.0,
                               child: ClipRRect(
                                 borderRadius: BorderRadius.circular(16),
                                 child: Image.file(
                                   ImagePathHelper.getFile(widget.item.imagePath!),
                                   fit: BoxFit.contain,
                                 ),
                               ),
                             ),
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
                },
                child: Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: widget.item.imagePath == null 
                        ? const Color(0x1A000000)
                        : null,
                    borderRadius: BorderRadius.circular(12),
                    border: widget.item.imagePath != null 
                        ? Border.all(color: Colors.grey[300]!, width: 1)
                        : null,
                    image: widget.item.imagePath != null && ImagePathHelper.exists(widget.item.imagePath!)
                        ? DecorationImage(
                            image: FileImage(ImagePathHelper.getFile(widget.item.imagePath!)),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: widget.item.imagePath == null || !ImagePathHelper.exists(widget.item.imagePath!)
                      ? const Icon(
                          Icons.shopping_cart_checkout,
                          color: AppColors.primary,
                          size: 28,
                        )
                      : null,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.item.name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Row(
                      children: [
                        Text(
                          "Stock: ${widget.item.stock}",
                          style: TextStyle(
                            fontSize: 13,
                            color: widget.item.stock < widget.item.lowStockThreshold ? Colors.red : Colors.grey[600],
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Icon(Icons.qr_code, size: 14, color: Colors.grey[500]),
                        const SizedBox(width: 4),
                        Text(
                          widget.item.barcode,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[500],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        if (widget.item.category != "General")
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                            decoration: BoxDecoration(color: const Color(0x1A9C27B0), borderRadius: BorderRadius.circular(4)),
                            child: Text(widget.item.category, style: const TextStyle(fontSize: 10, color: Colors.purple, fontWeight: FontWeight.bold)),
                          ),
                        if (widget.item.subCategory != "N/A")
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                            decoration: BoxDecoration(color: const Color(0x1A3F51B5), borderRadius: BorderRadius.circular(4)),
                            child: Text(widget.item.subCategory, style: const TextStyle(fontSize: 10, color: Colors.indigo, fontWeight: FontWeight.bold)),
                          ),
                        if (widget.item.size != "N/A")
                          Container(
                             padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                             decoration: BoxDecoration(color: const Color(0x1AFF9800), borderRadius: BorderRadius.circular(4)),
                             child: Text(widget.item.size, style: const TextStyle(fontSize: 10, color: Colors.orange, fontWeight: FontWeight.bold)),
                          ),
                        if (widget.item.weight != "N/A")
                          Container(
                             padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                             decoration: BoxDecoration(color: const Color(0x1A009688), borderRadius: BorderRadius.circular(4)),
                             child: Text(widget.item.weight, style: const TextStyle(fontSize: 10, color: Colors.teal, fontWeight: FontWeight.bold)),
                          ),
                      ],
                    ),
                  ],
                ),
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
              fillColor: const Color(0x0D448AFF),
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
    ),
  );
}
}
