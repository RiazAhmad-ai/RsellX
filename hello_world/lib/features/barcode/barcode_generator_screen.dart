// lib/features/barcode/barcode_generator_screen.dart
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:barcode_widget/barcode_widget.dart';
import '../../shared/widgets/full_scanner_screen.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';
import '../../data/models/inventory_model.dart';
import '../../providers/inventory_provider.dart';
import '../../providers/settings_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';

class BarcodeGeneratorScreen extends StatefulWidget {
  final InventoryItem? item;

  const BarcodeGeneratorScreen({super.key, this.item});

  @override
  State<BarcodeGeneratorScreen> createState() => _BarcodeGeneratorScreenState();
}

class _BarcodeGeneratorScreenState extends State<BarcodeGeneratorScreen> {
  final TextEditingController _barcodeController = TextEditingController();
  final TextEditingController _labelController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _quantityController = TextEditingController(
    text: "1",
  );

  String _selectedBarcodeType = "Code128";
  bool _showPrice = true;
  bool _showLabel = true;
  int _labelQuantity = 1;

  final List<String> _barcodeTypes = [
    "Code128",
    "Code39",
    "EAN13",
    "EAN8",
    "UPC-A",
    "QR Code",
  ];

  @override
  void initState() {
    super.initState();
    if (widget.item != null) {
      _barcodeController.text = widget.item!.barcode;
      _labelController.text = widget.item!.name;
      _priceController.text = widget.item!.price.toStringAsFixed(0);
    }
  }

  @override
  void dispose() {
    _barcodeController.dispose();
    _labelController.dispose();
    _priceController.dispose();
    _quantityController.dispose();
    super.dispose();
  }

  Barcode _getBarcodeType() {
    switch (_selectedBarcodeType) {
      case "Code39":
        return Barcode.code39();
      case "EAN13":
        return Barcode.ean13();
      case "EAN8":
        return Barcode.ean8();
      case "UPC-A":
        return Barcode.upcA();
      case "QR Code":
        return Barcode.qrCode();
      default:
        return Barcode.code128();
    }
  }

  bool _isValidBarcode() {
    final barcodeData = _barcodeController.text.trim();
    if (barcodeData.isEmpty) return false;

    try {
      switch (_selectedBarcodeType) {
        case "EAN13":
          return barcodeData.length == 12 || barcodeData.length == 13;
        case "EAN8":
          return barcodeData.length == 7 || barcodeData.length == 8;
        case "UPC-A":
          return barcodeData.length == 11 || barcodeData.length == 12;
        default:
          return true;
      }
    } catch (e) {
      return false;
    }
  }

