// lib/screens/expense_screen.dart
import 'package:flutter/material.dart';
import '../widgets/add_expense_sheet.dart';

class ExpenseScreen extends StatefulWidget {
  const ExpenseScreen({super.key});

  @override
  State<ExpenseScreen> createState() => _ExpenseScreenState();
}

class _ExpenseScreenState extends State<ExpenseScreen> {
  // 1. STATE VARIABLE: Current Date (Default: Aaj ki tareekh)
  DateTime _selectedDate = DateTime.now();

  String _selectedCategory = "All";

  final List<Map<String, String>> _todayExpenses = [
    {"id": "1", "title": "Staff Lunch", "category": "Food", "amount": "Rs 850"},
    {
      "id": "2",
      "title": "Rickshaw Fare",
      "category": "Travel",
      "amount": "Rs 200",
    },
    {"id": "5", "title": "Chai Pani", "category": "Food", "amount": "Rs 150"},
  ];

  final List<Map<String, String>> _yesterdayExpenses = [
    {
      "id": "3",
      "title": "Electricity Bill",
      "category": "Bills",
      "amount": "Rs 4,500",
    },
    {
      "id": "4",
      "title": "Shop Rent",
      "category": "Rent",
      "amount": "Rs 35,000",
    },
  ];

  void _deleteItem(String id, bool isToday) {
    setState(() {
      if (isToday) {
        _todayExpenses.removeWhere((item) => item['id'] == id);
      } else {
        _yesterdayExpenses.removeWhere((item) => item['id'] == id);
      }
    });
  }

  List<Map<String, String>> _getFilteredList(
    List<Map<String, String>> originalList,
  ) {
    if (_selectedCategory == "All") {
      return originalList;
    } else {
      return originalList
          .where((item) => item['category'] == _selectedCategory)
          .toList();
    }
  }

  // === 2. CALENDAR PICKER LOGIC ===
  Future<void> _pickDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020), // 2020 se pehle nahi ja sakte
      lastDate: DateTime.now(), // Aaj ke baad nahi ja sakte
      builder: (context, child) {
        // Red Theme for Calendar
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Colors.red, // Header Color
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
      // User ko feedback diya
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Showing expenses for ${_getMonthName(picked.month)}"),
        ),
      );
    }
  }

  // Helper: Mahinay ka naam lene ke liye (1 -> JAN)
  String _getMonthName(int month) {
    const months = [
      "JAN",
      "FEB",
      "MAR",
      "APR",
      "MAY",
      "JUN",
      "JUL",
      "AUG",
      "SEP",
      "OCT",
      "NOV",
      "DEC",
    ];
    return months[month - 1];
  }

  @override
  Widget build(BuildContext context) {
    final filteredToday = _getFilteredList(_todayExpenses);
    final filteredYesterday = _getFilteredList(_yesterdayExpenses);

    // Dynamic Month Name
    String currentMonthName = _getMonthName(_selectedDate.month);
    String currentYear = _selectedDate.year.toString();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          "Expenses Manager",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.w900),
        ),
        actions: [
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.add, color: Colors.white, size: 20),
            ),
            onPressed: () {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.white,
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
                ),
                builder: (context) => const AddExpenseSheet(),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // === 3. UPDATED HEADER CARD (Clickable Calendar) ===
            Container(
              margin: const EdgeInsets.all(24),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFEF4444), Color(0xFF991B1B)],
                ),
                borderRadius: BorderRadius.circular(32),
                boxShadow: [
                  BoxShadow(
                    color: Colors.red.withOpacity(0.4),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Dynamic Date Text
                      Text(
                        "TOTAL SPENT ($currentMonthName $currentYear)",
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
                        ),
                      ),

                      // ALIVE CALENDAR ICON
                      GestureDetector(
                        onTap: _pickDate, // <--- Click Function
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.calendar_month,
                            color: Colors.white,
                            size: 18,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    "Rs 45,200",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 40,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),

            // CATEGORY FILTERS
            SizedBox(
              height: 40,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 24),
                children: [
                  _buildFilterChip("All"),
                  _buildFilterChip("Food"),
                  _buildFilterChip("Bills"),
                  _buildFilterChip("Rent"),
                  _buildFilterChip("Travel"),
                  _buildFilterChip("Extra"),
                ],
              ),
            ),
            const SizedBox(height: 30),

            // LISTS
            if (filteredToday.isNotEmpty) ...[
              _buildDateHeader("TODAY"),
              ...filteredToday.map((item) => _buildSwipeableItem(item, true)),
              const SizedBox(height: 20),
            ],

            if (filteredYesterday.isNotEmpty) ...[
              _buildDateHeader("YESTERDAY"),
              ...filteredYesterday.map(
                (item) => _buildSwipeableItem(item, false),
              ),
            ],

            if (filteredToday.isEmpty && filteredYesterday.isEmpty)
              Padding(
                padding: const EdgeInsets.all(40.0),
                child: Column(
                  children: [
                    Icon(
                      Icons.filter_list_off,
                      size: 50,
                      color: Colors.grey[300],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      "No expenses found",
                      style: TextStyle(color: Colors.grey[400]),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  // (Baqi helper functions same hain, unhein change karne ki zaroorat nahi)
  Widget _buildDateHeader(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
      child: Row(
        children: [
          Text(
            text,
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

  Widget _buildSwipeableItem(Map<String, String> item, bool isToday) {
    return Dismissible(
      key: Key(item['id']!),
      direction: DismissDirection.endToStart,
      confirmDismiss: (direction) async {
        return await showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: const Text(
                "Delete Expense?",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              content: const Text(
                "Kya aap waqai is Expenses ko delete karna chahte hain?",
              ),
              actions: <Widget>[
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text(
                    "Cancel",
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text(
                    "DELETE",
                    style: TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
      onDismissed: (direction) {
        _deleteItem(item['id']!, isToday);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Expense Deleted")));
      },
      background: Container(
        margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.red[100],
          borderRadius: BorderRadius.circular(20),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.delete, color: Colors.red),
      ),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
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
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.receipt_long,
                color: Colors.black,
                size: 18,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item['title']!,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    item['category']!,
                    style: const TextStyle(
                      color: Colors.grey,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              item['amount']!,
              style: const TextStyle(
                fontWeight: FontWeight.w900,
                color: Colors.red,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label) {
    bool isActive = _selectedCategory == label;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedCategory = label;
        });
      },
      child: Container(
        margin: const EdgeInsets.only(right: 10),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? Colors.black : Colors.white,
          borderRadius: BorderRadius.circular(30),
          border: isActive ? null : Border.all(color: Colors.grey.shade300),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: isActive ? Colors.white : Colors.black,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ),
      ),
    );
  }
}
