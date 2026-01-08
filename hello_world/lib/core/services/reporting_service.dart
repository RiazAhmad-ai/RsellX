import 'dart:io';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:excel/excel.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:file_picker/file_picker.dart';
import '../../data/models/sale_model.dart';
import '../../data/models/expense_model.dart';
import '../../data/models/inventory_model.dart';
import '../../shared/utils/formatting.dart';

class ReportingService {
  static Future<void> generateSalesReport({
    required String shopName,
    required List<SaleRecord> sales,
    required DateTime date,
  }) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(shopName, style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 8),
              pw.Text("Sales Report - ${date.day}/${date.month}/${date.year}"),
              pw.Divider(),
              pw.SizedBox(height: 16),
              pw.TableHelper.fromTextArray(
                headers: ['Item', 'Qty', 'Price', 'Total', 'Profit'],
                data: sales.map((s) => [
                  s.name,
                  s.qty.toString(),
                  Formatter.formatCurrency(s.price),
                  Formatter.formatCurrency(s.price * s.qty),
                  Formatter.formatCurrency(s.profit),
                ]).toList(),
              ),
              pw.SizedBox(height: 20),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.end,
                children: [
                   pw.Text(
                    "Total Sales: Rs ${Formatter.formatCurrency(sales.fold(0, (sum, s) => sum + (s.price * s.qty).toInt()))}",
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(onLayout: (PdfPageFormat format) async => pdf.save());
  }

  static Future<void> generateExpenseReport({
    required String shopName,
    required List<ExpenseItem> expenses,
    required DateTime date,
  }) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(shopName, style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 8),
              pw.Text("Expense Report - ${date.day}/${date.month}/${date.year}"),
              pw.Divider(),
              pw.SizedBox(height: 16),
              pw.TableHelper.fromTextArray(
                headers: ['Title', 'Category', 'Amount'],
                data: expenses.map((e) => [
                  e.title,
                  e.category,
                  Formatter.formatCurrency(e.amount),
                ]).toList(),
              ),
              pw.SizedBox(height: 20),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.end,
                children: [
                  pw.Text(
                    "Total Expenses: Rs ${Formatter.formatCurrency(expenses.fold(0.0, (sum, e) => sum + e.amount))}",
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(onLayout: (PdfPageFormat format) async => pdf.save());
  }

  static Future<void> generateInventoryExcel({
    required String shopName,
    required List<InventoryItem> items,
  }) async {
    var excel = Excel.createExcel();
    Sheet sheetObject = excel['Inventory'];
    excel.delete('Sheet1'); // Remove default sheet

    // Styles
    CellStyle headerStyle = CellStyle(
      bold: true,
      fontFamily: getFontFamily(FontFamily.Arial),
      backgroundColorHex: ExcelColor.fromHexString("#E53935"), // Red
      fontColorHex: ExcelColor.fromHexString("#FFFFFF"),
    );

    // Headers
    sheetObject.appendRow([
      TextCellValue("Item Name"),
      TextCellValue("Category"),
      TextCellValue("Size"),
      TextCellValue("Barcode"),
      TextCellValue("Price (Rs)"),
      TextCellValue("Current Stock"),
      TextCellValue("Stock Value (Rs)"),
    ]);

    for (int i = 0; i < 7; i++) {
      sheetObject.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0)).cellStyle = headerStyle;
    }

    // Data
    for (var item in items) {
      sheetObject.appendRow([
        TextCellValue(item.name),
        TextCellValue(item.category),
        TextCellValue(item.size),
        TextCellValue(item.barcode),
        DoubleCellValue(item.price),
        IntCellValue(item.stock),
        DoubleCellValue(item.price * item.stock),
      ]);
    }

    final String fileName = "inventory_report_${DateTime.now().millisecondsSinceEpoch}.xlsx";
    final directory = await getTemporaryDirectory();
    final file = File("${directory.path}/$fileName");
    
    final bytes = excel.save();
    if (bytes != null) {
      await file.writeAsBytes(bytes);
      await Share.shareXFiles([XFile(file.path)], text: 'Inventory Stock Report - $shopName');
    }
  }

