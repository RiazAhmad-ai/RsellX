// lib/screens/inventory_screen.dart
import 'package:flutter/material.dart';
import '../widgets/add_item_sheet.dart'; // <--- Yeh add karein
import 'camera_screen.dart';

class InventoryScreen extends StatelessWidget {
  const InventoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        // SafeArea: Taake notch/status bar ke peeche na chup jaye
        child: Column(
          children: [
            // 1. HEADER & ADD BUTTON
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "DUKAN KA MAAL",
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -1,
                    ),
                  ),

                  // === BUTTON START ===
                  GestureDetector(
                    // Yahan 'async' lagaya taake hum 'await' use kar sakein
                    onTap: () async {
                      // 1. Camera kholo aur Jawab ka intezar karo (await)
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const CameraScreen(mode: 'add'),
                        ),
                      );

                      // 2. Agar Jawab 'true' aaya (Yani scan pura hua)
                      if (result == true && context.mounted) {
                        // 3. To ab Form (Sheet) kholo
                        showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          backgroundColor: Colors.white,
                          shape: const RoundedRectangleBorder(
                            borderRadius: BorderRadius.vertical(
                              top: Radius.circular(30),
                            ),
                          ),
                          builder: (context) => const AddItemSheet(),
                        );
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        "NAYA MAAL +",
                        style: TextStyle(
                          color: Colors.blue,
                          fontWeight: FontWeight.bold,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ),
                  // === BUTTON END ===
                ],
              ),
            ),

            const SizedBox(height: 24),

            // 2. SEARCH BAR
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(16),
                ),
                child: TextField(
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.search, color: Colors.grey),
                    hintText: "Naam se dhoondein...",
                    border: InputBorder.none, // Line hata di
                    contentPadding: const EdgeInsets.symmetric(vertical: 16),
                    // Camera Icon
                    suffixIcon: Container(
                      margin: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF334155),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.camera_alt,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 24),

            // 3. ITEM LIST (ListView)
            Expanded(
              // Bachi hui jagah le lo
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                children: [
                  // Item 1 (Manual Card abhi ke liye)
                  _buildInventoryItem(
                    title: "Bone China Cup (Blue)",
                    stock: "STOCK: 2 SETS",
                    isLowStock: true,
                  ),
                  const SizedBox(height: 16), // Gap
                  // Item 2
                  _buildInventoryItem(
                    title: "Dinner Set (24 Pcs)",
                    stock: "STOCK: 15 SETS",
                    isLowStock: false,
                  ),
                  const SizedBox(height: 16),
                  // Item 3
                  _buildInventoryItem(
                    title: "Tea Spoon Set",
                    stock: "STOCK: 50 PCS",
                    isLowStock: false,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper Widget (Taake baar baar code repeat na karna pade)
  Widget _buildInventoryItem({
    required String title,
    required String stock,
    required bool isLowStock,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isLowStock
            ? const Color(0xFFFEF2F2)
            : Colors.white, // Agar low stock hai to laal background
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isLowStock ? Colors.red.shade100 : Colors.grey.shade200,
        ),
        boxShadow: [
          if (!isLowStock) // Sirf normal items pe shadow
            BoxShadow(
              color: Colors.grey.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
        ],
      ),
      child: Row(
        children: [
          // Icon Box
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: isLowStock ? Colors.white : Colors.grey[100],
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              Icons.coffee,
              color: isLowStock ? Colors.red : Colors.grey,
              size: 30,
            ),
          ),
          const SizedBox(width: 16),
          // Text Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  stock,
                  style: TextStyle(
                    color: isLowStock ? Colors.red[500] : Colors.grey,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          // Tag (Agar low stock hai to dikhao)
          if (isLowStock)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                "KAM HAI",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 8,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
