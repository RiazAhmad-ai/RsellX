// lib/widgets/add_item_sheet.dart
import 'package:flutter/material.dart';

class AddItemSheet extends StatefulWidget {
  const AddItemSheet({super.key});

  @override
  State<AddItemSheet> createState() => _AddItemSheetState();
}

class _AddItemSheetState extends State<AddItemSheet> {
  // 1. STATE VARIABLES
  bool _hasSizes = false; // Kya sizes hain?

  // Agar sizes hain to unki list yahan store hogi
  final List<Map<String, String>> _sizesList = [];

  // Controllers (Simple item ke liye)
  final TextEditingController _simplePriceController = TextEditingController();
  final TextEditingController _simpleQtyController = TextEditingController(
    text: "1",
  );

  // === FUNCTION: SIZE ADD KARNE KA DIALOG ===
  void _addSizeDialog() {
    TextEditingController sizeNameController = TextEditingController();
    TextEditingController sizePriceController = TextEditingController();
    TextEditingController sizeQtyController = TextEditingController(text: "1");

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Add Size Variant"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: sizeNameController,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: "Size Name (e.g. Small, 42)",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: sizePriceController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: "Price",
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: sizeQtyController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: "Qty",
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () {
              if (sizeNameController.text.isNotEmpty) {
                setState(() {
                  _sizesList.add({
                    "name": sizeNameController.text,
                    "price": sizePriceController.text,
                    "qty": sizeQtyController.text,
                  });
                });
                Navigator.pop(context);
              }
            },
            child: const Text("ADD"),
          ),
        ],
      ),
    );
  }

  // === FUNCTION: REMOVE SIZE ===
  void _removeSize(int index) {
    setState(() {
      _sizesList.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(
        bottom: bottomPadding,
        left: 20,
        right: 20,
        top: 20,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 20),

            const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "STOCK ADD KAREIN",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
                ),
                Icon(Icons.add_box, color: Colors.blue),
              ],
            ),
            const SizedBox(height: 20),

            // 1. ITEM NAME (Common)
            const Text(
              "ITEM NAME",
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 5),
            TextFormField(
              autofocus: true,
              decoration: InputDecoration(
                hintText: "Misal: T-Shirt / Joggers",
                filled: true,
                fillColor: Colors.grey[50],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                prefixIcon: const Icon(
                  Icons.shopping_bag_outlined,
                  color: Colors.grey,
                ),
              ),
            ),
            const SizedBox(height: 20),

            // === 2. SIZES TOGGLE SWITCH ===
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: _hasSizes ? Colors.blue[50] : Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
                border: _hasSizes ? Border.all(color: Colors.blue) : null,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Kya is item ke Sizes hain?",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Switch(
                    value: _hasSizes,
                    activeColor: Colors.blue,
                    onChanged: (val) {
                      setState(() {
                        _hasSizes = val;
                      });
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // === 3. LOGIC: EITHER SIMPLE OR SIZES ===
            if (!_hasSizes) ...[
              // === OPTION A: SIMPLE ITEM (No Sizes) ===
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "PRICE (RS)",
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 5),
                        TextFormField(
                          controller: _simplePriceController,
                          keyboardType: TextInputType.number,
                          style: const TextStyle(
                            fontWeight: FontWeight.w900,
                            color: Colors.blue,
                          ),
                          decoration: InputDecoration(
                            hintText: "0",
                            filled: true,
                            fillColor: Colors.blue[50],
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
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "QUANTITY",
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 5),
                        TextFormField(
                          controller: _simpleQtyController,
                          textAlign: TextAlign.center,
                          keyboardType: TextInputType.number,
                          style: const TextStyle(fontWeight: FontWeight.w900),
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: Colors.grey[100],
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ] else ...[
              // === OPTION B: SIZES LIST (Variants) ===
              const Text(
                "ADDED SIZES:",
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 10),

              // List of added sizes
              if (_sizesList.isEmpty)
                const Center(
                  child: Text(
                    "No sizes added yet.",
                    style: TextStyle(
                      color: Colors.grey,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                )
              else
                ListView.builder(
                  shrinkWrap: true, // Zaroori hai column ke andar list ke liye
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _sizesList.length,
                  itemBuilder: (context, index) {
                    final size = _sizesList[index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(color: Colors.grey.shade200),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.blue[50],
                          child: Text(
                            size['name']![0].toUpperCase(),
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.blue,
                            ),
                          ),
                        ),
                        title: Text(
                          "Size: ${size['name']}",
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          "Price: ${size['price']} | Qty: ${size['qty']}",
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _removeSize(index),
                        ),
                      ),
                    );
                  },
                ),

              const SizedBox(height: 10),

              // Add Size Button
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _addSizeDialog,
                  icon: const Icon(Icons.add),
                  label: const Text("ADD A SIZE (e.g. S, M, L)"),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),
            ],

            const SizedBox(height: 20),

            // Description (Common)
            TextFormField(
              decoration: InputDecoration(
                hintText: "Description (Optional)...",
                filled: true,
                fillColor: Colors.grey[50],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
              ),
            ),

            const SizedBox(height: 30),

            // Save Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  // Logic to check simple or sizes
                  if (_hasSizes && _sizesList.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Please add at least one size!"),
                        backgroundColor: Colors.red,
                      ),
                    );
                    return;
                  }

                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        _hasSizes
                            ? "Item with ${_sizesList.length} sizes Added!"
                            : "Item Added Successfully!",
                      ),
                      backgroundColor: Colors.blue,
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                ),
                child: const Text(
                  "CONFIRM & ADD STOCK",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
