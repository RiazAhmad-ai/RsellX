// lib/widgets/expense_section.dart
import 'package:flutter/material.dart';

class ExpenseSection extends StatelessWidget {
  const ExpenseSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Header (Title aur Add Button)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "RECENT Expenses",
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  color: Colors.grey,
                  letterSpacing: 1.5,
                ),
              ),
              // Add Button
              GestureDetector(
                onTap: () {
                  // Yahan baad mein Expense Add form khul sakta hai
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.red[50],
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    "ADD +",
                    style: TextStyle(
                      color: Colors.red,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // 2. Expense List Items
          _buildExpenseItem("Electricity Bill", "Yesterday", "Rs 4,500"),

          // Beech mein halki line
          Divider(height: 24, color: Colors.grey[100]),

          _buildExpenseItem("Staff Lunch", "Today", "Rs 850"),
        ],
      ),
    );
  }

  // Helper Widget taake code baar baar na likhna pade
  Widget _buildExpenseItem(String title, String date, String amount) {
    return Row(
      children: [
        // Icon Circle
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.red[50],
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.receipt_long, color: Colors.red, size: 20),
        ),
        const SizedBox(width: 16),

        // Name & Date
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
                date,
                style: const TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ],
          ),
        ),

        // Amount (Red Color)
        Text(
          amount,
          style: const TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 14,
            color: Colors.red,
          ),
        ),
      ],
    );
  }
}
