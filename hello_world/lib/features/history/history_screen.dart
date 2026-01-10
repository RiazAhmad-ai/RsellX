import 'package:flutter/material.dart';
import 'package:rsellx/providers/sales_provider.dart';
import 'package:rsellx/providers/settings_provider.dart';
import 'package:rsellx/providers/inventory_provider.dart';
import 'package:provider/provider.dart';
import '../../data/models/sale_model.dart';
import '../../data/models/inventory_model.dart';
import '../../shared/utils/formatting.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/services/reporting_service.dart';
import '../../shared/widgets/full_scanner_screen.dart';
import '../../shared/widgets/text_scanner_screen.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  DateTime _selectedDate = DateTime.now();
  String _searchQuery = "";
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  
  int _currentPage = 1;
  static const int _pageSize = 15;
  bool _isLoadingMore = false;
  List<String> _displayedBillOrder = [];
  Map<String, List<SaleRecord>> _groupedSales = {};
  List<SaleRecord> _filteredHistory = [];

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      _loadMoreHistory();
    }
  }

  void _syncData(List<SaleRecord> allHistory) {
    _filteredHistory = allHistory.where((item) {
      final matchesDate = _isSameDay(item.date, _selectedDate);
      final name = item.name.toLowerCase();
      final status = item.status.toLowerCase();
      final query = _searchQuery.toLowerCase();
      return matchesDate && (name.contains(query) || status.contains(query));
    }).toList();

    _groupedSales = {};
    final List<String> fullBillOrder = [];
    for (var item in _filteredHistory) {
      final key = item.billId ?? item.id;
      if (!_groupedSales.containsKey(key)) {
        _groupedSales[key] = [];
        fullBillOrder.add(key);
      }
      _groupedSales[key]!.add(item);
    }
    
    // Sort bills by time (newest first)
    fullBillOrder.sort((a, b) {
       final timeA = _groupedSales[a]!.first.date;
       final timeB = _groupedSales[b]!.first.date;
       return timeB.compareTo(timeA);
    });

    _displayedBillOrder = fullBillOrder.take(_currentPage * _pageSize).toList();

  }

  void _loadMoreHistory() {
    if (_isLoadingMore) return;
    
    final salesProvider = context.read<SalesProvider>();
    final allHistory = salesProvider.historyItems;

    final filtered = allHistory.where((item) {
      final matchesDate = _isSameDay(item.date, _selectedDate);
      final name = item.name.toLowerCase();
      final status = item.status.toLowerCase();
      final query = _searchQuery.toLowerCase();
      return matchesDate && (name.contains(query) || status.contains(query));
    }).toList();

    final List<String> fullBillOrder = [];
    final Map<String, List<SaleRecord>> groups = {};
    for (var item in filtered) {
      final key = item.billId ?? item.id;
      if (!groups.containsKey(key)) {
        groups[key] = [];
        fullBillOrder.add(key);
      }
      groups[key]!.add(item);
    }

    fullBillOrder.sort((a, b) => groups[b]!.first.date.compareTo(groups[a]!.first.date));

    if (_displayedBillOrder.length >= fullBillOrder.length) return;

    setState(() => _isLoadingMore = true);

    Future.delayed(const Duration(milliseconds: 300), () {
      if (!mounted) return;
      final nextBills = fullBillOrder.skip(_currentPage * _pageSize).take(_pageSize).toList();
      setState(() {
        _displayedBillOrder.addAll(nextBills);
        _currentPage++;
        _isLoadingMore = false;
      });
    });
  }


  void _openTextScanner() async {
    final String? text = await Navigator.push<String>(
      context,
      MaterialPageRoute(
        builder: (context) => const TextScannerScreen(),
      ),
    );

    if (text != null && text.isNotEmpty) {
      // Basic cleanup of scanned text
      final cleanText = text.replaceAll('\n', ' ').trim();
      setState(() {
        _searchController.text = cleanText;
        _searchQuery = cleanText;
        _currentPage = 1;
      });
    }
  }

  void _openSearchScanner() async {
    final String? barcode = await Navigator.push<String>(
      context,
      MaterialPageRoute(
        builder: (context) => const FullScannerScreen(title: "Scan to Search"),
      ),
    );

    if (barcode == null) return;
    
    final match = context.read<InventoryProvider>().findItemByBarcode(barcode);
    if (match != null) {
      setState(() {
        _searchController.text = match.name;
        _searchQuery = match.name;
        _currentPage = 1;
      });
    } else {
      setState(() {
        _searchController.text = barcode;
        _searchQuery = barcode;
        _currentPage = 1;
      });
    }
  }

  String _formatDateManual(DateTime date) {
    const months = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"];
    return "${date.day.toString().padLeft(2, '0')} ${months[date.month - 1]} ${date.year}";
  }

  // === HELPERS ===
  DateTime _parseDate(dynamic dateVal) {
    if (dateVal == null) return DateTime.now();
    if (dateVal is DateTime) return dateVal;
    return DateTime.tryParse(dateVal.toString()) ?? DateTime.now();
  }

  bool _isSameDay(DateTime d1, DateTime d2) {
    return d1.year == d2.year && d1.month == d2.month && d1.day == d2.day;
  }

  // === ACTIONS ===
  void _handleRefund(SaleRecord item) {
    int totalQty = item.qty;
    int refundQty = 1;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFFff9966), Color(0xFFff5e62)], // Orange/Red
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                  ),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.refresh, color: Colors.white, size: 32),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        "Process Refund",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item.name,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 14,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),

                // Content
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      const Text(
                        "How many items to refund?",
                        style: TextStyle(color: Colors.grey, fontSize: 13),
                      ),
                      const SizedBox(height: 20),
                      
                      if (totalQty > 1)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _buildStepperBtn(Icons.remove, Colors.red, () {
                              if (refundQty > 1) setDialogState(() => refundQty--);
                            }),
                            Container(
                              width: 80,
                              alignment: Alignment.center,
                              child: Text(
                                "$refundQty",
                                style: const TextStyle(
                                  fontSize: 32,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                            ),
                            _buildStepperBtn(Icons.add, Colors.green, () {
                              if (refundQty < totalQty) setDialogState(() => refundQty++);
                            }),
                          ],
                        )
                      else
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text(
                            "1 Item (Full Refund)",
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                        ),

                      const SizedBox(height: 24),
                      
                      Row(
                        children: [
                          Expanded(
                            child: TextButton(
                              onPressed: () => Navigator.pop(ctx),
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 14),
                              ),
                              child: Text("Cancel", style: TextStyle(color: Colors.grey[600])),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 2,
                            child: ElevatedButton.icon(
                              onPressed: () {
                                context.read<SalesProvider>().refundSale(item, refundQty: refundQty);
                                Navigator.pop(ctx);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text("Refund of $refundQty item(s) processed! ✅"),
                                    behavior: SnackBarBehavior.floating,
                                    backgroundColor: Colors.green,
                                  ),
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFff5e62),
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              icon: const Icon(Icons.check_circle_outline, size: 20),
                              label: const Text(
                                "Confirm Refund",
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStepperBtn(IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Icon(icon, color: color),
      ),
    );
  }

  void _handleDelete(String id) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
             // Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFFef473a), Color(0xFFcb2d3e)], // Red Gradient
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                children: [
                   Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.warning_amber_rounded, color: Colors.white, size: 36),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    "Delete Record?",
                    style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  const Text(
                    "Are you sure you want to delete this record properly?\nThis action cannot be undone.",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.black54, fontSize: 15, height: 1.4),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: () => Navigator.pop(ctx),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          child: Text("Keep It", style: TextStyle(color: Colors.grey[600])),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            context.read<SalesProvider>().deleteHistoryItem(id);
                            Navigator.pop(ctx);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFef473a),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            elevation: 0,
                          ),
                          child: const Text("Delete", style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleEdit(SaleRecord item) {
    final nameCtrl = TextEditingController(text: item.name);
    final priceCtrl = TextEditingController(text: item.price.toString());
    final qtyCtrl = TextEditingController(text: item.qty.toString());

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        insetPadding: const EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF2193b0), Color(0xFF6dd5ed)], // Blue Gradient
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                ),
                child: Column(
                  children: [
                     Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.edit_note, color: Colors.white, size: 30),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      "Edit Sale Record",
                      style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),

              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    _buildStyledTextField(nameCtrl, "Item Name", Icons.shopping_bag_outlined),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(child: _buildStyledTextField(priceCtrl, "Sale Price", Icons.attach_money, isNumber: true)),
                        const SizedBox(width: 16),
                        Expanded(child: _buildStyledTextField(qtyCtrl, "Quantity", Icons.numbers, isNumber: true)),
                      ],
                    ),
                    const SizedBox(height: 24),
                    
                    Row(
                      children: [
                        Expanded(
                          child: TextButton(
                            onPressed: () => Navigator.pop(context),
                             style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 14),
                              ),
                            child: Text("Cancel", style: TextStyle(color: Colors.grey[600])),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: ElevatedButton.icon(
                            onPressed: () {
                              final updatedSale = SaleRecord(
                                id: item.id,
                                itemId: item.itemId,
                                name: nameCtrl.text,
                                price: double.tryParse(priceCtrl.text) ?? item.price,
                                actualPrice: item.actualPrice,
                                qty: int.tryParse(qtyCtrl.text) ?? item.qty,
                                profit: 0, // Recalculated
                                date: item.date,
                                status: item.status,
                              );
                              context.read<SalesProvider>().updateHistoryItem(item, updatedSale);
                              Navigator.pop(context);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF2193b0),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              elevation: 2,
                            ),
                            icon: const Icon(Icons.save_outlined, size: 20),
                            label: const Text("Save Changes", style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStyledTextField(TextEditingController controller, String label, IconData icon, {bool isNumber = false}) {
    return TextField(
      controller: controller,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Colors.grey[400], size: 20),
        filled: true,
        fillColor: Colors.grey[50],
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final salesProvider = context.watch<SalesProvider>();
    final settingsProvider = context.watch<SettingsProvider>();

    // Sync data reactively from the provider's source of truth
    _syncData(salesProvider.historyItems);

    double dayTotal = 0;
    double dayProfit = 0;
    for (var item in _filteredHistory) {
      if (item.status != "Refunded") {
        dayTotal += (item.price * item.qty);
        dayProfit += item.profit;
      }
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        controller: _scrollController,
        slivers: [
          // 1. Sleek App Bar
          SliverAppBar(
            expandedHeight: 180,
            floating: false,
            pinned: true,
            elevation: 0,
            backgroundColor: AppColors.primary,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: AppColors.primaryGradient,
                ),
                child: Padding(
                  padding: const EdgeInsets.only(top: 80, left: 24, right: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Sales History",
                        style: AppTextStyles.label.copyWith(color: Colors.white70),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Rs ${Formatter.formatCurrency(dayTotal)}",
                                style: AppTextStyles.h1.copyWith(color: Colors.white, fontSize: 28),
                              ),
                              Text(
                                "Profit: Rs ${Formatter.formatCurrency(dayProfit)}",
                                style: AppTextStyles.bodySmall.copyWith(color: Colors.white.withOpacity(0.8)),
                              ),
                            ],
                          ),
                          IconButton(
                            onPressed: () => ReportingService.generateSalesReport(
                              shopName: settingsProvider.shopName,
                              sales: _filteredHistory,
                              date: _selectedDate,
                            ),
                            icon: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(10)),
                              child: const Icon(Icons.picture_as_pdf, color: Colors.white),
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            onPressed: () async {
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: _selectedDate,
                                firstDate: DateTime(2022),
                                lastDate: DateTime.now(),
                                builder: (context, child) {
                                  return Theme(
                                    data: Theme.of(context).copyWith(
                                      colorScheme: const ColorScheme.light(
                                        primary: AppColors.primary,
                                        onPrimary: Colors.white,
                                        onSurface: AppColors.textPrimary,
                                      ),
                                    ),
                                    child: child!,
                                  );
                                },
                              );
                              if (picked != null) {
                                setState(() {
                                  _selectedDate = picked;
                                  _currentPage = 1;
                                });
                              }
                            },
                            icon: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(10)),
                              child: const Icon(Icons.calendar_month, color: Colors.white),
                            ),
                          )
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              title: Text(
                _formatDateManual(_selectedDate),
                style: AppTextStyles.h3.copyWith(color: Colors.white),
              ),
              centerTitle: false,
            ),
          ),

          // 2. Search & Filter Bar
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: TextField(
                controller: _searchController,
                onChanged: (val) => setState(() {
                  _searchQuery = val;
                  _currentPage = 1;
                }),
                decoration: InputDecoration(
                  hintText: "Search items or status...",
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                       IconButton(
                        icon: const Icon(Icons.document_scanner_outlined, color: Colors.indigo),
                        onPressed: _openTextScanner,
                        tooltip: "OCR Text Scan",
                      ),
                      IconButton(
                        icon: const Icon(Icons.qr_code_scanner, color: AppColors.primary),
                        onPressed: _openSearchScanner,
                        tooltip: "Barcode Scan",
                      ),
                    ],
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(vertical: 0),
                ),
              ),
            ),
          ),

          // 3. History List (Grouped)
          _displayedBillOrder.isEmpty
              ? SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.receipt_long_outlined, size: 64, color: Colors.grey[300]),
                        const SizedBox(height: 16),
                        const Text("No sales records found", style: TextStyle(color: Colors.grey)),
                      ],
                    ),
                  ),
                )
              : SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  sliver: AnimationLimiter(
                    child: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          if (index == _displayedBillOrder.length) {
                             return const Padding(
                               padding: EdgeInsets.symmetric(vertical: 20),
                               child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                             );
                          }

                          final billId = _displayedBillOrder[index];
                          final items = _groupedSales[billId]!;
                          return AnimationConfiguration.staggeredList(
                            position: index,
                            duration: const Duration(milliseconds: 375),
                            child: SlideAnimation(
                              verticalOffset: 50.0,
                              child: FadeInAnimation(
                                child: _BillCard(
                                  billId: billId,
                                  items: items,
                                  onRefund: (item) => _handleRefund(item),
                                  onDelete: (id) => _handleDelete(id),
                                  onEdit: (item) => _handleEdit(item),
                                ),
                              ),
                            ),
                          );
                        },
                        childCount: _displayedBillOrder.length + (_isLoadingMore ? 1 : 0),
                      ),
                    ),
                  ),
                ),
          
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }
}

