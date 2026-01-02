// lib/widgets/filter_buttons.dart
import 'package:flutter/material.dart';

class FilterButtons extends StatelessWidget {
  const FilterButtons({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildButton("Weekly", false),
        _buildButton("Monthly", true), // Active
        _buildButton("Annual", false),
      ],
    );
  }

  // Private helper method taake code repeat na ho
  Widget _buildButton(String text, bool isActive) {
    return Container(
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
    );
  }
}
