import 'package:flutter/material.dart';
import '../../data/repositories/data_store.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../shared/utils/formatting.dart';
import '../../core/services/reporting_service.dart';
import '../../data/models/sale_model.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  bool _shouldPrintInvoice = false;

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
      body: ListenableBuilder(
        listenable: DataStore(),
        builder: (context, _) {
          final cart = DataStore().cart;
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
                        subtitle: Text(
                          "Rs ${Formatter.formatCurrency(item.price)} x ${item.qty}",
                          style: AppTextStyles.label,
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
                              onPressed: () => DataStore().removeFromCart(index),
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
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text("Total Items", style: AppTextStyles.label),
                        Text("${DataStore().cartCount}", style: AppTextStyles.h3),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text("Total Amount", style: AppTextStyles.h3),
                        Text(
                          "Rs ${Formatter.formatCurrency(DataStore().cartTotal)}",
                          style: AppTextStyles.h1.copyWith(color: AppColors.secondary, fontSize: 24),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    
                    // TOGGLE FOR INVOICE
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
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
                    ),
                    
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.secondary,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          elevation: 0,
                        ),
                        onPressed: () async {
                          final store = DataStore();
                          final cartItems = List<SaleRecord>.from(store.cart);
                          final billId = "BILL-${DateTime.now().millisecondsSinceEpoch}";
                          
                          await store.checkoutCart();
                          
                          if (context.mounted) {
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text("Sale completed successfully! ✅"),
                                backgroundColor: AppColors.success,
                                behavior: SnackBarBehavior.floating,
                              ),
                            );

                            // Only generate if toggle is ON
                            if (_shouldPrintInvoice) {
                              ReportingService.generateInvoice(
                                shopName: store.shopName,
                                address: store.address,
                                items: cartItems,
                                billId: billId,
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
