// lib/widgets/sell_item_sheet.dart
import 'package:flutter/material.dart';
import '../data/inventory_model.dart';
import '../data/data_store.dart';
import '../utils/formatting.dart';

class SellItemSheet extends StatefulWidget {
  final InventoryItem item;

  const SellItemSheet({super.key, required this.item});

  @override
  State<SellItemSheet> createState() => _SellItemSheetState();
}

class _SellItemSheetState extends State<SellItemSheet> {
  late TextEditingController _salePriceController;
  double _profit = 0.0;

  @override
  void initState() {
    super.initState();
    _salePriceController = TextEditingController(
      text: widget.item.price.toInt().toString(),
    );
    _calculateProfit();
  }

  void _calculateProfit() {
    double salePrice = double.tryParse(_salePriceController.text) ?? 0.0;
    setState(() {
      _profit = salePrice - widget.item.price;
    });
  }

  void _confirmSell() {
    final double salePrice =
        double.tryParse(_salePriceController.text) ?? widget.item.price;
    final double profit = salePrice - widget.item.price;

    if (widget.item.stock > 0) {
      // 1. Stock kam karein
      widget.item.stock--;
      DataStore().updateInventoryItem(widget.item);

      // 2. History mein save karein (FIXED: Qty Added)
      DataStore().addHistoryItem({
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
        'itemId': widget.item.id,
        'name': widget.item.name,
        'qty': 1, // <--- YEH LINE ADD KI HAI (Zaroori)
        'price': salePrice,
        'actualPrice': widget.item.price,
        'profit': profit,
        'status': 'Sold',
        'date': DateTime.now().toIso8601String(),
      });

      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Sold for Rs ${Formatter.formatCurrency(salePrice)} (Profit: Rs ${Formatter.formatCurrency(profit)})",
          ),
          backgroundColor: Colors.green,
        ),
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
                  color: Colors.red[50],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.shopping_cart_checkout,
                  color: Colors.red,
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
                      color: widget.item.stock < 5 ? Colors.red : Colors.grey,
                      fontWeight: FontWeight.bold,
                    ),
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
                  "Actual Price (Khareed)",
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
          TextField(
            controller: _salePriceController,
            keyboardType: TextInputType.number,
            onChanged: (val) => _calculateProfit(),
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
            decoration: InputDecoration(
              labelText: "Sale Price (Bechne ki Qeemat)",
              labelStyle: const TextStyle(color: Colors.blue),
              prefixText: "Rs ",
              filled: true,
              fillColor: Colors.blue[50],
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Colors.blue, width: 2),
              ),
            ),
          ),
          const SizedBox(height: 12),
          if (_profit != 0)
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
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: widget.item.stock > 0 ? _confirmSell : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
              ),
              child: const Text(
                "CONFIRM SELL",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
