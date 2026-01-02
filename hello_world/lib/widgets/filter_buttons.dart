// lib/widgets/filter_buttons.dart
import 'package:flutter/material.dart';

class FilterButtons extends StatelessWidget {
  final String selectedFilter; // "Weekly", "Monthly", or "Annual"
  final Function(String) onFilterChanged; // Parent ko batane ke liye

  const FilterButtons({
    super.key,
    required this.selectedFilter,
    required this.onFilterChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildButton("Weekly"),
        _buildButton("Monthly"),
        _buildButton("Annual"),
      ],
    );
  }

  Widget _buildButton(String text) {
    bool isActive = selectedFilter == text;
    return GestureDetector(
      onTap: () => onFilterChanged(text), // Click hone par function call karo
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: isActive
            ? BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: const [
                  BoxShadow(color: Colors.black12, blurRadius: 5),
                ],
              )
            : null,
        child: Text(
          text,
          style: TextStyle(
            color: isActive ? Colors.black : Colors.grey,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
