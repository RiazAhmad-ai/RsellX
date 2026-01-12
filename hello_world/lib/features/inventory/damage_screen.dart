import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/inventory_provider.dart';
import '../../data/models/damage_model.dart';
import '../../data/models/inventory_model.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../shared/widgets/full_scanner_screen.dart';
import '../../core/utils/id_generator.dart';

class DamageScreen extends StatelessWidget {
  const DamageScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<InventoryProvider>();
    final history = provider.damageHistory;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text("Damage Tracking", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: Column(
        children: [
          // Total Loss Card
          Container(
            margin: const EdgeInsets.all(20),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Colors.redAccent, Colors.red]),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [BoxShadow(color: const Color(0x4DF44336), blurRadius: 10, offset: const Offset(0, 5))],
            ),
            child: Row(
              children: [
                const Icon(Icons.broken_image_outlined, color: Colors.white, size: 40),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Total Damage Loss", style: TextStyle(color: Colors.white70, fontSize: 12)),
                    Text(
                      "Rs ${provider.getTotalDamageLoss().toInt()}",
                      style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text("Recent Damage Records", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ),
          ),

          Expanded(
            child: history.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.remove_shopping_cart_outlined, size: 60, color: Colors.grey[300]),
                        const SizedBox(height: 16),
                        const Text("No damage records found", style: TextStyle(color: Colors.grey)),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    itemCount: history.length,
                    itemBuilder: (context, index) {
                      final record = history[index];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [BoxShadow(color: const Color(0x05000000), blurRadius: 5, offset: const Offset(0, 2))],
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          leading: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: const BoxDecoration(color: Color(0x0DF44336), shape: BoxShape.circle),
                            child: const Icon(Icons.close, color: Colors.red, size: 20),
                          ),
                          title: Text(record.itemName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(record.reason, style: TextStyle(color: Colors.grey[600], fontSize: 11)),
                              const SizedBox(height: 4),
                              Text(DateFormat('dd MMM yyyy, hh:mm a').format(record.date), style: TextStyle(color: Colors.grey[400], fontSize: 10)),
                            ],
                          ),
                          trailing: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text("-${record.qty} Pcs", style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 15)),
                              Text("Rs ${record.lossAmount.toInt()}", style: TextStyle(color: Colors.grey[500], fontSize: 11)),
                            ],
                          ),
                          onLongPress: () => _showEditDamageSheet(context, record),
                          onTap: () => _showEditDamageSheet(context, record),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddDamageSheet(context),
        backgroundColor: Colors.red,
        icon: const Icon(Icons.add_circle_outline),
        label: const Text("RECORD DAMAGE", style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 0.5)),
      ),
    );
  }

  void _showAddDamageSheet(BuildContext context) {
    _showDamageForm(context, null);
  }

  void _showEditDamageSheet(BuildContext context, DamageRecord record) {
    _showDamageForm(context, record);
  }

  void _showDamageForm(BuildContext context, DamageRecord? editRecord) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DamageFormSheet(editRecord: editRecord),
    );
  }
}

class DamageFormSheet extends StatefulWidget {
  final DamageRecord? editRecord;
  const DamageFormSheet({super.key, this.editRecord});

  @override
  State<DamageFormSheet> createState() => _DamageFormSheetState();
}

class _DamageFormSheetState extends State<DamageFormSheet> {
  InventoryItem? selectedItem;
  final TextEditingController qtyCtrl = TextEditingController();
  final TextEditingController reasonCtrl = TextEditingController();
  final TextEditingController searchCtrl = TextEditingController();
  List<InventoryItem> filteredItems = [];

  @override
  void initState() {
    super.initState();
    final provider = context.read<InventoryProvider>();
    if (widget.editRecord != null) {
      qtyCtrl.text = widget.editRecord!.qty.toString();
      reasonCtrl.text = widget.editRecord!.reason;
      try {
        selectedItem = provider.inventory.firstWhere((e) => e.id == widget.editRecord!.itemId);
      } catch (_) {}
    }
  }

