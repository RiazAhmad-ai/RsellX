import 'package:flutter/material.dart';
import '../data/inventory_model.dart'; // Database Model

class SellItemSheet extends StatefulWidget {
  final InventoryItem item; // Jo item bechna hai wo yahan aayega

  const SellItemSheet({super.key, required this.item});

  @override
  State<SellItemSheet> createState() => _SellItemSheetState();
}

class _SellItemSheetState extends State<SellItemSheet> {
  int _qty = 1;
  late double _finalPrice;

  @override
  void initState() {
    super.initState();
    _finalPrice = widget.item.price; // Shuru mein price 1 item ki hogi
  }

  void _updatePrice(String qtyStr) {
    setState(() {
      _qty = int.tryParse(qtyStr) ?? 1;
      _finalPrice = widget.item.price * _qty;
    });
  }

  void _confirmSale() {
    // 1. Check karein stock hai ya nahi
    if (widget.item.stock < _qty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("❌ Stock khatam ho gaya hai!"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // 2. Stock Update Karein (Minus)
    setState(() {
      widget.item.stock = widget.item.stock - _qty;
    });

    // 3. Database mein Save Karein (Hamesha ke liye)
    widget.item.save();

    // 4. Band karein aur success dikhayein
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("✅ Sold ${_qty}x ${widget.item.name}! Stock Updated."),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 20,
        right: 20,
        top: 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          const SizedBox(height: 20),

          // Header
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "ITEM MIL GAYA!",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
              ),
              Icon(Icons.check_circle, color: Colors.green, size: 28),
            ],
          ),
          const SizedBox(height: 20),

          // Item Details Card (Dynamic Data)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.inventory_2, color: Colors.blue),
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.item.name, // <-- Asli Naam
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      "Stock Available: ${widget.item.stock}", // <-- Asli Stock
                      style: TextStyle(
                        color: widget.item.stock < 5 ? Colors.red : Colors.grey,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                Text(
                  "Rs ${widget.item.price.toStringAsFixed(0)}", // <-- Asli Price
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Qty Inputs
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "QTY",
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 5),
                    TextFormField(
                      initialValue: "1",
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      onChanged:
                          _updatePrice, // <-- Type karte hi price update hogi
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 20,
                      ),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Colors.grey[50],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "FINAL BILL",
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        vertical: 15,
                        horizontal: 15,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green[50],
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        "Rs ${_finalPrice.toStringAsFixed(0)}", // <-- Total Bill
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 20,
                          color: Colors.green,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 30),

          // SELL BUTTON
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _confirmSale, // <-- Button dabane par stock minus hoga
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                padding: const EdgeInsets.symmetric(vertical: 20),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.shopping_cart_checkout, color: Colors.white),
                  SizedBox(width: 10),
                  Text(
                    "CONFIRM SALE",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
