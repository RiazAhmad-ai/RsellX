// lib/screens/history_screen.dart
import 'package:flutter/material.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  // 1. STATE VARIABLES
  DateTime _selectedDate = DateTime.now();
  String _searchQuery = "";

  // Dummy Data
  final List<Map<String, dynamic>> _historyItems = [
    {
      "id": "101",
      "item": "Bone China Cup Set",
      "qty": "2",
      "price": "4,500",
      "time": "10:30 AM",
      "date": "Today",
      "status": "Completed",
    },
    {
      "id": "102",
      "item": "Water Glass (6 Pcs)",
      "qty": "1",
      "price": "1,200",
      "time": "11:15 AM",
      "date": "Today",
      "status": "Completed",
    },
    {
      "id": "103",
      "item": "Tea Spoon Set",
      "qty": "3",
      "price": "850",
      "time": "04:45 PM",
      "date": "Yesterday",
      "status": "Refunded",
    },
    {
      "id": "104",
      "item": "Dinner Set (Large)",
      "qty": "1",
      "price": "12,000",
      "time": "06:00 PM",
      "date": "Yesterday",
      "status": "Completed",
    },
  ];

  // === FUNCTIONS ===

  // Delete Function
  void _deleteItem(String id) {
    setState(() {
      _historyItems.removeWhere((item) => item['id'] == id);
    });
  }

  // Calendar Picker
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Showing History for: ${_formatDate(picked)}")),
      );
    }
  }

  String _formatDate(DateTime date) {
    return "${date.day}/${date.month}/${date.year}";
  }

  // Edit Dialog
  void _showEditDialog(Map<String, dynamic> item) {
    TextEditingController priceController = TextEditingController(
      text: item['price'],
    );
    TextEditingController qtyController = TextEditingController(
      text: item['qty'],
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(
          "Edit Sale Record",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: qtyController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: "Quantity (Qty)",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: priceController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: "Price (Rs)",
                border: OutlineInputBorder(),
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
            onPressed: () {
              setState(() {
                item['price'] = priceController.text;
                item['qty'] = qtyController.text;
              });
              Navigator.pop(context);
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text("Record Updated!")));
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text("UPDATE", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // === UI BUILD ===
  @override
  Widget build(BuildContext context) {
    final filteredList = _historyItems.where((item) {
      return item['item'].toString().toLowerCase().contains(
        _searchQuery.toLowerCase(),
      );
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          "Sales History",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.w900),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_month, color: Colors.black),
            onPressed: _pickDate,
          ),
          const SizedBox(width: 10),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: TextField(
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
              decoration: InputDecoration(
                hintText: "Search receipt or item...",
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

          // List
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: filteredList.length,
              itemBuilder: (context, index) {
                final item = filteredList[index];

                bool showHeader = true;
                if (index > 0 &&
                    filteredList[index - 1]['date'] == item['date']) {
                  showHeader = false;
                }

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (showHeader) _buildDateHeader(item['date']),
                    _buildHistoryCard(item),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // Helper Widgets
  Widget _buildDateHeader(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Text(
            text.toUpperCase(),
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w900,
              color: Colors.grey,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(child: Divider(color: Colors.grey[300])),
        ],
      ),
    );
  }

  Widget _buildHistoryCard(Map<String, dynamic> item) {
    bool isRefund = item['status'] == "Refunded";

    return Dismissible(
      key: Key(item['id']),
      direction: DismissDirection.endToStart,
      confirmDismiss: (direction) async {
        return await showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text("Delete Record?"),
            content: const Text(
              "Kya aap is sale record ko delete karna chahte hain?",
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
                  style: TextStyle(color: Colors.red),
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
        // === STACK IMPLEMENTATION (For Corner Ribbon) ===
        child: Stack(
          children: [
            // 1. Content Row
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
                          item['item'],
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 4),
                        // Wrap hata diya, simple Row text
                        Text(
                          "${item['qty']} x Items   •   ${item['time']}",
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),

                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        "Rs ${item['price']}",
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 16,
                          color: isRefund ? Colors.red : Colors.black,
                        ),
                      ),
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
                                      Icons.edit,
                                      color: Colors.blue,
                                    ),
                                    title: const Text("Edit Record"),
                                    onTap: () {
                                      Navigator.pop(context);
                                      _showEditDialog(item);
                                    },
                                  ),
                                  ListTile(
                                    leading: const Icon(
                                      Icons.keyboard_return,
                                      color: Colors.orange,
                                    ),
                                    title: const Text("Mark as Refund (Wapis)"),
                                    onTap: () {
                                      setState(() {
                                        item['status'] = "Refunded";
                                      });
                                      Navigator.pop(context);
                                    },
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                        child: const Padding(
                          padding: EdgeInsets.only(top: 8, left: 10, bottom: 5),
                          child: Icon(Icons.more_horiz, color: Colors.grey),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // 2. Refund Ribbon (Top Left Corner)
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
                    "REFUND",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1,
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
