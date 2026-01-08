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
                            color: Colors.black.withOpacity(0.04),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          )
                        ],
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(16),
                        title: Text(item.name, style: AppTextStyles.h3),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Rs ${Formatter.formatCurrency(item.price)} x ${item.qty}",
                              style: AppTextStyles.label,
                            ),
                            const SizedBox(height: 4),
                            Wrap(
                              spacing: 8,
                              runSpacing: 4,
                              children: [
                                if (item.category != "General")
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(color: Colors.purple.withOpacity(0.1), borderRadius: BorderRadius.circular(4)),
                                    child: Text(item.category, style: const TextStyle(fontSize: 10, color: Colors.purple, fontWeight: FontWeight.bold)),
                                  ),
                                if (item.size != "N/A")
                                  Container(
                                     padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                     decoration: BoxDecoration(color: Colors.orange.withOpacity(0.1), borderRadius: BorderRadius.circular(4)),
                                     child: Text("Size: ${item.size}", style: const TextStyle(fontSize: 10, color: Colors.orange, fontWeight: FontWeight.bold)),
                                  ),
                              ],
                            ),
                          ],
                        ),
                        trailing: Row(
                           mainAxisSize: MainAxisSize.min,
                           children: [
                             Text(
                               "Rs ${Formatter.formatCurrency(item.price * item.qty)}",
                               style: AppTextStyles.h3.copyWith(color: AppColors.primary),
                             ),
                             const SizedBox(width: 8),
                             IconButton(
                               icon: const Icon(Icons.delete_outline, color: Colors.red),
                               onPressed: () => salesProvider.removeFromCart(index),
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
                              ReportingService.generateInvoice(
                                shopName: settingsProvider.shopName,
                                address: settingsProvider.address,
                                items: cartItems,
                                billId: billId,
                                discount: _discount,
                                paperFormat: _paperSize == "80mm" ? PdfPageFormat.roll80 : PdfPageFormat.roll57,
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
