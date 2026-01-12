import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rsellx/providers/sales_provider.dart';
import 'package:rsellx/providers/settings_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../shared/utils/formatting.dart';
import '../../core/services/reporting_service.dart';
import '../../data/models/sale_model.dart';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import '../../core/utils/image_path_helper.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  bool _shouldPrintInvoice = false;
  String _paperSize = "80mm";
  final _discountCtrl = TextEditingController();
  double _discount = 0.0;

  @override
  void initState() {
    super.initState();
    _discountCtrl.addListener(() {
      setState(() {
        _discount = double.tryParse(_discountCtrl.text) ?? 0.0;
      });
    });
  }
  
  @override
  void dispose() {
    _discountCtrl.dispose();
    super.dispose();
  }

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
                    ImagePathHelper.getFile(imagePath),
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
                  color: const Color(0xB3000000), // 0.7 opacity black
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

  void _showCustomQuantityDialog(SalesProvider salesProvider, int index, int currentQty, String itemName) {
    final TextEditingController qtyController = TextEditingController(text: currentQty.toString());
    final availableStock = salesProvider.getAvailableStock(index);
    final maxQty = currentQty + availableStock;
    
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Column(
          children: [
            const Icon(Icons.edit, color: AppColors.primary, size: 32),
            const SizedBox(height: 8),
            Text(
              "Set Quantity",
              style: AppTextStyles.h2,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              itemName,
              style: AppTextStyles.label.copyWith(fontSize: 12),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0x1A448AFF), // 0.1 opacity blue
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                "Available: $availableStock more (Max: $maxQty)",
                style: const TextStyle(fontSize: 12, color: Colors.blue, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: qtyController,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              autofocus: true,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              decoration: InputDecoration(
                hintText: "Enter quantity",
                filled: true,
                fillColor: Colors.grey[100],
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: AppColors.primary, width: 2),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Cancel", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.secondary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () {
              final newQty = int.tryParse(qtyController.text) ?? 0;
              if (newQty < 1) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Quantity must be at least 1"), backgroundColor: Colors.orange),
                );
                return;
              }
              if (newQty > maxQty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("Maximum available quantity is $maxQty"), backgroundColor: Colors.red),
                );
                return;
              }
              
              int delta = newQty - currentQty;
              if (delta != 0) {
                bool success = salesProvider.updateCartItemQty(index, delta);
                if (!success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Failed to update quantity"), backgroundColor: Colors.red),
                  );
                  return;
                }
              }
              Navigator.pop(ctx);
            },
            child: const Text("Update", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text("Sell Cart", style: AppTextStyles.h2),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Builder(
        builder: (context) {
          final salesProvider = context.watch<SalesProvider>();
          final settingsProvider = context.watch<SettingsProvider>();
          final cart = salesProvider.cart;
          
          if (cart.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                   Icon(Icons.shopping_cart_outlined, size: 80, color: Colors.grey[300]),
                   const SizedBox(height: 16),
                   Text("Your cart is empty", style: AppTextStyles.h3.copyWith(color: Colors.grey)),
                ],
              ),
            );
          }
          
          final subTotal = salesProvider.cartTotal;
          final finalTotal = subTotal - _discount;

          return Column(
            children: [
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: cart.length,
                  itemBuilder: (context, index) {
                    final item = cart[index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0x0A000000), // 0.04 opacity black
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          )
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            // Leading: Image
                            GestureDetector(
                              onTap: item.imagePath != null && ImagePathHelper.exists(item.imagePath!)
                                  ? () => _showImagePreview(item.imagePath!, item.name)
                                  : null,
                              child: Container(
                                width: 50,
                                height: 50,
                                decoration: BoxDecoration(
                                  color: Colors.grey[100],
                                  borderRadius: BorderRadius.circular(8),
                                  border: item.imagePath != null ? Border.all(color: Colors.grey[200]!) : null,
                                  image: item.imagePath != null && ImagePathHelper.exists(item.imagePath!)
                                      ? DecorationImage(
                                          image: ResizeImage(FileImage(ImagePathHelper.getFile(item.imagePath!)), width: 100),
                                          fit: BoxFit.cover,
                                        )
                                      : null,
                                ),
                                child: item.imagePath == null || !ImagePathHelper.exists(item.imagePath!)
                                    ? const Icon(Icons.image_not_supported_outlined, color: Colors.grey, size: 24)
                                    : null,
                              ),
                            ),
                            const SizedBox(width: 12),
                            // Middle: Item Details
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(item.name, style: AppTextStyles.h3, maxLines: 1, overflow: TextOverflow.ellipsis),
                                  const SizedBox(height: 4),
                                  Text(
                                    "Rs ${Formatter.formatCurrency(item.price)} each",
                                    style: AppTextStyles.label.copyWith(fontSize: 12),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    "Total: Rs ${Formatter.formatCurrency(item.price * item.qty)}",
                                    style: AppTextStyles.h3.copyWith(color: AppColors.primary, fontSize: 14),
                                  ),
                                  const SizedBox(height: 4),
                                  Wrap(
                                    spacing: 6,
                                    runSpacing: 4,
                                    children: [
                                      if (item.category != "General")
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(color: Colors.purple.withOpacity(0.1), borderRadius: BorderRadius.circular(4)),
                                          child: Text(item.category, style: const TextStyle(fontSize: 9, color: Colors.purple, fontWeight: FontWeight.bold)),
                                        ),
                                      if (item.size != "N/A")
                                        Container(
                                           padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                           decoration: BoxDecoration(color: Colors.orange.withOpacity(0.1), borderRadius: BorderRadius.circular(4)),
                                           child: Text("Size: ${item.size}", style: const TextStyle(fontSize: 9, color: Colors.orange, fontWeight: FontWeight.bold)),
                                        ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            // Right: Quantity Controls + Delete
                            Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // Quantity Controls Row
                                Container(
                                  decoration: BoxDecoration(
                                    color: Colors.grey[100],
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: Colors.grey[300]!),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      // Decrement Button
                                      InkWell(
                                        onTap: item.qty > 1 ? () {
                                          bool success = salesProvider.updateCartItemQty(index, -1);
                                          if (!success) {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              const SnackBar(content: Text("Cannot decrease quantity below 1"), backgroundColor: Colors.orange),
                                            );
                                          }
                                        } : null,
                                        borderRadius: const BorderRadius.horizontal(left: Radius.circular(12)),
                                        child: Container(
                                          padding: const EdgeInsets.all(8),
                                          child: Icon(
                                            Icons.remove,
                                            size: 18,
                                            color: item.qty > 1 ? Colors.red : Colors.grey,
                                          ),
                                        ),
                                      ),
                                      // Quantity Display - Tap to enter custom number
                                      GestureDetector(
                                        onTap: () => _showCustomQuantityDialog(salesProvider, index, item.qty, item.name),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            border: Border.symmetric(vertical: BorderSide(color: Colors.grey[300]!)),
                                          ),
                                          child: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Text(
                                                "${item.qty}",
                                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                              ),
                                              const Text(
                                                "tap",
                                                style: TextStyle(fontSize: 8, color: Colors.grey),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                      // Increment Button
                                      InkWell(
                                        onTap: () {
                                          bool success = salesProvider.updateCartItemQty(index, 1);
                                          if (!success) {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              const SnackBar(content: Text("Not enough stock available!"), backgroundColor: Colors.red),
                                            );
                                          }
                                        },
                                        borderRadius: const BorderRadius.horizontal(right: Radius.circular(12)),
                                        child: Container(
                                          padding: const EdgeInsets.all(8),
                                          child: const Icon(
                                            Icons.add,
                                            size: 18,
                                            color: Colors.green,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 8),
                                // Delete Button
                                InkWell(
                                  onTap: () => salesProvider.removeFromCart(index),
                                  borderRadius: BorderRadius.circular(8),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: Colors.red.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.delete_outline, color: Colors.red, size: 16),
                                        SizedBox(width: 4),
                                        Text("Remove", style: TextStyle(color: Colors.red, fontSize: 11, fontWeight: FontWeight.bold)),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              
              // Bottom Checkout Panel
              Container(
                padding: const EdgeInsets.all(24),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
                  boxShadow: [
                    BoxShadow(color: Colors.black12, blurRadius: 20, offset: Offset(0, -10))
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Subtotal
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text("Subtotal", style: AppTextStyles.label),
                        Text("${salesProvider.cartCount} items | Rs ${Formatter.formatCurrency(subTotal)}", style: AppTextStyles.bodyMedium),
                      ],
                    ),
                    const SizedBox(height: 12),
                    
                    // Discount Input
                    Row(
                      children: [
                        const Icon(Icons.local_offer_outlined, color: Colors.orange, size: 20),
                        const SizedBox(width: 8),
                        Text("Discount (Rs)", style: AppTextStyles.h3),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextField(
                            controller: _discountCtrl,
                            keyboardType: TextInputType.number,
                            textAlign: TextAlign.end,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                            decoration: InputDecoration(
                              hintText: "0",
                              filled: true,
                              fillColor: Colors.grey[50],
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                            ),
                          ),
                        ),
                      ],
                    ),
                    
                    const Divider(height: 30),
                    
                    // Final Total
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text("TOTAL PAYABLE", style: AppTextStyles.h3),
                        Text(
                          "Rs ${Formatter.formatCurrency(finalTotal)}",
                          style: AppTextStyles.h1.copyWith(color: AppColors.secondary, fontSize: 26),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    
                    // INVOICE TOGGLE
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.receipt_long, color: AppColors.primary, size: 20),
                                  const SizedBox(width: 10),
                                  Text("Generate Invoice", style: AppTextStyles.bodyMedium),
                                ],
                              ),
                              Switch(
                                value: _shouldPrintInvoice,
                                activeColor: AppColors.secondary,
                                onChanged: (val) => setState(() => _shouldPrintInvoice = val),
                              ),
                            ],
                          ),
                          if (_shouldPrintInvoice)
                            Row(
                               mainAxisAlignment: MainAxisAlignment.spaceBetween,
                               children: [
                                 const Text("Paper Size:", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                 DropdownButton<String>(
                                   value: _paperSize,
                                   items: ["80mm", "58mm"].map((String value) {
                                     return DropdownMenuItem<String>(
                                       value: value,
                                       child: Text(value, style: const TextStyle(fontSize: 12)),
                                     );
                                   }).toList(),
                                   onChanged: (val) {
                                     if (val != null) setState(() => _paperSize = val);
                                   },
                                 ),
                               ],
                            ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                    // CHECKOUT BUTTON
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.secondary,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          elevation: 2,
                        ),
                        onPressed: () async {
                          try {
                            final cartItems = List<SaleRecord>.from(salesProvider.cart);
                            final billId = "BILL-${DateTime.now().millisecondsSinceEpoch}";
                            
                            // Pass discount to checkout logic
                            await salesProvider.checkoutCart(discount: _discount);
                            
                            if (context.mounted) {
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text("Sale completed successfully! ✅"),
                                  backgroundColor: AppColors.success,
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );

                              if (_shouldPrintInvoice) {
                                try {
                                  await ReportingService.generateInvoice(
                                    shopName: settingsProvider.shopName,
                                    address: settingsProvider.address,
                                    items: cartItems,
                                    billId: billId,
                                    discount: _discount,
                                    paperFormat: _paperSize == "80mm" ? PdfPageFormat.roll80 : PdfPageFormat.roll57,
                                  );
                                } catch (e) {
                                  // Invoice generation failed but sale is complete
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text("Sale complete but invoice generation failed: $e"),
                                        backgroundColor: Colors.orange,
                                        duration: const Duration(seconds: 5),
                                      ),
                                    );
                                  }
                                }
                              }
                            }
                          } catch (e) {
                            // Checkout failed - cart should still be intact
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text("Checkout failed: $e\nPlease try again."),
                                  backgroundColor: Colors.red,
                                  duration: const Duration(seconds: 5),
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            }
                          }
                        },
                        child: const Text(
                          "CONFIRM SALE",
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
