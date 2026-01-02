// lib/widgets/analysis_chart.dart
import 'package:flutter/material.dart';

class AnalysisChart extends StatelessWidget {
  const AnalysisChart({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        // Halka border taake background se alag lage
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          // 1. Header (Title & Profit)
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "BUSINESS ANALYSIS",
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      color: Colors.grey,
                      letterSpacing: 1.5,
                    ),
                  ),
                  Text(
                    "Monthly Summary",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    "NET PROFIT",
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                    ),
                  ),
                  Text(
                    "Rs 343,150",
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                      color: Colors.green,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),

          // 2. Graph Bars (W1, W2, W3, W4)
          SizedBox(
            height: 120, // Chart area ki height
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              crossAxisAlignment:
                  CrossAxisAlignment.end, // Bars neeche se shuru hon
              children: [
                _buildBarGroup("W1", 0.4, 0.2), // 40% Sale, 20% Kharcha
                _buildBarGroup("W2", 0.6, 0.3),
                _buildBarGroup("W3", 0.8, 0.4),
                _buildBarGroup("W4", 0.5, 0.25, isSelected: true), // Blue Text
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Helper: Ek hafte ke 2 bars (Green & Red)
  Widget _buildBarGroup(
    String label,
    double salePct,
    double expensePct, {
    bool isSelected = false,
  }) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        // Bars
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            // Green Bar (Sale)
            Container(
              width: 8,
              height: 80 * salePct, // 80px max height
              decoration: BoxDecoration(
                color: Colors.green,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 4),
            // Red Bar (Expense)
            Container(
              width: 8,
              height: 80 * expensePct,
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        // Label (W1, W2...)
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: isSelected ? Colors.blue : Colors.grey[300],
          ),
        ),
      ],
    );
  }
}
