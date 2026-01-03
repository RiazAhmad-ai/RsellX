import 'dart:io';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../screens/camera_screen.dart'; // Camera Screen
import '../services/ai_service.dart'; // Brain
import '../data/inventory_model.dart'; // Database Model

class AddItemSheet extends StatefulWidget {
  const AddItemSheet({super.key});

  @override
  State<AddItemSheet> createState() => _AddItemSheetState();
}

class _AddItemSheetState extends State<AddItemSheet> {
  // Controllers
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _stockController = TextEditingController(
    text: "1",
  );
  final TextEditingController _descController = TextEditingController();

  // Images Store karne ke liye
  final List<File> _capturedImages = [];
  bool _isSaving = false; // Loading indicator ke liye

  // === 1. CAMERA SE PHOTO LENA ===
  Future<void> _takePhoto() async {
    // Camera Screen kholo ('add' mode mein)
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const CameraScreen(mode: 'add')),
    );

    // Agar photo wapis aayi hai
    if (result != null && result is File) {
      setState(() {
        _capturedImages.add(result);
      });
    }
  }

  // === 2. IMAGE REMOVE KARNA ===
  void _removePhoto(int index) {
    setState(() {
      _capturedImages.removeAt(index);
    });
  }

  // === 3. FINAL SAVE LOGIC (JADOO YAHAN HAI) ===
  Future<void> _saveItem() async {
    if (_nameController.text.isEmpty || _priceController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Name aur Price zaroori hain!")),
      );
      return;
    }

    if (_capturedImages.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Kam se kam ek photo lein!")),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      // A. Har Photo ka AI Fingerprint nikalo
      List<List<double>> allEmbeddings = [];

      for (var imageFile in _capturedImages) {
        // AI Service ko call kiya
        List<double> fingerprint = await AIService().getEmbedding(imageFile);
        allEmbeddings.add(fingerprint);
      }

      // B. Data Object banao
      final newItem = InventoryItem(
        id: DateTime.now().millisecondsSinceEpoch.toString(), // Unique ID
        name: _nameController.text,
        price: double.tryParse(_priceController.text) ?? 0.0,
        stock: int.tryParse(_stockController.text) ?? 0,
        description: _descController.text,
        embeddings: allEmbeddings, // Yahan numbers save ho rahe hain
      );

      // C. Hive Box mein Save karo
      var box = Hive.box<InventoryItem>('inventoryBox');
      await box.add(newItem);

      // D. Success! Sheet band karo
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Item Saved with AI Fingerprints! ✅")),
        );
      }
    } catch (e) {
      print("Error saving: $e");
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Error: $e")));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Keyboard ke liye padding
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
            // Handle Bar
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

            const Text(
              "ADD NEW STOCK",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),

            // === INPUT FIELDS ===
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: "Item Name",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.grey[50],
              ),
            ),
            const SizedBox(height: 10),

            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _priceController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: "Price",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: Colors.grey[50],
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: _stockController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: "Stock Qty",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: Colors.grey[50],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // === PHOTOS SECTION ===
            const Text(
              "Photos (Multiple Angles)",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),

            SizedBox(
              height: 100,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _capturedImages.length + 1, // +1 for Add Button
                itemBuilder: (context, index) {
                  // Last item is Add Button
                  if (index == _capturedImages.length) {
                    return GestureDetector(
                      onTap: _takePhoto,
                      child: Container(
                        width: 100,
                        margin: const EdgeInsets.only(right: 10),
                        decoration: BoxDecoration(
                          color: Colors.blue[50],
                          // FIX: Changed BorderStyle.dash to BorderStyle.solid
                          border: Border.all(
                            color: Colors.blue,
                            style: BorderStyle.solid,
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.camera_alt, color: Colors.blue),
                            Text(
                              "Add Photo",
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.blue,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  // Captured Images
                  return Stack(
                    children: [
                      Container(
                        width: 100,
                        margin: const EdgeInsets.only(right: 10),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          image: DecorationImage(
                            image: FileImage(_capturedImages[index]),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      Positioned(
                        right: 0,
                        top: 0,
                        child: GestureDetector(
                          onTap: () => _removePhoto(index),
                          child: Container(
                            color: Colors.black54,
                            child: const Icon(
                              Icons.close,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),

            const SizedBox(height: 20),

            // === SAVE BUTTON ===
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _saveItem, // Disable if saving
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isSaving
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        "SAVE ITEM (AI PROCESSING)",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
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
