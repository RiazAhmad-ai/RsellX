// lib/features/dashboard/analysis_chart.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../shared/utils/formatting.dart';
import 'dart:math'; // Max value nikalne ke liye

class AnalysisChart extends StatefulWidget {
  final String title;
  // Ab hum pura data map pass karenge
  final Map<String, dynamic> chartData;

  const AnalysisChart({
    super.key,
    required this.title,
    required this.chartData, // <--- Changed
  });

  @override
  State<AnalysisChart> createState() => _AnalysisChartState();
}

class _AnalysisChartState extends State<AnalysisChart> {
  String _selectedView = "Sales";
  int? touchedIndex;
  int? _selectedIndex; // Persist selection on click

  @override
  Widget build(BuildContext context) {
    // Data nikalna
    List<String> labels = widget.chartData['labels'] ?? [];
    List<double> rawValues = widget.chartData[_selectedView] ?? [];

    // Graph ki height adjust karna (Normalization)
    double maxValue = rawValues.isEmpty ? 1 : rawValues.reduce(max);
    if (maxValue == 0) maxValue = 1;

    // Total Amount Calculate karna
    double totalSum = rawValues.fold(0, (p, c) => p + c);
    String totalAmountStr = "Rs ${Formatter.formatCurrency(totalSum)}";

    // CURRENT LOGIC: Touch ko priority dein, phir selected bar ko, phir total
    int? activeIndex = touchedIndex ?? _selectedIndex;

    String displayAmount = (activeIndex != null && activeIndex < rawValues.length)
        ? "Rs ${Formatter.formatCurrency(rawValues[activeIndex])}"
        : totalAmountStr;

    String displayLabel = (activeIndex != null && activeIndex < labels.length)
        ? "${labels[activeIndex]} ${_selectedView}"
        : "TOTAL ${_selectedView.toUpperCase()}";

    // Color Selection
    Color barColor = _selectedView == "Sales"
        ? Colors.blue
        : _selectedView == "Profit"
        ? Colors.green
        : Colors.red;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // === HEADER ===
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                widget.title.toUpperCase(),
                style: const TextStyle(
                  color: Colors.grey,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(width: 10),
              Flexible(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildToggleButton("Sales"),
                        _buildToggleButton("Profit"),
                        _buildToggleButton("Expenses"),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // === AMOUNT DISPLAY ===
          Text(
            displayAmount,
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w900,
              color: Colors.black,
            ),
          ),
          Text(
            displayLabel,
            style: const TextStyle(
              color: Colors.grey,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 30),

          // === BARS ===
          SizedBox(
            height: 180,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(rawValues.length, (index) {
                bool isTouched = touchedIndex == index;
                bool isSelected = _selectedIndex == index;
                bool isActive = isTouched || isSelected;

                // === REAL LOGIC ===
                double percentage = rawValues[index] / maxValue;
                double barHeight = 140 * percentage;
                if (barHeight < 5) barHeight = 5;

                return GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() {
                      if (_selectedIndex == index) {
                        _selectedIndex = null; // Unselect if already selected
                      } else {
                        _selectedIndex = index; // Select new
                      }
                    });
                  },
                  onTapDown: (_) => setState(() => touchedIndex = index),
                  onTapUp: (_) => setState(() => touchedIndex = null),
                  onPanEnd: (_) => setState(() => touchedIndex = null),
                  onLongPress: () {
                    HapticFeedback.lightImpact();
                    _showDayDetails(
                      labels[index],
                      widget.chartData['Sales'][index],
                      widget.chartData['Profit'][index],
                      widget.chartData['Expenses'][index],
                    );
                  },
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeOut,
                        width: isActive ? 16 : 12,
                        height: barHeight,
                        decoration: BoxDecoration(
                          color: isActive
                              ? barColor.withOpacity(1.0)
                              : barColor.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(8),
                          border: isSelected 
                              ? Border.all(color: Colors.black.withOpacity(0.2), width: 2)
                              : null,
                          gradient: isActive
                              ? LinearGradient(
                                  colors: [barColor, barColor.withOpacity(0.7)],
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                )
                              : null,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        index < labels.length ? labels[index] : "",
                        style: TextStyle(
                          color: isActive ? Colors.black : Colors.grey,
                          fontWeight: isActive
                              ? FontWeight.bold
                              : FontWeight.normal,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  // === NEW: DETAILED DIALOG ===
  void _showDayDetails(String label, double s, double p, double e) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          "$label Summary",
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildDetailRow("Total Sales", s, Colors.blue),
            const Divider(),
            _buildDetailRow("Net Profit", p, Colors.green),
            const Divider(),
            _buildDetailRow("Expenses", e, Colors.red),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: (p - e) >= 0 ? Colors.green[50] : Colors.red[50],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("Take Home:", style: TextStyle(fontWeight: FontWeight.bold)),
                  Text(
                    "Rs ${Formatter.formatCurrency(p - e)}",
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      color: (p - e) >= 0 ? Colors.green[700] : Colors.red[700],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("CLOSE", style: TextStyle(color: Colors.grey)),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, double value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Text(
            "Rs ${Formatter.formatCurrency(value)}",
            style: TextStyle(fontWeight: FontWeight.bold, color: color),
          ),
        ],
      ),
    );
  }

  Widget _buildToggleButton(String text) {
    bool isActive = _selectedView == text;
    return GestureDetector(
      onTap: () => setState(() {
        _selectedView = text;
        _selectedIndex = null; // View change hone par selection reset kar dein
      }),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 4,
                  ),
                ]
              : [],
        ),
        child: Text(
          text,
          style: TextStyle(
            color: isActive ? Colors.black : Colors.grey,
            fontWeight: FontWeight.bold,
            fontSize: 10,
          ),
        ),
      ),
    );
  }
}
