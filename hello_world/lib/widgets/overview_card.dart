// lib/widgets/overview_card.dart
import 'package:flutter/material.dart';

class OverviewCard extends StatefulWidget {
  final String title;
  final String amount;
  // Percentage variable hata diya

  const OverviewCard({super.key, required this.title, required this.amount});

  @override
  State<OverviewCard> createState() => _OverviewCardState();
}

class _OverviewCardState extends State<OverviewCard> {
  bool _isBalanceVisible = true;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // === TITLE + EYE ICON ===
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
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

                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _isBalanceVisible = !_isBalanceVisible;
                      });
                    },
                    child: Icon(
                      _isBalanceVisible
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                      color: Colors.grey,
                      size: 18,
                    ),
                  ),
                ],
              ),
              const Icon(Icons.inventory_2, color: Colors.grey, size: 18),
            ],
          ),

          const SizedBox(
            height: 16,
          ), // Thoda gap badhaya taake center mein lage
          // === AMOUNT TEXT ===
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: Text(
              _isBalanceVisible ? widget.amount : "Rs •••••••",
              key: ValueKey<bool>(_isBalanceVisible),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),

          // Neeche wali percentage Row yahan se DELETE kar di
        ],
      ),
    );
  }
}