  // === BARCODE GENERATOR OPTIONS ===
  void _showBarcodeGeneratorOptions() {
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
                  "Choose a barcode format",
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
                    final code = timestamp.toString().substring(1);
                    Navigator.pop(context);
                    setState(() {
                      _barcodeController.text = code;
                    });
                    _showGeneratedMessage(code);
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
                    final random =
                        DateTime.now().millisecondsSinceEpoch % 100000000;
                    final code = random.toString().padLeft(8, '0');
                    Navigator.pop(context);
                    setState(() {
                      _barcodeController.text = code;
                    });
                    _showGeneratedMessage(code);
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
                    _showGeneratedMessage(code);
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
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
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
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
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
              _showGeneratedMessage(code);
            },
            child: const Text("Generate"),
          ),
        ],
      ),
    );
  }

  void _showGeneratedMessage(String code) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text("Barcode Generated: $code")),
          ],
        ),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showQuantityInputDialog() {
    final quantityController = TextEditingController(text: "$_labelQuantity");
    int tempQuantity = _labelQuantity;

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => Dialog(
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 24,
            vertical: 16, // More room for keyboard
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          child: SingleChildScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            child: Container(
              width: 320,
              padding: const EdgeInsets.all(0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Gradient Header
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.accent.withOpacity(0.85),
                          AppColors.accent,
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(24),
                      ),
                    ),
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Icon(
                            Icons.print_outlined,
                            color: Colors.white,
                            size: 28,
                          ),
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          "Number of Labels",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "Set quantity to print",
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Content
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        // Number Input with +/- buttons
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Minus Button
                            GestureDetector(
                              onTap: () {
                                int current = int.tryParse(quantityController.text) ?? 1;
                                if (current > 1) {
                                  setDialogState(() {
                                    tempQuantity = current - 1;
                                    quantityController.text = "$tempQuantity";
                                  });
                                }
                              },
                              child: _buildStepperButton(Icons.remove, Colors.red),
                            ),

                            const SizedBox(width: 16),

                            // Text Field
                            SizedBox(
                              width: 120,
                              child: TextField(
                                controller: quantityController,
                                keyboardType: TextInputType.number,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 36,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.accent,
                                ),
                                decoration: InputDecoration(
                                  filled: true,
                                  fillColor: AppColors.accent.withOpacity(0.08),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    borderSide: BorderSide.none,
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    borderSide: const BorderSide(
                                      color: AppColors.accent,
                                      width: 2,
                                    ),
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(
                                    vertical: 8,
                                  ),
                                ),
                                onChanged: (value) {
                                  setDialogState(() {
                                    tempQuantity = int.tryParse(value) ?? 1;
                                  });
                                },
                              ),
                            ),

                            const SizedBox(width: 16),

                            // Plus Button
                            GestureDetector(
                              onTap: () {
                                int current = int.tryParse(quantityController.text) ?? 1;
                                if (current < 500) {
                                  setDialogState(() {
                                    tempQuantity = current + 1;
                                    quantityController.text = "$tempQuantity";
                                  });
                                }
                              },
                              child: _buildStepperButton(Icons.add, Colors.green),
                            ),
                          ],
                        ),

                        const SizedBox(height: 20),

                        // Quick Select Buttons
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [5, 10, 25, 50, 100].map((qty) {
                            final isSelected = tempQuantity == qty;
                            return GestureDetector(
                              onTap: () {
                                setDialogState(() {
                                  tempQuantity = qty;
                                  quantityController.text = "$qty";
                                });
                              },
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? AppColors.accent
                                      : Colors.grey[100],
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: isSelected
                                        ? AppColors.accent
                                        : Colors.transparent,
                                  ),
                                  boxShadow: isSelected
                                      ? [
                                          BoxShadow(
                                            color: AppColors.accent.withOpacity(0.3),
                                            blurRadius: 6,
                                            offset: const Offset(0, 2),
                                          ),
                                        ]
                                      : [],
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  "$qty",
                                  style: TextStyle(
                                    color: isSelected
                                        ? Colors.white
                                        : Colors.grey[700],
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),

                        const SizedBox(height: 24),

                        // Action Buttons
                        Row(
                          children: [
                            Expanded(
                              child: TextButton(
                                onPressed: () => Navigator.pop(context),
                                style: TextButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    side: BorderSide(color: Colors.grey[300]!),
                                  ),
                                ),
                                child: Text(
                                  "Cancel",
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              flex: 2,
                              child: ElevatedButton.icon(
                                onPressed: () {
                                  final input = int.tryParse(quantityController.text.trim());
                                  if (input == null || input < 1 || input > 500) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text("Enter valid number (1-500)"),
                                        backgroundColor: Colors.red,
                                        behavior: SnackBarBehavior.floating,
                                      ),
                                    );
                                    return;
                                  }
                                  Navigator.pop(context);
                                  setState(() {
                                    _labelQuantity = input;
                                  });
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.accent,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  elevation: 4,
                                  shadowColor: AppColors.accent.withOpacity(0.4),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                                icon: const Icon(Icons.check, size: 20),
                                label: const Text(
                                  "Confirm",
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        
                        // Extra bottom padding for keyboard safety
                        SizedBox(height: MediaQuery.of(context).viewInsets.bottom > 0 ? 16 : 0),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStepperButton(IconData icon, Color color) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Icon(icon, color: color, size: 22),
    );
  }

  Future<void> _printBarcodes() async {
    final barcodeData = _barcodeController.text.trim();
    if (barcodeData.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please enter a barcode value"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final settingsProvider = context.read<SettingsProvider>();
    final shopName = settingsProvider.shopName;

    final pdf = pw.Document();

    // Calculate labels per page (4 columns x 10 rows = 40 per A4 page)
    const int labelsPerRow = 4;
    const int labelsPerColumn = 10;
    const int labelsPerPage = labelsPerRow * labelsPerColumn;

    int totalLabels = _labelQuantity;
    int pagesNeeded = (totalLabels / labelsPerPage).ceil();

    for (int page = 0; page < pagesNeeded; page++) {
      int labelsOnThisPage = (totalLabels - page * labelsPerPage).clamp(
        0,
        labelsPerPage,
      );

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(10),
          build: (context) {
            return pw.Wrap(
              spacing: 5,
              runSpacing: 5,
              children: List.generate(labelsOnThisPage, (index) {
                return pw.Container(
                  width: 130,
                  height: 70,
                  padding: const pw.EdgeInsets.all(4),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: PdfColors.grey300, width: 0.5),
                  ),
                  child: pw.Column(
                    mainAxisAlignment: pw.MainAxisAlignment.center,
                    children: [
                      if (_showLabel && _labelController.text.isNotEmpty)
                        pw.Text(
                          _labelController.text,
                          style: pw.TextStyle(
                            fontSize: 7,
                            fontWeight: pw.FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: pw.TextOverflow.clip,
                        ),
                      pw.SizedBox(height: 2),
                      pw.BarcodeWidget(
                        barcode: _getBarcodeType(),
                        data: barcodeData,
                        width: 110,
                        height: 30,
                        drawText: false,
                      ),
                      pw.SizedBox(height: 2),
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Expanded(
                            child: pw.Text(
                              barcodeData,
                              style: const pw.TextStyle(fontSize: 6),
                              maxLines: 1,
                            ),
                          ),
                          if (_showPrice && _priceController.text.isNotEmpty)
                            pw.Text(
                              "Rs ${_priceController.text}",
                              style: pw.TextStyle(
                                fontSize: 8,
                                fontWeight: pw.FontWeight.bold,
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                );
              }),
            );
          },
        ),
      );
    }

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: "barcode_labels_${DateTime.now().millisecondsSinceEpoch}",
    );
  }

  @override
  Widget build(BuildContext context) {
    final inventoryProvider = context.watch<InventoryProvider>();
    final barcodeData = _barcodeController.text.trim();
    final isValid = _isValidBarcode();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text("Barcode Generator", style: AppTextStyles.h2),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (widget.item == null)
            IconButton(
              icon: const Icon(
                Icons.inventory_2_outlined,
                color: AppColors.accent,
              ),
              onPressed: () =>
                  _showInventoryPicker(inventoryProvider.inventory),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // === BARCODE PREVIEW CARD ===
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                children: [
                  if (_showLabel && _labelController.text.isNotEmpty)
                    Text(
                      _labelController.text,
                      style: AppTextStyles.h3,
                      textAlign: TextAlign.center,
                    ),
                  const SizedBox(height: 16),
                  if (barcodeData.isNotEmpty && isValid)
                    BarcodeWidget(
                      barcode: _getBarcodeType(),
                      data: barcodeData,
                      width: 250,
                      height: 100,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                      errorBuilder: (context, error) => Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          "Invalid barcode format for $_selectedBarcodeType",
                          style: const TextStyle(color: Colors.red),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    )
                  else
                    Container(
                      width: 250,
                      height: 100,
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.grey[300]!,
                          style: BorderStyle.solid,
                        ),
                      ),
                      child: const Center(
                        child: Text(
                          "Enter barcode data\nto preview",
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey),
                        ),
                      ),
                    ),
                  const SizedBox(height: 12),
                  if (_showPrice && _priceController.text.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.accent.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        "Rs ${_priceController.text}",
                        style: AppTextStyles.h3.copyWith(
                          color: AppColors.accent,
                        ),
                      ),
                    ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // === BARCODE TYPE SELECTOR ===
            Text(
              "Barcode Type",
              style: AppTextStyles.label.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 40,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _barcodeTypes.length,
                itemBuilder: (context, index) {
                  final type = _barcodeTypes[index];
                  final isSelected = _selectedBarcodeType == type;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedBarcodeType = type),
                    child: Container(
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.accent : Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isSelected
                              ? AppColors.accent
                              : Colors.grey[300]!,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          type,
                          style: TextStyle(
                            color: isSelected ? Colors.white : Colors.black,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 20),

            // === BARCODE DATA INPUT WITH GENERATE BUTTON ===
            Text(
              "Barcode Data",
              style: AppTextStyles.label.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: TextField(
                    controller: _barcodeController,
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(
                      hintText: "Enter or generate barcode",
                      prefixIcon: const Icon(
                        Icons.qr_code,
                        color: AppColors.accent,
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey[300]!),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey[300]!),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: AppColors.accent,
                          width: 2,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                // Auto Generate Button
                Tooltip(
                  message: "Auto Generate",
                  child: GestureDetector(
                    onTap: _showBarcodeGeneratorOptions,
                    child: Container(
                      height: 56,
                      width: 56,
                      decoration: BoxDecoration(
                        color: AppColors.success,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.success.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.auto_awesome,
                        color: Colors.white,
                        size: 26,
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // === LABEL & PRICE ===
            Row(
              children: [
                Expanded(
                  child: _buildInputField(
                    controller: _labelController,
                    label: "Label (Name)",
                    hint: "Product name",
                    icon: Icons.label_outline,
                    onChanged: (_) => setState(() {}),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildInputField(
                    controller: _priceController,
                    label: "Price",
                    hint: "0",
                    icon: Icons.attach_money,
                    keyboardType: TextInputType.number,
                    onChanged: (_) => setState(() {}),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // === OPTIONS TOGGLES ===
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  _buildToggleRow(
                    "Show Label on Print",
                    _showLabel,
                    (val) => setState(() => _showLabel = val),
                  ),
                  const Divider(),
                  _buildToggleRow(
                    "Show Price on Print",
                    _showPrice,
                    (val) => setState(() => _showPrice = val),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // === QUANTITY SELECTOR ===
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Icon(Icons.copy_all, color: AppColors.accent),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Number of Labels",
                          style: AppTextStyles.bodyMedium.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          "Tap number to edit manually",
                          style: AppTextStyles.label,
                        ),
                      ],
                    ),
                  ),
                  Row(
                    children: [
                      IconButton(
                        onPressed: _labelQuantity > 1
                            ? () => setState(() => _labelQuantity--)
                            : null,
                        icon: const Icon(
                          Icons.remove_circle_outline,
                          color: Colors.red,
                        ),
                      ),
                      // Tappable Quantity Display
                      GestureDetector(
                        onTap: _showQuantityInputDialog,
                        child: Container(
                          width: 60,
                          height: 44,
                          decoration: BoxDecoration(
                            color: AppColors.accent.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: AppColors.accent.withOpacity(0.3),
                            ),
                          ),
                          child: Center(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  "$_labelQuantity",
                                  style: AppTextStyles.h3.copyWith(
                                    color: AppColors.accent,
                                  ),
                                ),
                                const SizedBox(width: 2),
                                Icon(
                                  Icons.edit,
                                  size: 12,
                                  color: AppColors.accent.withOpacity(0.7),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: _labelQuantity < 500
                            ? () => setState(() => _labelQuantity++)
                            : null,
                        icon: const Icon(
                          Icons.add_circle_outline,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // === QUICK QUANTITY BUTTONS ===
            Wrap(
              spacing: 8,
              children: [5, 10, 20, 50].map((qty) {
                return ActionChip(
                  label: Text("$qty Labels"),
                  onPressed: () => setState(() => _labelQuantity = qty),
                  backgroundColor: _labelQuantity == qty
                      ? AppColors.accent
                      : Colors.grey[200],
                  labelStyle: TextStyle(
                    color: _labelQuantity == qty ? Colors.white : Colors.black,
                    fontWeight: FontWeight.bold,
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 32),

            // === PRINT BUTTON ===
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton.icon(
                onPressed: barcodeData.isNotEmpty && isValid
                    ? _printBarcodes
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.secondary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                icon: const Icon(Icons.print),
                label: Text(
                  "PRINT $_labelQuantity BARCODE${_labelQuantity > 1 ? 'S' : ''}",
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    Function(String)? onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTextStyles.label.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          onChanged: onChanged,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(icon, color: AppColors.accent),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.accent, width: 2),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildToggleRow(String title, bool value, Function(bool) onChanged) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: AppTextStyles.bodyMedium),
        Switch(
          value: value,
          onChanged: onChanged,
          activeColor: AppColors.accent,
        ),
      ],
    );
  }

  void _showInventoryPicker(List<InventoryItem> items) {
    String searchQuery = "";

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            // Filter items based on search
            final filteredItems = items.where((item) {
              final query = searchQuery.toLowerCase();
              return item.name.toLowerCase().contains(query) ||
                  item.barcode.toLowerCase().contains(query);
            }).toList();

            return Container(
              height: MediaQuery.of(context).size.height * 0.85,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: Column(
                children: [
                  // Handle Bar
                  Container(
                    margin: const EdgeInsets.only(top: 12),
                    width: 50,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),

                  // Header
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppColors.accent.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.inventory_2,
                            color: AppColors.accent,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("Select Product", style: AppTextStyles.h2),
                              Text(
                                "${filteredItems.length} products available",
                                style: TextStyle(
                                  color: Colors.grey[500],
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.close, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),

                  // Search Bar with Barcode Button
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 10,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            onChanged: (value) {
                              setModalState(() {
                                searchQuery = value;
                              });
                            },
                            decoration: InputDecoration(
                              hintText: "Search name or barcode...",
                              prefixIcon: const Icon(
                                Icons.search,
                                color: AppColors.accent,
                              ),
                              suffixIcon: searchQuery.isNotEmpty
                                  ? IconButton(
                                      icon: const Icon(Icons.clear, size: 20),
                                      onPressed: () {
                                        setModalState(() {
                                          searchQuery = "";
                                        });
                                      },
                                    )
                                  : null,
                              filled: true,
                              fillColor: Colors.grey[100],
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide.none,
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 14,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        // Barcode Scan Button
                        GestureDetector(
                          onTap: () async {
                            Navigator.pop(context);
                            // Navigate to scanner and get result
                            final result = await Navigator.push(
                              this.context,
                              MaterialPageRoute(
                                builder: (context) => const FullScannerScreen(title: "Scan Product"),
                              ),
                            );
                            // If barcode found, search for it
                            if (result != null) {
                              final foundItem = items.firstWhere(
                                (item) => item.barcode == result,
                                orElse: () => InventoryItem(
                                  id: '',
                                  name: '',
                                  price: 0,
                                  stock: 0,
                                  barcode: '',
                                ),
                              );
                              if (foundItem.id.isNotEmpty) {
                                setState(() {
                                  _barcodeController.text = foundItem.barcode;
                                  _labelController.text = foundItem.name;
                                  _priceController.text = foundItem.price
                                      .toStringAsFixed(0);
                                });
                                ScaffoldMessenger.of(this.context).showSnackBar(
                                  SnackBar(
                                    content: Text("Found: ${foundItem.name}"),
                                    backgroundColor: AppColors.success,
                                  ),
                                );
                              } else {
                                ScaffoldMessenger.of(this.context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      "Product not found in inventory",
                                    ),
                                    backgroundColor: Colors.orange,
                                  ),
                                );
                              }
                            }
                          },
                          child: Container(
                            width: 52,
                            height: 52,
                            decoration: BoxDecoration(
                              color: AppColors.accent,
                              borderRadius: BorderRadius.circular(14),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.accent.withOpacity(0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.qr_code_scanner,
                              color: Colors.white,
                              size: 26,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const Divider(height: 1),

                  // Product List
                  Expanded(
                    child: filteredItems.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.search_off,
                                  size: 64,
                                  color: Colors.grey[300],
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  "No products found",
                                  style: TextStyle(
                                    color: Colors.grey[500],
                                    fontSize: 16,
                                  ),
                                ),
                                Text(
                                  "Try a different search term",
                                  style: TextStyle(
                                    color: Colors.grey[400],
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            itemCount: filteredItems.length,
                            itemBuilder: (context, index) {
                              final item = filteredItems[index];
                              final isLowStock =
                                  item.stock <= item.lowStockThreshold;

                              return GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _barcodeController.text = item.barcode;
                                    _labelController.text = item.name;
                                    _priceController.text = item.price
                                        .toStringAsFixed(0);
                                  });
                                  Navigator.pop(context);
                                },
                                child: Container(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  padding: const EdgeInsets.all(14),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: Colors.grey[200]!,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.03),
                                        blurRadius: 10,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    children: [
                                      // Product Icon with Gradient
                                      Container(
                                        width: 56,
                                        height: 56,
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            colors: [
                                              AppColors.accent.withOpacity(0.7),
                                              AppColors.accent,
                                            ],
                                            begin: Alignment.topLeft,
                                            end: Alignment.bottomRight,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            14,
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: AppColors.accent
                                                  .withOpacity(0.25),
                                              blurRadius: 8,
                                              offset: const Offset(0, 3),
                                            ),
                                          ],
                                        ),
                                        child: const Icon(
                                          Icons.shopping_bag_outlined,
                                          color: Colors.white,
                                          size: 26,
                                        ),
                                      ),

                                      const SizedBox(width: 14),

                                      // Product Info
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              item.name,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 15,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            const SizedBox(height: 4),
                                            Row(
                                              children: [
                                                Icon(
                                                  Icons.qr_code,
                                                  size: 14,
                                                  color: Colors.grey[500],
                                                ),
                                                const SizedBox(width: 4),
                                                Expanded(
                                                  child: Text(
                                                    item.barcode,
                                                    style: TextStyle(
                                                      color: Colors.grey[600],
                                                      fontSize: 12,
                                                    ),
                                                    maxLines: 1,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 6),
                                            Row(
                                              children: [
                                                // Price Badge
                                                Container(
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        horizontal: 8,
                                                        vertical: 3,
                                                      ),
                                                  decoration: BoxDecoration(
                                                    color: AppColors.success
                                                        .withOpacity(0.1),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          6,
                                                        ),
                                                  ),
                                                  child: Text(
                                                    "Rs ${item.price.toStringAsFixed(0)}",
                                                    style: const TextStyle(
                                                      color: AppColors.success,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontSize: 12,
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(width: 8),
                                                // ... (Price Badge is above)
                                                // Stock Badge ...
                                                Container(
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        horizontal: 8,
                                                        vertical: 3,
                                                      ),
                                                  decoration: BoxDecoration(
                                                    color: isLowStock
                                                        ? AppColors.error
                                                              .withOpacity(0.1)
                                                        : Colors.grey[100],
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          6,
                                                        ),
                                                  ),
                                                  child: Row(
                                                    mainAxisSize:
                                                        MainAxisSize.min,
                                                    children: [
                                                      Icon(
                                                        isLowStock
                                                            ? Icons
                                                                  .warning_amber
                                                            : Icons.inventory,
                                                        size: 12,
                                                        color: isLowStock
                                                            ? AppColors.error
                                                            : Colors.grey[600],
                                                      ),
                                                      const SizedBox(width: 4),
                                                      Text(
                                                        "${item.stock}",
                                                        style: TextStyle(
                                                          color: isLowStock
                                                              ? AppColors.error
                                                              : Colors
                                                                    .grey[600],
                                                          fontSize: 11,
                                                          fontWeight: isLowStock
                                                              ? FontWeight.bold
                                                              : FontWeight
                                                                    .normal,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 6),
                                            // Category & Size
                                            Wrap(
                                              spacing: 8,
                                              children: [
                                                if (item.category != "General")
                                                  Container(
                                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                    decoration: BoxDecoration(color: Colors.purple.withOpacity(0.1), borderRadius: BorderRadius.circular(4)),
                                                    child: Text(item.category, style: const TextStyle(fontSize: 10, color: Colors.purple, fontWeight: FontWeight.bold)),
                                                  ),
                                                if (item.size != "N/A")
                                                  Container(
                                                     padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                     decoration: BoxDecoration(color: Colors.orange.withOpacity(0.1), borderRadius: BorderRadius.circular(4)),
                                                     child: Text("Size: ${item.size}", style: const TextStyle(fontSize: 10, color: Colors.orange, fontWeight: FontWeight.bold)),
                                                  ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),

                                      // Arrow
                                      Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: AppColors.accent.withOpacity(
                                            0.1,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                        ),
                                        child: const Icon(
                                          Icons.arrow_forward_ios,
                                          size: 16,
                                          color: AppColors.accent,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
