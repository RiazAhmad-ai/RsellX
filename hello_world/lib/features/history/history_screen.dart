// lib/features/history/history_screen.dart
import 'package:flutter/material.dart';
import '../../data/repositories/data_store.dart';
import '../../shared/utils/formatting.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  DateTime _selectedDate = DateTime.now();
  String _searchQuery = "";

  @override
  void initState() {
    super.initState();
    DataStore().addListener(_onDataChange);
  }

  @override
  void dispose() {
    DataStore().removeListener(_onDataChange);
    super.dispose();
  }

  void _onDataChange() {
    if (mounted) setState(() {});
  }

  // === ACTIONS ===
  void _deleteItem(String id) {
    DataStore().deleteHistoryItem(id);
  }

  // NEW REFUND LOGIC CALL
  void _markAsRefund(Map<String, dynamic> item) {
    DataStore().refundSale(
      item,
    ); // <--- Restores stock and corrects calculations
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Refund Successful! Stock Restored.")),
    );
  }

  void _showEditHistoryDialog(Map<String, dynamic> item) {
    final nameCtrl = TextEditingController(text: item['name'] ?? item['item'] ?? "");
    final priceCtrl = TextEditingController(text: item['price']?.toString() ?? "0");
    final qtyCtrl = TextEditingController(text: (item['qty'] ?? 1).toString());

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Edit History Record"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(labelText: "Item Name"),
            ),
            TextField(
              controller: priceCtrl,
              decoration: const InputDecoration(labelText: "Sale Price"),
              keyboardType: TextInputType.number,
            ),
            TextField(
              controller: qtyCtrl,
              decoration: const InputDecoration(labelText: "Quantity"),
              keyboardType: TextInputType.number,
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
              DataStore().updateHistoryItem(item, {
                'name': nameCtrl.text,
                'price': priceCtrl.text,
                'qty': qtyCtrl.text,
              });
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Record Updated Successfully! ✅")),
              );
            },
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }

  Future<void> _pickDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Colors.red,
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  DateTime _parseDate(dynamic dateVal) {
    if (dateVal == null) return DateTime.now();
    if (dateVal is DateTime) return dateVal;
    return DateTime.tryParse(dateVal.toString()) ?? DateTime.now();
  }

  bool _isSameDay(DateTime d1, DateTime d2) {
    return d1.year == d2.year && d1.month == d2.month && d1.day == d2.day;
  }

  @override
  Widget build(BuildContext context) {
    final filteredList = DataStore().historyItems.where((item) {
      DateTime itemDate = _parseDate(item['date']);
      bool dateMatches = _isSameDay(itemDate, _selectedDate);
      final name = item['name'] ?? item['item'] ?? "";
      bool searchMatches = name.toString().toLowerCase().contains(
        _searchQuery.toLowerCase(),
      );
      return dateMatches && searchMatches;
    }).toList();

    String displayDate =
        "${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}";

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Sales History",
              style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.w900,
                fontSize: 18,
              ),
            ),
            Text(
              "Showing: $displayDate",
              style: const TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_month, color: Colors.red),
            onPressed: _pickDate,
          ),
          const SizedBox(width: 10),
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: TextField(
              onChanged: (value) => setState(() => _searchQuery = value),
              decoration: InputDecoration(
                hintText: "Search item name...",
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                filled: true,
                fillColor: Colors.grey[100],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          Expanded(
            child: filteredList.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.history_toggle_off,
                          size: 80,
                          color: Colors.grey[300],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          "No history available for this date.",
                          style: TextStyle(
                            color: Colors.grey[500],
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: filteredList.length,
                    itemBuilder: (context, index) =>
                        _buildHistoryCard(filteredList[index], _selectedDate),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryCard(Map<String, dynamic> item, DateTime dt) {
    bool isRefund = item['status'] == "Refunded";
    String itemName = item['name'] ?? item['item'] ?? "Unknown Item";
    String qty = item['qty']?.toString() ?? "1";
    String price = item['price']?.toString() ?? "0";
    String profit = item['profit']?.toString() ?? "0";

    DateTime itemTime = _parseDate(item['date']);
    String timeStr =
        "${itemTime.hour}:${itemTime.minute.toString().padLeft(2, '0')}";

    return Dismissible(
      key: Key(item['id'] ?? DateTime.now().toString()),
      direction: DismissDirection.endToStart,
      confirmDismiss: (direction) async {
        return await showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text("Delete Record?"),
            content: const Text(
              "Deleting this record will not restore stock. Only the record will be removed.",
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text("Cancel"),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text(
                  "DELETE",
                  style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        );
      },
      onDismissed: (direction) => _deleteItem(item['id']),
      background: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.red[100],
          borderRadius: BorderRadius.circular(16),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.delete, color: Colors.red),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: isRefund
              ? Border.all(color: Colors.red.withOpacity(0.3))
              : null,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: isRefund ? Colors.red[50] : Colors.green[50],
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isRefund ? Icons.keyboard_return : Icons.check,
                      color: isRefund ? Colors.red : Colors.green,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          itemName,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "$qty x Items   •   $timeStr",
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 12,
                          ),
                        ),
                        if (!isRefund &&
                            double.tryParse(profit) != null &&
                            double.parse(profit) != 0)
                          Text(
                            "Profit: Rs $profit",
                            style: TextStyle(
                              color: Colors.green[700],
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        "Rs $price",
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 16,
                          color: isRefund ? Colors.red : Colors.black,
                          decoration: isRefund
                              ? TextDecoration.lineThrough
                              : null,
                        ),
                      ),
                      if (!isRefund)
                        GestureDetector(
                          onTap: () {
                            showModalBottomSheet(
                              context: context,
                              builder: (context) => Container(
                                padding: const EdgeInsets.all(20),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    ListTile(
                                      leading: const Icon(
                                        Icons.keyboard_return,
                                        color: Colors.orange,
                                      ),
                                      title: const Text(
                                        "Mark as Refund (Restore Stock)",
                                      ),
                                      onTap: () {
                                        Navigator.pop(context);
                                        _markAsRefund(
                                          item,
                                        ); // <--- Call new function
                                      },
                                    ),
                                    ListTile(
                                      leading: const Icon(
                                        Icons.edit,
                                        color: Colors.blue,
                                      ),
                                      title: const Text("Edit Record"),
                                      onTap: () {
                                        Navigator.pop(context);
                                        _showEditHistoryDialog(item);
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                          child: const Padding(
                            padding: EdgeInsets.only(
                              top: 8,
                              left: 10,
                              bottom: 5,
                            ),
                            child: Icon(Icons.more_horiz, color: Colors.grey),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            if (isRefund)
              Positioned(
                top: 0,
                left: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(16),
                      bottomRight: Radius.circular(10),
                    ),
                  ),
                  child: const Text(
                    "REFUNDED",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
