// lib/features/expenses/expense_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:rsellx/providers/expense_provider.dart';
import 'package:rsellx/providers/settings_provider.dart';
import 'add_expense_sheet.dart';
import '../../data/models/expense_model.dart';
import '../../shared/utils/formatting.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/services/reporting_service.dart';
import '../../core/utils/debouncer.dart';

class ExpenseScreen extends StatefulWidget {
  const ExpenseScreen({super.key});

  @override
  State<ExpenseScreen> createState() => _ExpenseScreenState();
}

class _ExpenseScreenState extends State<ExpenseScreen> {
  // 1. STATE VARIABLES
  DateTime _selectedDate = DateTime.now(); // By default Aaj ki date
  String _selectedCategory = "All";
  final List<String> categories = ["Food", "Bills", "Rent", "Travel", "Extra"];
  
  // Search functionality
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";
  final Debouncer _searchDebouncer = Debouncer(milliseconds: 300);

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchDebouncer.dispose();
    super.dispose();
  }

  // === FUNCTIONS ===

  void _deleteItem(String id) {
    context.read<ExpenseProvider>().deleteExpense(id);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Expense Deleted"),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // === EDIT FEATURE ===
  void _showEditSheet(ExpenseItem item) {
    TextEditingController amountController = TextEditingController(
      text: item.amount.toString(),
    );
    TextEditingController titleController = TextEditingController(
      text: item.title,
    );
    String currentCategory = item.category;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                left: 24,
                right: 24,
                top: 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    "EDIT EXPENSE",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        "Rs",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                      ),
                      const SizedBox(width: 10),
                      SizedBox(
                        width: 150,
                        child: TextFormField(
                          controller: amountController,
                          keyboardType: TextInputType.number,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 40,
                          ),
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const Divider(),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: titleController,
                    decoration: InputDecoration(
                      labelText: "Description",
                      prefixIcon: const Icon(
                        Icons.edit_note,
                        color: Colors.grey,
                      ),
                      filled: true,
                      fillColor: Colors.grey[50],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: categories.map((cat) {
                        bool isSelected = currentCategory == cat;
                        return GestureDetector(
                          onTap: () =>
                              setModalState(() => currentCategory = cat),
                          child: Container(
                            margin: const EdgeInsets.only(right: 10),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? Colors.blue
                                  : Colors.grey[100],
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              cat,
                              style: TextStyle(
                                color: isSelected ? Colors.white : Colors.black,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 30),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        item.amount = double.tryParse(amountController.text) ?? item.amount;
                        item.title = titleController.text;
                        item.category = currentCategory;

                        context.read<ExpenseProvider>().updateExpense(item);
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text("Expense Updated!"),
                            backgroundColor: AppColors.accent,
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        padding: const EdgeInsets.symmetric(vertical: 18),
                      ),
                      child: const Text(
                        "UPDATE EXPENSE",
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
            );
          },
        );
      },
    );
  }

  // === FILTERING ===
  List<ExpenseItem> _getFilteredList(List<ExpenseItem> originalList) {
    var filtered = originalList;
    
    // Filter by category
    if (_selectedCategory != "All") {
      filtered = filtered.where((item) => item.category == _selectedCategory).toList();
    }
    
    // Filter by search query
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      filtered = filtered.where((item) {
        return item.title.toLowerCase().contains(query) ||
               item.category.toLowerCase().contains(query);
      }).toList();
    }
    
    return filtered;
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

  String _formatDate(DateTime date) {
    return "${date.day}/${date.month}/${date.year}";
  }

  @override
  Widget build(BuildContext context) {
    final expenseProvider = context.watch<ExpenseProvider>();
    final settingsProvider = context.watch<SettingsProvider>();
    final isVisible = settingsProvider.isBalanceVisible;
    
    // 1. Get Data for SELECTED DATE ONLY
    final expensesForDate = expenseProvider.getExpensesForDate(_selectedDate);
    final filteredList = _getFilteredList(expensesForDate);
    final totalSpent = expenseProvider.getTotalExpensesForDate(_selectedDate);

    String displayDate = _formatDate(_selectedDate);
    bool isToday = _formatDate(DateTime.now()) == displayDate;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          "Expenses Manager",
          style: AppTextStyles.h2,
        ),
        actions: [
          IconButton(
            onPressed: () async {
              try {
                await ReportingService.generateExpenseReport(
                  shopName: settingsProvider.shopName,
                  expenses: _getFilteredList(expenseProvider.getExpensesForDate(_selectedDate)),
                  date: _selectedDate,
                );
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Failed to generate PDF: $e'),
                      backgroundColor: AppColors.error,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              }
            },
            icon: const Icon(Icons.picture_as_pdf, color: AppColors.accent),
          ),
          IconButton(
            onPressed: _pickDate,
            icon: const Icon(Icons.calendar_month, color: AppColors.accent),
          ),
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
      body: RefreshIndicator(
        onRefresh: () async {
          // Reset to today's date when refreshed
          setState(() {
            _selectedDate = DateTime.now();
          });
          
          // Show feedback to user
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Refreshed to Today's Date"),
              backgroundColor: AppColors.accent,
              behavior: SnackBarBehavior.floating,
              duration: Duration(seconds: 1),
            ),
          );
        },
        color: AppColors.accent,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(), // Important for pull to refresh
          child: Column(
            children: [
              // 1. PREMIUM DASHBOARD HEADER
            Container(
              margin: const EdgeInsets.all(24),
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF2D3436), Color(0xFF000000)], // Sleek Dark Design or keep Red if you prefer
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(35),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x33000000), // 0.2 opacity black
                    blurRadius: 25,
                    offset: Offset(0, 15),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(35),
                child: Stack(
                  children: [
                    // Decorative Background Circle
                    Positioned(
                      right: -50,
                      top: -50,
                      child: Container(
                        width: 200,
                        height: 200,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Color(0x26FF0000), // 0.15 opacity red
                        ),
                      ),
                    ),
                    
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // PERIOD STATS (Today, Weekly, Monthly, Annual)
                          Row(
                            children: [
                              _buildGlassStat(
                                label: isToday ? "TODAY" : "SELECTED",
                                subtitle: DateFormat('MMM d, yyyy').format(_selectedDate),
                                amount: expenseProvider.getTotalExpensesForDate(_selectedDate),
                                icon: Icons.bolt_rounded,
                                color: Colors.blueAccent,
                                onLongPress: () => _showDetailedReport(context, "DAILY REPORT", expenseProvider.getExpensesForDate(_selectedDate), expenseProvider.getTotalExpensesForDate(_selectedDate), Colors.blue, isVisible),
                              ),
                              const SizedBox(width: 12),
                              _buildGlassStat(
                                label: "WEEKLY",
                                subtitle: "${DateFormat('MMM d').format(_selectedDate.subtract(Duration(days: _selectedDate.weekday - 1)))} - ${DateFormat('MMM d').format(_selectedDate.subtract(Duration(days: _selectedDate.weekday - 1)).add(const Duration(days: 6)))}",
                                amount: expenseProvider.getTotalExpensesForWeek(_selectedDate),
                                icon: Icons.auto_graph_rounded,
                                color: Colors.orangeAccent,
                                onLongPress: () => _showDetailedReport(context, "WEEKLY REPORT", expenseProvider.getExpensesForWeek(_selectedDate), expenseProvider.getTotalExpensesForWeek(_selectedDate), Colors.orange, isVisible),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              _buildGlassStat(
                                label: "MONTHLY",
                                subtitle: DateFormat('MMMM yyyy').format(_selectedDate),
                                amount: expenseProvider.getTotalExpensesForMonth(_selectedDate),
                                icon: Icons.calendar_month_rounded,
                                color: Colors.greenAccent,
                                onLongPress: () => _showDetailedReport(context, "MONTHLY REPORT", expenseProvider.getExpensesForMonth(_selectedDate), expenseProvider.getTotalExpensesForMonth(_selectedDate), Colors.green, isVisible),
                              ),
                              const SizedBox(width: 12),
                              _buildGlassStat(
                                label: "ANNUAL",
                                subtitle: DateFormat('yyyy').format(_selectedDate),
                                amount: expenseProvider.getTotalExpensesForYear(_selectedDate),
                                icon: Icons.account_balance_wallet_rounded,
                                color: Colors.purpleAccent,
                                onLongPress: () => _showDetailedReport(context, "ANNUAL REPORT", expenseProvider.getExpensesForYear(_selectedDate), expenseProvider.getTotalExpensesForYear(_selectedDate), Colors.purple, isVisible),
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

            // SEARCH BAR
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              child: TextField(
                controller: _searchController,
                onChanged: (val) {
                  _searchDebouncer.run(() {
                    if (mounted) {
                      setState(() {
                        _searchQuery = val;
                      });
                    }
                  });
                },
                decoration: InputDecoration(
                  hintText: "Search expenses...",
                  hintStyle: TextStyle(color: Colors.grey.shade400),
                  prefixIcon: const Icon(Icons.search, color: AppColors.accent),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, color: Colors.grey),
                          onPressed: () {
                            setState(() {
                              _searchController.clear();
                              _searchQuery = "";
                            });
                          },
                        )
                      : null,
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

            // FILTERS
            SizedBox(
              height: 40,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 24),
                children: [
                  "All",
                  "Food",
                  "Bills",
                  "Rent",
                  "Travel",
                  "Extra",
                ].map((cat) => _buildFilterChip(cat)).toList(),
              ),
            ),
            const SizedBox(height: 30),

            // LIST (Single List based on Date)
            if (filteredList.isNotEmpty) ...[
              _buildDateHeader(isToday ? "TODAY" : displayDate),
              ...filteredList.map((item) => _buildSwipeableItem(item, isVisible)),
              const SizedBox(height: 80),
            ] else
              Padding(
                padding: const EdgeInsets.all(40.0),
                child: Column(
                  children: [
                    Icon(Icons.event_busy, size: 50, color: Colors.grey[300]),
                    const SizedBox(height: 10),
                    Text(
                      "No expenses for $displayDate",
                      style: TextStyle(color: Colors.grey[400]),
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

  Widget _buildSwipeableItem(ExpenseItem item, bool isVisible) {
    return Dismissible(
      key: Key(item.id),
      direction: DismissDirection.endToStart,
      confirmDismiss: (direction) async {
        return await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Text("Delete Expense?", style: AppTextStyles.h3),
            content: const Text("Are you sure you want to delete this expense?"),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text("Cancel", style: TextStyle(color: AppColors.textSecondary)),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text("DELETE", style: TextStyle(color: AppColors.error, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        );
      },
      onDismissed: (_) => _deleteItem(item.id),
      background: Container(
        margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0x1AEF4444), // AppColors.error 0.1 opacity
          borderRadius: BorderRadius.circular(20),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.delete_outline, color: AppColors.error),
      ),
      child: GestureDetector(
        onTap: () => _showEditSheet(item),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: const [
              BoxShadow(
                color: Color(0x0A000000), // 0.04 opacity black
                blurRadius: 10,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: const BoxDecoration(
                  color: Color(0x1A3B82F6), // AppColors.accent 0.1 opacity
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.edit_note, color: AppColors.accent, size: 20),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      item.category,
                      style: AppTextStyles.label,
                    ),
                  ],
                ),
              ),
              Text(
                "Rs ${isVisible ? Formatter.formatCurrency(item.amount) : '••••'}",
                style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.w900, color: AppColors.error),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label) {
    bool isActive = _selectedCategory == label;
    return GestureDetector(
      onTap: () => setState(() => _selectedCategory = label),
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

  Widget _buildGlassStat({
    required String label,
    required String subtitle,
    required double amount,
    required IconData icon,
    required Color color,
    VoidCallback? onLongPress,
  }) {
    final isVisible = Provider.of<SettingsProvider>(context, listen: false).isBalanceVisible;
    return Expanded(
      child: GestureDetector(
        onLongPress: onLongPress,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 12),
          decoration: BoxDecoration(
            color: const Color(0x14FFFFFF), // 0.08 opacity white
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0x1FFFFFFF)), // 0.12 opacity white
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 16),
              ),
              const SizedBox(height: 12),
              Text(
                label,
                style: const TextStyle(
                  color: Color(0x80FFFFFF), // 0.5 opacity white
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(
                  color: Color(0xB3FFFFFF), // 0.7 opacity white
                  fontSize: 8,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              FittedBox(
                child: Text(
                  isVisible ? "Rs ${Formatter.formatCurrency(amount)}" : "Rs •••••",
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // === UNIVERSAL DETAILED REPORT DIALOG ===
  void _showDetailedReport(BuildContext context, String title, List<ExpenseItem> items, double total, Color themeColor, bool isVisible) {
    // Group by category for the report
    Map<String, double> categoryTotals = {};
    for (var e in items) {
      categoryTotals[e.category] = (categoryTotals[e.category] ?? 0) + e.amount;
    }

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        backgroundColor: Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: themeColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.assessment_rounded, color: themeColor, size: 30),
              ),
              const SizedBox(height: 16),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "Total Spent: ${isVisible ? 'Rs ${Formatter.formatCurrency(total)}' : 'Rs •••••••'}",
                style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 24),
              
              // Category Breakdown List
              if (categoryTotals.isEmpty)
                 const Text("No expenses recorded for this period.")
              else
                Flexible(
                  child: SingleChildScrollView(
                    child: Column(
                      children: categoryTotals.entries.map((entry) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(color: themeColor, shape: BoxShape.circle),
                                ),
                                const SizedBox(width: 10),
                                Text(entry.key, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                              ],
                            ),
                            Text(
                              "Rs ${Formatter.formatCurrency(entry.value)}",
                              style: const TextStyle(fontWeight: FontWeight.w900, color: Colors.black87),
                            ),
                          ],
                        ),
                      )).toList(),
                    ),
                  ),
                ),
              
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 16),
              
              // Close Button
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    backgroundColor: Colors.black,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  ),
                  child: const Text("CLOSE", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
