import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rsellx/providers/inventory_provider.dart';
import '../../data/models/inventory_model.dart';
import '../../shared/widgets/full_scanner_screen.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';

class AddItemSheet extends StatefulWidget {
  const AddItemSheet({super.key});

  @override
  State<AddItemSheet> createState() => _AddItemSheetState();
}

class _AddItemSheetState extends State<AddItemSheet> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _categoryController = TextEditingController();
  final TextEditingController _sizeController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _stockController = TextEditingController(text: "1");
  final TextEditingController _descController = TextEditingController();
  final TextEditingController _barcodeController = TextEditingController();
  final TextEditingController _thresholdController = TextEditingController(text: "5");

  bool _isSaving = false;

  // === BARCODE SCANNER ===
  Future<void> _scanBarcode() async {
    final String? barcode = await Navigator.push<String>(
      context,
      MaterialPageRoute(
        builder: (context) => const FullScannerScreen(title: "Register Item"),
      ),
    );

    if (barcode != null) {
      setState(() {
        _barcodeController.text = barcode;
      });
    }
  }

  // === BARCODE GENERATOR ===
  void _generateBarcode() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.only(
              left: 24,
              right: 24,
              top: 16,
              bottom: MediaQuery.of(context).viewInsets.bottom + 24,
            ),
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
                const SizedBox(height: 16),
                Text("Generate Barcode", style: AppTextStyles.h2),
                const SizedBox(height: 4),
                Text(
                  "Choose a barcode format for your product",
                  style: TextStyle(color: Colors.grey[600], fontSize: 13),
                ),
                const SizedBox(height: 20),
                
                // Option 1: Auto Generate (Timestamp based)
                _buildGenerateOption(
                  icon: Icons.auto_awesome,
                  color: AppColors.success,
                  title: "Auto Generate (Unique)",
                  subtitle: "Creates unique 12-digit code",
                  onTap: () {
                    final timestamp = DateTime.now().millisecondsSinceEpoch;
                    final code = timestamp.toString().substring(1); // 12 digits
                    Navigator.pop(context);
                    setState(() {
                      _barcodeController.text = code;
                    });
                    _showBarcodeGeneratedMessage(code);
                  },
                ),
                
                const SizedBox(height: 10),
                
                // Option 2: Random Numeric
                _buildGenerateOption(
                  icon: Icons.pin,
                  color: AppColors.accent,
                  title: "Random Numeric (8 digits)",
                  subtitle: "Simple numeric code like 12345678",
                  onTap: () {
                    final random = DateTime.now().millisecondsSinceEpoch % 100000000;
                    final code = random.toString().padLeft(8, '0');
                    Navigator.pop(context);
                    setState(() {
                      _barcodeController.text = code;
                    });
                    _showBarcodeGeneratedMessage(code);
                  },
                ),
                
                const SizedBox(height: 10),
                
                // Option 3: SKU Style (Alphanumeric)
                _buildGenerateOption(
                  icon: Icons.inventory,
                  color: AppColors.primary,
                  title: "SKU Style (Alphanumeric)",
                  subtitle: "Like SKU-A1B2C3D4",
                  onTap: () {
                    final timestamp = DateTime.now().millisecondsSinceEpoch;
                    final hex = timestamp.toRadixString(16).toUpperCase();
                    final code = "SKU-${hex.substring(hex.length - 8)}";
                    Navigator.pop(context);
                    setState(() {
                      _barcodeController.text = code;
                    });
                    _showBarcodeGeneratedMessage(code);
                  },
                ),
                
                const SizedBox(height: 10),
                
                // Option 4: Custom Prefix
                _buildGenerateOption(
                  icon: Icons.edit,
                  color: Colors.purple,
                  title: "Custom with Shop Prefix",
                  subtitle: "Your shop code + number",
                  onTap: () {
                    Navigator.pop(context);
                    _showCustomPrefixDialog();
                  },
                ),
                
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGenerateOption({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, color: color, size: 16),
          ],
        ),
      ),
    );
  }

  void _showCustomPrefixDialog() {
    final prefixController = TextEditingController(text: "RSX");
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text("Custom Prefix", style: AppTextStyles.h3),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("Enter your shop prefix (2-5 characters):"),
            const SizedBox(height: 16),
            TextField(
              controller: prefixController,
              maxLength: 5,
              textCapitalization: TextCapitalization.characters,
              decoration: InputDecoration(
                hintText: "e.g. RSX, SHOP",
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                counterText: "",
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accent,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              final prefix = prefixController.text.trim().toUpperCase();
              if (prefix.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Please enter a prefix")),
                );
                return;
              }
              final random = DateTime.now().millisecondsSinceEpoch % 1000000;
              final code = "$prefix-${random.toString().padLeft(6, '0')}";
              Navigator.pop(context);
              setState(() {
                _barcodeController.text = code;
              });
              _showBarcodeGeneratedMessage(code);
            },
            child: const Text("Generate"),
          ),
        ],
      ),
    );
  }

  void _showBarcodeGeneratedMessage(String code) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 12),
            Text("Barcode Generated: $code"),
          ],
        ),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _saveItem() async {
    if (_barcodeController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Barcode/Sticker Number is required!")));
      return;
    }
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Item Name is required!")));
      return;
    }
    if (_priceController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Price is required!")));
      return;
    }

    setState(() => _isSaving = true);

    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      final newItem = InventoryItem(
        id: timestamp,
        name: _nameController.text.trim(),
        price: double.tryParse(_priceController.text) ?? 0.0,
        stock: int.tryParse(_stockController.text) ?? 0,
        description: _descController.text.isEmpty ? null : _descController.text,
        barcode: _barcodeController.text.trim(),
        lowStockThreshold: int.tryParse(_thresholdController.text) ?? 5,
        category: _categoryController.text.trim().isEmpty ? "General" : _categoryController.text.trim(),
        size: _sizeController.text.trim().isEmpty ? "N/A" : _sizeController.text.trim(),
      );

      context.read<InventoryProvider>().addInventoryItem(newItem);

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Item Saved Successfully! ✅"),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(
        bottom: bottomPadding,
        left: 24,
        right: 24,
        top: 24,
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
            const SizedBox(height: 24),
            Text("ADD NEW STOCK", style: AppTextStyles.h2),
            const SizedBox(height: 24),

            // Barcode Field with Scan & Generate Buttons
            const Text("Barcode / Sticker Number", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _barcodeController,
                    decoration: InputDecoration(
                      hintText: "Enter or Generate Code",
                      prefixIcon: const Icon(Icons.qr_code),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                      filled: true,
                      fillColor: Colors.grey[100],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // Generate Barcode Button
                Tooltip(
                  message: "Auto Generate",
                  child: GestureDetector(
                    onTap: _generateBarcode,
                    child: Container(
                      height: 56,
                      width: 56,
                      decoration: BoxDecoration(
                        color: AppColors.success,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(Icons.auto_awesome, color: Colors.white),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // Scan Barcode Button
                Tooltip(
                  message: "Scan Barcode",
                  child: GestureDetector(
                    onTap: _scanBarcode,
                    child: Container(
                      height: 56,
                      width: 56,
                      decoration: BoxDecoration(color: AppColors.accent, borderRadius: BorderRadius.circular(16)),
                      child: const Icon(Icons.qr_code_scanner, color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            const Text("Item Details", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
            const SizedBox(height: 8),
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                hintText: "Item Name",
                prefixIcon: const Icon(Icons.inventory_2_outlined),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                filled: true,
                fillColor: Colors.grey[100],
              ),
            ),
            const SizedBox(height: 12),
            
            // Category and Size
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _categoryController,
                    decoration: InputDecoration(
                      hintText: "Category",
                      prefixIcon: const Icon(Icons.category),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                      filled: true,
                      fillColor: Colors.grey[100],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _sizeController,
                    decoration: InputDecoration(
                      hintText: "Size",
                      prefixIcon: const Icon(Icons.straighten),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                      filled: true,
                      fillColor: Colors.grey[100],
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _priceController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      hintText: "Cost Price",
                      prefixIcon: const Icon(Icons.attach_money),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                      filled: true,
                      fillColor: Colors.grey[100],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _stockController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      hintText: "Stock Qty",
                      prefixIcon: const Icon(Icons.numbers),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                      filled: true,
                      fillColor: Colors.grey[100],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _thresholdController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                hintText: "Low Stock Alert Level",
                prefixIcon: const Icon(Icons.warning_amber_rounded),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                filled: true,
                fillColor: Colors.grey[100],
              ),
            ),
            const SizedBox(height: 12),

            TextField(
              controller: _descController,
              maxLines: 2,
              decoration: InputDecoration(
                hintText: "Description (Optional)",
                prefixIcon: const Icon(Icons.description_outlined),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                filled: true,
                fillColor: Colors.grey[100],
              ),
            ),
            const SizedBox(height: 32),

            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _saveItem,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.secondary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
                child: _isSaving
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        "SAVE ITEM",
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
