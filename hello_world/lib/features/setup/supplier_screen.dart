import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/supplier_provider.dart';
import '../../providers/inventory_provider.dart';
import '../../data/models/supplier_model.dart';
import '../../core/theme/app_colors.dart';
import '../../shared/utils/formatting.dart';

class SupplierScreen extends StatelessWidget {
  const SupplierScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<SupplierProvider>();
    final suppliers = provider.allSuppliers;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text("Suppliers & Purchases", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: suppliers.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.local_shipping_outlined, size: 80, color: Colors.grey[300]),
                  const SizedBox(height: 16),
                  const Text("No suppliers added yet", style: TextStyle(color: Colors.grey)),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => _showAddSupplierDialog(context),
                    child: const Text("Add First Supplier"),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: suppliers.length,
              itemBuilder: (context, index) {
                final s = suppliers[index];
                return _buildSupplierCard(context, s);
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddSupplierDialog(context),
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.person_add, color: Colors.white),
      ),
    );
  }

  Widget _buildSupplierCard(BuildContext context, Supplier s) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        title: Text(s.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(s.phone, style: TextStyle(color: Colors.grey[600], fontSize: 13)),
            const SizedBox(height: 8),
            Text("Payable: Rs ${Formatter.formatCurrency(s.balance)}", 
                 style: TextStyle(color: s.balance > 0 ? Colors.red : Colors.green, fontWeight: FontWeight.bold)),
          ],
        ),
        trailing: PopupMenuButton(
          itemBuilder: (context) => [
            const PopupMenuItem(value: "PURCHASE", child: Text("New Purchase")),
            const PopupMenuItem(value: "PAY", child: Text("Make Payment")),
            const PopupMenuItem(value: "DELETE", child: Text("Delete")),
          ],
          onSelected: (val) {
            if (val == "PURCHASE") _showAddPurchaseDialog(context, s);
            if (val == "PAY") _showPaymentDialog(context, s);
            if (val == "DELETE") context.read<SupplierProvider>().deleteSupplier(s);
          },
        ),
      ),
    );
  }

  void _showAddSupplierDialog(BuildContext context) {
    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Add Supplier"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: "Supplier Name")),
            TextField(controller: phoneCtrl, decoration: const InputDecoration(labelText: "Phone Number"), keyboardType: TextInputType.phone),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () {
              if (nameCtrl.text.isEmpty) return;
              context.read<SupplierProvider>().addSupplier(Supplier(
                id: "SUP-${DateTime.now().millisecondsSinceEpoch}",
                name: nameCtrl.text,
                phone: phoneCtrl.text,
              ));
              Navigator.pop(context);
            },
            child: const Text("Add"),
          ),
        ],
      ),
    );
  }

  void _showAddPurchaseDialog(BuildContext context, Supplier s) {
    final items = context.read<InventoryProvider>().inventory;
    String? selectedItemId;
    final qtyCtrl = TextEditingController(text: "1");
    final priceCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text("Purchase from ${s.name}"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
               DropdownButtonFormField<String>(
                decoration: const InputDecoration(labelText: "Select Product"),
                items: items.map((e) => DropdownMenuItem(value: e.id, child: Text(e.name))).toList(),
                onChanged: (val) => setState(() => selectedItemId = val),
              ),
              TextField(controller: qtyCtrl, decoration: const InputDecoration(labelText: "Quantity"), keyboardType: TextInputType.number),
              TextField(controller: priceCtrl, decoration: const InputDecoration(labelText: "Purchase Price (per piece)"), keyboardType: TextInputType.number),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
            ElevatedButton(
              onPressed: () {
                if (selectedItemId == null) return;
                final qty = int.tryParse(qtyCtrl.text) ?? 0;
                final price = double.tryParse(priceCtrl.text) ?? 0.0;
                final item = items.firstWhere((e) => e.id == selectedItemId);
                
                context.read<SupplierProvider>().addPurchase(PurchaseRecord(
                  id: "PUR-${DateTime.now().millisecondsSinceEpoch}",
                  supplierId: s.id,
                  itemId: item.id,
                  itemName: item.name,
                  qty: qty,
                  purchasePrice: price,
                  date: DateTime.now(),
                ));
                Navigator.pop(context);
              },
              child: const Text("Confirm"),
            ),
          ],
        ),
      ),
    );
  }

  void _showPaymentDialog(BuildContext context, Supplier s) {
    final amountCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Pay to ${s.name}"),
        content: TextField(
          controller: amountCtrl,
          decoration: const InputDecoration(labelText: "Amount Paid", prefixText: "Rs "),
          keyboardType: TextInputType.number,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () {
              final amount = double.tryParse(amountCtrl.text) ?? 0.0;
              if (amount > 0) {
                context.read<SupplierProvider>().paySupplier(s.id, amount);
              }
              Navigator.pop(context);
            },
            child: const Text("Confirm Payment"),
          ),
        ],
      ),
    );
  }
}