class _BillCard extends StatelessWidget {
  final String billId;
  final List<SaleRecord> items;
  final Function(SaleRecord) onRefund;
  final Function(String) onDelete;
  final Function(SaleRecord) onEdit;

  const _BillCard({
    required this.billId,
    required this.items,
    required this.onRefund,
    required this.onDelete,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    double billTotal = 0;
    double billProfit = 0;
    int totalQty = 0;
    bool allRefunded = true;

    for (var item in items) {
      if (item.status != "Refunded") {
        billTotal += (item.price * item.qty);
        billProfit += item.profit;
        allRefunded = false;
      }
      totalQty += item.qty;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Theme(
          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            leading: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: allRefunded ? AppColors.error.withOpacity(0.1) : AppColors.secondary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                allRefunded ? Icons.keyboard_return : Icons.receipt_long_outlined,
                color: allRefunded ? AppColors.error : AppColors.secondary,
                size: 20,
              ),
            ),
            title: Row(
              children: [
                Expanded(
                  child: Text(
                    items.length > 1 ? "Multiple Items (${items.length})" : items.first.name,
                    style: AppTextStyles.bodyLarge.copyWith(
                      fontWeight: FontWeight.bold,
                      decoration: allRefunded ? TextDecoration.lineThrough : null,
                    ),
                  ),
                ),
                if (allRefunded)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(color: AppColors.error, borderRadius: BorderRadius.circular(5)),
                    child: const Text("REFUNDED", style: TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold)),
                  ),
              ],
            ),
            subtitle: Text(
              "Total Qty: $totalQty • ${_formatTime(items.first.date)}",
              style: AppTextStyles.bodySmall,
            ),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  "Rs ${Formatter.formatCurrency(billTotal)}",
                  style: AppTextStyles.bodyLarge.copyWith(
                    fontWeight: FontWeight.w900,
                    color: allRefunded ? AppColors.error : AppColors.primary,
                  ),
                ),
                if (!allRefunded)
                  Text(
                    billProfit >= 0 ? "+Rs ${Formatter.formatCurrency(billProfit)}" : "-Rs ${Formatter.formatCurrency(billProfit.abs())}",
                    style: AppTextStyles.label.copyWith(color: billProfit >= 0 ? AppColors.success : AppColors.error, fontSize: 10),
                  ),
              ],
            ),
            children: [
              const Divider(height: 1, color: Color(0xFFF1F5F9)),
              ...items.map((item) => _IndividualItemRow(
                item: item,
                onRefund: () => onRefund(item),
                onDelete: () => onDelete(item.id),
                onEdit: () => onEdit(item),
              )),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  String _formatTime(DateTime date) {
    return "${date.hour % 12 == 0 ? 12 : date.hour % 12}:${date.minute.toString().padLeft(2, '0')} ${date.hour >= 12 ? 'PM' : 'AM'}";
  }
}

