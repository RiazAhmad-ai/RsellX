// lib/features/dashboard/analysis_chart.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../shared/utils/formatting.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import 'dart:math'; 

class AnalysisChart extends StatefulWidget {
  final String title;
  final Map<String, dynamic> chartData;

  const AnalysisChart({
    super.key,
    required this.title,
    required this.chartData, 
  });

  @override
  State<AnalysisChart> createState() => _AnalysisChartState();
}

class _AnalysisChartState extends State<AnalysisChart> {
  String _selectedView = "Sales";
  int? touchedIndex;
  int? _selectedIndex; 

  @override
  Widget build(BuildContext context) {
    List<String> labels = widget.chartData['labels'] ?? [];
    List<double> rawValues = List<double>.from(widget.chartData[_selectedView] ?? []);

    double maxValue = rawValues.isEmpty ? 1.0 : rawValues.reduce(max);
    if (maxValue < 1.0) maxValue = 1.0; // Ensure positive divisor and handle losses

    double totalSum = rawValues.fold(0, (p, c) => p + c);
    String totalAmountStr = "Rs ${Formatter.formatCurrency(totalSum)}";

    int? activeIndex = touchedIndex ?? _selectedIndex;

    String displayAmount = (activeIndex != null && activeIndex < rawValues.length)
        ? "Rs ${Formatter.formatCurrency(rawValues[activeIndex])}"
        : totalAmountStr;

    String displayLabel = (activeIndex != null && activeIndex < labels.length)
        ? "${labels[activeIndex]} ${_selectedView}"
        : "TOTAL ${_selectedView.toUpperCase()}";

    Color barColor = _selectedView == "Sales"
        ? AppColors.accent
        : _selectedView == "Profit"
        ? AppColors.success
        : _selectedView == "Expenses"
        ? AppColors.error
        : Colors.orange;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 24,
            offset: const Offset(0, 12),
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
                style: AppTextStyles.label.copyWith(
                  color: Colors.grey[400],
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.2,
                  fontSize: 10,
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.grey[100]!),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildToggleButton("Sales"),
                        _buildToggleButton("Profit"),
                        _buildToggleButton("Expenses"),
                        _buildToggleButton("Damage"),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // === AMOUNT DISPLAY ===
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: Text(
                  displayAmount,
                  key: ValueKey(displayAmount),
                  style: AppTextStyles.h1.copyWith(fontSize: 28, letterSpacing: -0.5),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                displayLabel,
                style: AppTextStyles.label.copyWith(color: Colors.grey, fontSize: 11),
              ),
            ],
          ),
          const SizedBox(height: 32),

          // === BARS ===
          SizedBox(
            height: 180, // Increased from 160
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(rawValues.length, (index) {
                bool isTouched = touchedIndex == index;
                bool isSelected = _selectedIndex == index;
                bool isActive = isTouched || isSelected;

                double percentage = (rawValues[index] / maxValue).clamp(0.0, 1.0);
                double barHeight = (130.0 * percentage).clamp(5.0, 130.0);

                return AnimatedKeyedBar(
                  key: ValueKey("bar_${_selectedView}_$index"),
                  barHeight: barHeight,
                  barColor: barColor,
                  isActive: isActive,
                  label: labels[index],
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() {
                      _selectedIndex = (_selectedIndex == index) ? null : index;
                    });
                  },
                  onTapDown: () => setState(() => touchedIndex = index),
                  onTapUp: () => setState(() => touchedIndex = null),
                  onLongPress: () {
                    HapticFeedback.heavyImpact();
                    _showDayDetails(
                      labels[index],
                      widget.chartData['Sales'][index],
                      widget.chartData['Profit'][index],
                      widget.chartData['Expenses'][index],
                      widget.chartData['Damage'][index],
                    );
                  },
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  void _showDayDetails(String label, double s, double p, double e, double d) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: "Details",
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, anim1, anim2) {
        return Center(
          child: Material(
            color: Colors.transparent,
            child: Container(
              width: MediaQuery.of(context).size.width * 0.85,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(28),
                boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 40)],
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text("$label Report", style: AppTextStyles.h2),
                    const SizedBox(height: 24),
                    _buildDetailItem("Gross Sales", s, AppColors.accent, Icons.trending_up),
                    _buildDetailItem("Expenses", e, AppColors.error, Icons.money_off),
                    _buildDetailItem("Damage Loss", d, Colors.orange, Icons.broken_image),
                    const Divider(height: 32),
                    _buildDetailItem("Net Profit", p, AppColors.success, Icons.account_balance_wallet, isLarge: true),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.grey[900],
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        child: const Text("DONE", style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
      transitionBuilder: (context, anim1, anim2, child) {
        return ScaleTransition(
          scale: CurvedAnimation(parent: anim1, curve: Curves.easeOutBack),
          child: FadeTransition(opacity: anim1, child: child),
        );
      },
    );
  }

  Widget _buildDetailItem(String label, double val, Color color, IconData icon, {bool isLarge = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 16),
          ),
          const SizedBox(width: 12),
          Text(label, style: TextStyle(color: Colors.grey[600], fontWeight: FontWeight.w500)),
          const Spacer(),
          Text(
            "Rs ${Formatter.formatCurrency(val)}",
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w900,
              fontSize: isLarge ? 18 : 14,
            ),
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
        _selectedIndex = null;
      }),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          boxShadow: isActive ? [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 2))] : [],
        ),
        child: Text(
          text,
          style: TextStyle(
            color: isActive ? Colors.black : Colors.grey[500],
            fontWeight: isActive ? FontWeight.w800 : FontWeight.w600,
            fontSize: 10,
          ),
        ),
      ),
    );
  }
}

class AnimatedKeyedBar extends StatelessWidget {
  final double barHeight;
  final Color barColor;
  final bool isActive;
  final String label;
  final VoidCallback onTap;
  final VoidCallback onTapDown;
  final VoidCallback onTapUp;
  final VoidCallback onLongPress;

  const AnimatedKeyedBar({
    super.key,
    required this.barHeight,
    required this.barColor,
    required this.isActive,
    required this.label,
    required this.onTap,
    required this.onTapDown,
    required this.onTapUp,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      onTapDown: (_) => onTapDown(),
      onTapUp: (_) => onTapUp(),
      onPanEnd: (_) => onTapUp(),
      onLongPress: onLongPress,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutQuart, // SAFE CURVE: No negative dip
            width: isActive ? 18 : 12,
            height: barHeight,
            decoration: BoxDecoration(
              color: isActive ? barColor : barColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(6),
              gradient: isActive
                  ? LinearGradient(
                      colors: [barColor, barColor.withOpacity(0.8)],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    )
                  : null,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            label,
            style: TextStyle(
              color: isActive ? Colors.black : Colors.grey[400],
              fontWeight: isActive ? FontWeight.w900 : FontWeight.normal,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}
