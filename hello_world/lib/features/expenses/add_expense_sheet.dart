// lib/features/expenses/add_expense_sheet.dart
import 'package:flutter/material.dart';
import '../../data/repositories/data_store.dart';

class AddExpenseSheet extends StatefulWidget {
  const AddExpenseSheet({super.key});

  @override
  State<AddExpenseSheet> createState() => _AddExpenseSheetState();
}

class _AddExpenseSheetState extends State<AddExpenseSheet> {
  String selectedCategory = "Food";
  final List<String> categories = ["Food", "Bills", "Rent", "Travel", "Extra"];

  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _descController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 24,
        right: 24,
        top: 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center, // Center Alignment
        children: [
          // Handle
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
            "ADD NEW EXPENSE",
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
              letterSpacing: 1,
            ),
          ),

          const SizedBox(height: 20),

          // === 1. BIG AMOUNT INPUT (Fixed Design) ===
          const Text(
            "Enter Amount",
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              const Text(
                "Rs",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                ),
              ),
              const SizedBox(width: 10),
              SizedBox(
                width: 150, // Fixed width
                child: TextFormField(
                  controller: _amountController,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center, // Beech mein likha jayega
                  autofocus: true, // Kholte hi keyboard aajaye
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 40,
                    color: Colors.black,
                  ),
                  decoration: const InputDecoration(
                    hintText: "0",
                    hintStyle: TextStyle(color: Colors.grey),
                    border: InputBorder.none, // Line hata di
                  ),
                ),
              ),
            ],
          ),

          const Divider(), // Patli line neeche
          const SizedBox(height: 20),

          // === 2. DESCRIPTION INPUT ===
          TextFormField(
            controller: _descController,
            decoration: InputDecoration(
              labelText: "Description (Details)",
              prefixIcon: const Icon(Icons.edit_note, color: Colors.grey),
              filled: true,
              fillColor: Colors.grey[50],
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 20),

          // === 3. CATEGORY CHIPS ===
          const Align(
            alignment: Alignment.centerLeft,
            child: Text(
              "SELECT CATEGORY",
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
          ),
          const SizedBox(height: 10),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: categories.map((cat) {
                bool isSelected = selectedCategory == cat;
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      selectedCategory = cat;
                    });
                  },
                  child: Container(
                    margin: const EdgeInsets.only(right: 10),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.red : Colors.grey[100],
                      borderRadius: BorderRadius.circular(20),
                      border: isSelected
                          ? null
                          : Border.all(color: Colors.grey.shade300),
                    ),
                    child: Text(
                      cat,
                      style: TextStyle(
                        color: isSelected ? Colors.white : Colors.black,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 30),

          // === 4. SAVE BUTTON ===
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                if (_amountController.text.isEmpty) {
                   ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Please enter amount!"),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }

                DataStore().addExpense({
                  "id": DateTime.now().millisecondsSinceEpoch.toString(),
                  "title": _descController.text.isEmpty ? selectedCategory : _descController.text,
                  "category": selectedCategory,
                  "amount": _amountController.text,
                }, isToday: true);

                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Expense Added!"),
                    backgroundColor: Colors.green,
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black, // Black button stylish lagta hai
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: const Text(
                "SAVE EXPENSE",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