  void _scanBarcode() async {
    final barcode = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (context) => const FullScannerScreen(title: "Scan Product")),
    );

    if (barcode != null) {
      final provider = context.read<InventoryProvider>();
      final item = provider.findItemByBarcode(barcode);
      if (item != null) {
        setState(() {
          selectedItem = item;
          searchCtrl.clear();
          filteredItems.clear();
        });
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Item not found"), backgroundColor: Colors.red));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<InventoryProvider>();
    final allItems = provider.inventory;

    return Container(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10))),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(widget.editRecord == null ? "Record New Damage" : "Edit Damage Record", style: AppTextStyles.h2),
                if (widget.editRecord != null)
                  IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                    onPressed: () {
                      provider.deleteDamageRecord(widget.editRecord!);
                      Navigator.pop(context);
                    },
                  ),
              ],
            ),
            const SizedBox(height: 24),

            // Product Selection Section
            const Text("Step 1: Select Product", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey)),
            const SizedBox(height: 12),
            if (selectedItem != null)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: const Color(0x0D2196F3), borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0x332196F3))),
                child: Row(
                  children: [
                    const Icon(Icons.inventory_2, color: Colors.blue),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(selectedItem!.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                        Text("Current Stock: ${selectedItem!.stock} | Rs ${selectedItem!.price.toInt()}", style: TextStyle(color: Colors.grey[600], fontSize: 11)),
                      ]),
                    ),
                    TextButton(onPressed: () => setState(() => selectedItem = null), child: const Text("Change")),
                  ],
                ),
              )
            else ...[
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: searchCtrl,
                      decoration: InputDecoration(
                        hintText: "Search product...",
                        prefixIcon: const Icon(Icons.search),
                        suffixIcon: searchCtrl.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear, color: Colors.grey),
                                onPressed: () {
                                  setState(() {
                                    searchCtrl.clear();
                                    filteredItems = [];
                                  });
                                },
                              )
                            : null,
                        filled: true,
                        fillColor: Colors.grey[100],
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                      ),
                      onChanged: (val) {
                        setState(() {
                          if (val.isEmpty) {
                            filteredItems = [];
                          } else {
                            filteredItems = allItems.where((e) => e.name.toLowerCase().contains(val.toLowerCase()) || e.barcode.contains(val)).toList();
                          }
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  InkWell(
                    onTap: _scanBarcode,
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(14)),
                      child: const Icon(Icons.qr_code_scanner, color: Colors.white),
                    ),
                  ),
                ],
              ),
              if (filteredItems.isNotEmpty)
                Container(
                  margin: const EdgeInsets.only(top: 8),
                  constraints: const BoxConstraints(maxHeight: 200),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: Colors.grey[200]!)),
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: filteredItems.length,
                    itemBuilder: (context, index) {
                      final item = filteredItems[index];
                      return ListTile(
                        title: Text(item.name),
                        subtitle: Text("Price: Rs ${item.price.toInt()} | Stock: ${item.stock}"),
                        onTap: () => setState(() {
                          selectedItem = item;
                          searchCtrl.clear();
                          filteredItems = [];
                        }),
                      );
                    },
                  ),
                ),
            ],

            const SizedBox(height: 24),
            const Text("Step 2: Damage Details", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey)),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: qtyCtrl,
                    decoration: InputDecoration(
                      labelText: "Quantity",
                      prefixIcon: const Icon(Icons.numbers),
                      filled: true,
                      fillColor: Colors.grey[100],
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 2,
                  child: TextField(
                    controller: reasonCtrl,
                    decoration: InputDecoration(
                      labelText: "Reason",
                      hintText: "e.g. Broken",
                      prefixIcon: const Icon(Icons.comment_outlined),
                      filled: true,
                      fillColor: Colors.grey[100],
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
                onPressed: () {
                  if (selectedItem == null) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please select a product")));
                    return;
                  }
                  final qty = int.tryParse(qtyCtrl.text) ?? 0;
                  if (qty <= 0) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Invalid quantity")));
                    return;
                  }

                  if (widget.editRecord == null) {
                    // Create New
                    final record = DamageRecord(
                      id: IdGenerator.generateId("DMG"),
                      itemId: selectedItem!.id,
                      itemName: selectedItem!.name,
                      qty: qty,
                      lossAmount: selectedItem!.price * qty,
                      date: DateTime.now(),
                      reason: reasonCtrl.text.isEmpty ? "Broken" : reasonCtrl.text,
                    );
                    provider.addDamageRecord(record);
                  } else {
                    // Update Existing
                    final newRecord = DamageRecord(
                      id: widget.editRecord!.id,
                      itemId: selectedItem!.id,
                      itemName: selectedItem!.name,
                      qty: qty,
                      lossAmount: selectedItem!.price * qty,
                      date: widget.editRecord!.date,
                      reason: reasonCtrl.text.isEmpty ? "Broken" : reasonCtrl.text,
                    );
                    provider.updateDamageRecord(widget.editRecord!, newRecord);
                  }

                  Navigator.pop(context);
                },
                child: Text(
                  widget.editRecord == null ? "SAVE RECORD" : "UPDATE RECORD",
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}