  static Future<void> generateInvoice({
    required String shopName,
    required String address,
    required List<SaleRecord> items,
    required String billId,
    double discount = 0.0,
    PdfPageFormat paperFormat = PdfPageFormat.roll80,
  }) async {
    final pdf = pw.Document();
    
    // Load Logo
    pw.MemoryImage? logoImage;
    try {
      final byteData = await rootBundle.load('assets/splash.png');
      logoImage = pw.MemoryImage(byteData.buffer.asUint8List());
    } catch (_) {
      // If logo fails, we proceed without it
    }

    final double subTotal = items.fold(0.0, (sum, item) => sum + (item.price * item.qty));
    final double finalTotal = subTotal - discount;
    final bool isSmall = paperFormat.width < 200; // roll57 is ~160, roll80 is ~226

    pdf.addPage(
      pw.Page(
        pageFormat: paperFormat,
        margin: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 10),
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              // === HEADER ===
              if (logoImage != null)
                pw.Container(
                  height: 40,
                  width: 40,
                  child: pw.Image(logoImage),
                ),
              pw.SizedBox(height: 5),
              pw.Text(shopName.toUpperCase(), style: pw.TextStyle(fontSize: isSmall ? 12 : 16, fontWeight: pw.FontWeight.bold), textAlign: pw.TextAlign.center),
              if (address.isNotEmpty)
                pw.Text(address, style: pw.TextStyle(fontSize: isSmall ? 8 : 10), textAlign: pw.TextAlign.center),
              
              pw.SizedBox(height: 8),
              pw.Divider(thickness: 1, color: PdfColors.black),
              
              // === INFO ===
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text("Bill: #${billId.substring(billId.length - 6)}", style: pw.TextStyle(fontSize: isSmall ? 7 : 9)),
                  pw.Text("${DateTime.now().day}/${DateTime.now().month} ${DateTime.now().hour}:${DateTime.now().minute}", style: pw.TextStyle(fontSize: isSmall ? 7 : 9)),
                ],
              ),
              pw.Divider(thickness: 1, color: PdfColors.black),
              pw.SizedBox(height: 5),
              
              // === ITEMS TABLE ===
              pw.TableHelper.fromTextArray(
                context: context,
                headers: ['Item', 'Qty', 'Amt'],
                columnWidths: {
                  0: const pw.FlexColumnWidth(3),
                  1: const pw.FlexColumnWidth(1),
                  2: const pw.FlexColumnWidth(2),
                },
                headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: isSmall ? 8 : 10),
                cellStyle: pw.TextStyle(fontSize: isSmall ? 7 : 9),
                cellAlignment: pw.Alignment.centerLeft,
                headerDecoration: const pw.BoxDecoration(border: null),
                border: null,
                data: items.map((i) => [
                  i.name.length > (isSmall ? 12 : 20) ? "${i.name.substring(0, isSmall ? 10 : 18)}.." : i.name,
                  i.qty.toString(),
                  Formatter.formatCurrency(i.price * i.qty),
                ]).toList(),
              ),
              
              pw.SizedBox(height: 8),
              pw.Divider(thickness: 0.5, color: PdfColors.grey),
              
              // === TOTALS ===
              pw.Container(
                alignment: pw.Alignment.centerRight,
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text("Subtotal:  ${Formatter.formatCurrency(subTotal)}", style: pw.TextStyle(fontSize: isSmall ? 8 : 10)),
                    if (discount > 0)
                      pw.Text("Discount: -${Formatter.formatCurrency(discount)}", style: pw.TextStyle(fontSize: isSmall ? 8 : 10)),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      "TOTAL: ${Formatter.formatCurrency(finalTotal)}", 
                      style: pw.TextStyle(fontSize: isSmall ? 12 : 14, fontWeight: pw.FontWeight.bold)
                    ),
                  ],
                ),
              ),
              
              pw.Divider(thickness: 1, color: PdfColors.black),
              pw.SizedBox(height: 10),
              
              // === FOOTER ===
              pw.Text("Thank you for choosing us!", style: pw.TextStyle(fontSize: isSmall ? 8 : 10, fontStyle: pw.FontStyle.italic)),
              pw.Text("No Return / No Exchange after sale.", style: pw.TextStyle(fontSize: isSmall ? 7 : 8)),
              pw.SizedBox(height: 10),
              pw.BarcodeWidget(
                barcode: pw.Barcode.code128(),
                data: billId,
                width: isSmall ? 80 : 120,
                height: 20,
                drawText: false,
              ),
              pw.SizedBox(height: 20),
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(onLayout: (PdfPageFormat format) async => pdf.save(), name: "Invoice_$billId");
  }

  static Future<bool> importInventoryFromExcel() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx'],
      );

      if (result != null) {
        var bytes = File(result.files.single.path!).readAsBytesSync();
        var excel = Excel.decodeBytes(bytes);
        final box = Hive.box<InventoryItem>('inventoryBox');

        for (var table in excel.tables.keys) {
          var rows = excel.tables[table]!.rows;
          // Assume first row is header: Name, Barcode, Price, Stock
          for (int i = 1; i < rows.length; i++) {
            var row = rows[i];
            if (row.length < 3) continue;

            final name = row[0]?.value?.toString() ?? "";
            final barcode = row[1]?.value?.toString() ?? "N/A";
            final price = double.tryParse(row[2]?.value?.toString() ?? "0") ?? 0.0;
            final stock = int.tryParse(row[3]?.value?.toString() ?? "0") ?? 0;

            if (name.isNotEmpty) {
              box.add(InventoryItem(
                id: DateTime.now().millisecondsSinceEpoch.toString() + i.toString(),
                name: name,
                barcode: barcode,
                price: price,
                stock: stock,
              ));
            }
          }
        }
        return true;
      }
    } catch (e) {
      print("Excel Import Error: $e");
    }
    return false;
  }
}