class _IndividualItemRow extends StatelessWidget {
  final SaleRecord item;
  final VoidCallback onRefund;
  final VoidCallback onDelete;
  final VoidCallback onEdit;

  const _IndividualItemRow({
    required this.item,
    required this.onRefund,
    required this.onDelete,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    bool isRefunded = item.status == "Refunded";
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.name,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        decoration: isRefunded ? TextDecoration.lineThrough : null,
                        color: isRefunded ? Colors.grey : Colors.black87,
                      ),
                    ),
                    Text(
                      "${item.qty} x Rs ${Formatter.formatCurrency(item.price)}",
                      style: TextStyle(color: Colors.grey[600], fontSize: 11),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    "Rs ${Formatter.formatCurrency(item.price * item.qty)}",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isRefunded ? Colors.red : Colors.black,
                    ),
                  ),
                  if (!isRefunded)
                    Text(
                      "+Rs ${Formatter.formatCurrency(item.profit)}",
                      style: TextStyle(color: AppColors.success, fontSize: 10),
                    ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (!isRefunded)
                _SmallActionButton(icon: Icons.refresh, color: Colors.orange, onTap: onRefund),
              const SizedBox(width: 8),
              _SmallActionButton(icon: Icons.edit, color: Colors.blue, onTap: onEdit),
              const SizedBox(width: 8),
              _SmallActionButton(icon: Icons.delete_outline, color: Colors.red, onTap: onDelete),
            ],
          ),
          const Divider(height: 16, color: Color(0xFFF8FAFC)),
        ],
      ),
    );
  }
}

class _SmallActionButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _SmallActionButton({required this.icon, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: color, size: 16),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 4),
            Text(label, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}
