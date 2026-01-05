// lib/features/history/history_screen.dart
import 'package:flutter/material.dart';
import '../../data/repositories/data_store.dart';
import '../../data/models/sale_model.dart';
import '../../shared/utils/formatting.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/services/reporting_service.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  DateTime _selectedDate = DateTime.now();
  String _searchQuery = "";
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    DataStore().addListener(_onDataChange);
  }

  @override
  void dispose() {
    DataStore().removeListener(_onDataChange);
    _searchController.dispose();
    super.dispose();
  }

  void _onDataChange() {
    if (mounted) setState(() {});
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
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text("Process Refund", style: AppTextStyles.h2),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text("How many items do you want to refund?"),
              const SizedBox(height: 20),
              if (totalQty > 1)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.remove_circle_outline, color: AppColors.error),
                      onPressed: refundQty > 1 ? () => setDialogState(() => refundQty--) : null,
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Text("$refundQty", style: AppTextStyles.h1),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add_circle_outline, color: AppColors.success),
                      onPressed: refundQty < totalQty ? () => setDialogState(() => refundQty++) : null,
                    ),
                  ],
                )
              else
                Text("1 Item (Full Refund)", style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.bold)),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text("Cancel", style: TextStyle(color: AppColors.textSecondary)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.warning,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () {
                DataStore().refundSale(item, refundQty: refundQty);
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text("Refund of $refundQty item(s) processed! ✅"),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
              child: const Text("CONFIRM REFUND", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  void _handleDelete(String id) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text("Delete Record?", style: AppTextStyles.h3),
        content: const Text("Are you sure? This will remove the record permanently but will NOT restore stock."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text("Keep", style: TextStyle(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () {
              DataStore().deleteHistoryItem(id);
              Navigator.pop(ctx);
            },
            child: const Text("DELETE", style: TextStyle(color: AppColors.error, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _handleEdit(SaleRecord item) {
    final nameCtrl = TextEditingController(text: item.name);
    final priceCtrl = TextEditingController(text: item.price.toString());
    final qtyCtrl = TextEditingController(text: item.qty.toString());

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text("Edit Sale Record", style: AppTextStyles.h3),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: "Item Name")),
            TextField(controller: priceCtrl, decoration: const InputDecoration(labelText: "Sale Price"), keyboardType: TextInputType.number),
            TextField(controller: qtyCtrl, decoration: const InputDecoration(labelText: "Quantity"), keyboardType: TextInputType.number),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Cancel", style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accent,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () {
              final updatedSale = SaleRecord(
                id: item.id,
                itemId: item.itemId,
                name: nameCtrl.text,
                price: double.tryParse(priceCtrl.text) ?? item.price,
                actualPrice: item.actualPrice,
                qty: int.tryParse(qtyCtrl.text) ?? item.qty,
                profit: 0, // Recalculated in DataStore
                date: item.date,
                status: item.status,
              );
              DataStore().updateHistoryItem(item, updatedSale);
              Navigator.pop(context);
            },
            child: const Text("Save", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final allHistory = DataStore().historyItems;
    
    // Filter logic
    // Filter logic
    final filteredHistory = allHistory.where((item) {
      final matchesDate = _isSameDay(item.date, _selectedDate);
      
      final name = item.name.toLowerCase();
      final status = item.status.toLowerCase();
      final matchesSearch = name.contains(_searchQuery.toLowerCase()) || 
                            status.contains(_searchQuery.toLowerCase());
      
      return matchesDate && matchesSearch;
    }).toList();

    // Summary calculations
    double dayTotal = 0;
    double dayProfit = 0;
    for (var item in filteredHistory) {
      if (item.status != "Refunded") {
        dayTotal += (item.price * item.qty);
        dayProfit += item.profit;
      }
    }

    // Grouping by Bill ID
    final Map<String, List<SaleRecord>> groupedSales = {};
    final List<String> billOrder = [];

    for (var item in filteredHistory) {
      final key = item.billId ?? item.id;
      if (!groupedSales.containsKey(key)) {
        groupedSales[key] = [];
        billOrder.add(key);
      }
      groupedSales[key]!.add(item);
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
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
                              shopName: DataStore().shopName,
                              sales: filteredHistory,
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
                              if (picked != null) setState(() => _selectedDate = picked);
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
                onChanged: (v) => setState(() => _searchQuery = v),
                decoration: InputDecoration(
                  hintText: "Search items or status...",
                  prefixIcon: const Icon(Icons.search),
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
          billOrder.isEmpty
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
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final billId = billOrder[index];
                        final items = groupedSales[billId]!;
                        return _BillCard(
                          billId: billId,
                          items: items,
                          onRefund: (item) => _handleRefund(item),
                          onDelete: (id) => _handleDelete(id),
                          onEdit: (item) => _handleEdit(item),
                        );
                      },
                      childCount: billOrder.length,
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
