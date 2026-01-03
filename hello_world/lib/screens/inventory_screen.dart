import 'dart:io';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart'; // Database listener
import '../data/inventory_model.dart'; // Data Model
import '../services/ai_service.dart'; // AI Brain
import '../services/recognition_service.dart'; // Match Maker
import 'camera_screen.dart'; // Camera
import '../widgets/add_item_sheet.dart'; // Add Form
import '../widgets/sell_item_sheet.dart'; // Sell Form

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";

  // === 1. ADD ITEM (Sirf Sheet Kholo) ===
  void _addNewItemWithCamera() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      builder: (context) => const AddItemSheet(),
    );
  }

  // === 2. MAGIC: AI SEARCH & SELL ===
  Future<void> _scanForSearch() async {
    // Step A: Camera kholo
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const CameraScreen(mode: 'scan')),
    );

    // Step B: Check karo ke photo wapis aayi hai ya nahi
    if (result != null && result is File) {
      // User ko batao hum dhoond rahe hain
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("🔍 Identifying Item..."),
          duration: Duration(milliseconds: 1000),
        ),
      );

      try {
        // Step C: Photo ko AI Brain mein bhejo
        final embedding = await AIService().getEmbedding(result);

        // Step D: Database se saara data uthao
        final box = Hive.box<InventoryItem>('inventoryBox');
        final allItems = box.values.toList();

        // Step E: Match Dhoondo
        final match = RecognitionService().findMatch(embedding, allItems);

        if (!mounted) return;

        if (match != null) {
          // ✅ MATCH MIL GAYA!
          // Ab hum 'match' bhej rahe hain (jo InventoryItem hai) -> Safe!
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.white,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
            ),
            builder: (context) => SellItemSheet(item: match),
          );
        } else {
          // ❌ Match nahi mila
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("❌ Item nahi mila! Pehle Add karein."),
              backgroundColor: Colors.red,
            ),
          );
        }
      } catch (e) {
        print("Error: $e");
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Error: $e")));
      }
    }
  }

  // === 3. DELETE ITEM ===
  void _deleteItem(InventoryItem item) {
    item.delete();
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text("Item Deleted")));
  }

  // === 4. EDIT ITEM SHEET ===
  void _showEditSheet(InventoryItem item) {
    final nameCtrl = TextEditingController(text: item.name);
    final priceCtrl = TextEditingController(text: item.price.toString());
    final stockCtrl = TextEditingController(text: item.stock.toString());

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          top: 20,
          left: 20,
          right: 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              "EDIT ITEM",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(labelText: "Name"),
            ),
            TextField(
              controller: priceCtrl,
              decoration: const InputDecoration(labelText: "Price"),
              keyboardType: TextInputType.number,
            ),
            TextField(
              controller: stockCtrl,
              decoration: const InputDecoration(labelText: "Stock"),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                item.name = nameCtrl.text;
                item.price = double.tryParse(priceCtrl.text) ?? item.price;
                item.stock = int.tryParse(stockCtrl.text) ?? item.stock;
                item.save();
                Navigator.pop(context);
              },
              child: const Text("UPDATE"),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          "My Inventory (AI)",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const CircleAvatar(
              backgroundColor: Colors.blue,
              child: Icon(Icons.add, color: Colors.white),
            ),
            onPressed: _addNewItemWithCamera,
          ),
          const SizedBox(width: 10),
        ],
      ),
      body: Column(
        children: [
          // SEARCH BAR
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: TextField(
              controller: _searchController,
              onChanged: (val) => setState(() => _searchQuery = val),
              decoration: InputDecoration(
                hintText: "Search or Scan...",
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                // CAMERA BUTTON
                suffixIcon: IconButton(
                  icon: const Icon(Icons.camera_alt, color: Colors.blue),
                  onPressed:
                      _scanForSearch, // <--- Yahan ghalati thi, ab theek hai
                ),
                filled: true,
                fillColor: Colors.grey[100],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),

          // ITEM LIST
          Expanded(
            child: ValueListenableBuilder<Box<InventoryItem>>(
              valueListenable: Hive.box<InventoryItem>(
                'inventoryBox',
              ).listenable(),
              builder: (context, box, _) {
                final items = box.values.where((item) {
                  return item.name.toLowerCase().contains(
                    _searchQuery.toLowerCase(),
                  );
                }).toList();

                if (items.isEmpty) {
                  return const Center(child: Text("No items found."));
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final item = items[index];
                    return Dismissible(
                      key: Key(item.id),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        color: Colors.red,
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 20),
                        child: const Icon(Icons.delete, color: Colors.white),
                      ),
                      onDismissed: (direction) => _deleteItem(item),
                      child: GestureDetector(
                        onTap: () => _showEditSheet(item),
                        child: Card(
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                          margin: const EdgeInsets.only(bottom: 12),
                          child: ListTile(
                            leading: Container(
                              width: 50,
                              height: 50,
                              decoration: BoxDecoration(
                                color: Colors.blue[50],
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(
                                Icons.inventory_2,
                                color: Colors.blue,
                              ),
                            ),
                            title: Text(
                              item.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Text(
                              "Rs ${item.price.toStringAsFixed(0)}",
                            ),
                            trailing: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                color: item.stock < 5
                                    ? Colors.red[50]
                                    : Colors.green[50],
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                "${item.stock} Left",
                                style: TextStyle(
                                  color: item.stock < 5
                                      ? Colors.red
                                      : Colors.green,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
