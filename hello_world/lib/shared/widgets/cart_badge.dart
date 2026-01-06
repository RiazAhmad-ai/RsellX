import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/sales_provider.dart';

class CartBadge extends StatelessWidget {
  final VoidCallback onTap;
  const CartBadge({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final count = context.watch<SalesProvider>().cart.length;
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        alignment: Alignment.center,
        children: [
          const Padding(
            padding: EdgeInsets.all(8.0),
            child: Icon(Icons.shopping_cart_outlined, color: Colors.blue, size: 28),
          ),
          if (count > 0)
            Positioned(
              top: 5,
              right: 5,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  "$count",
                  style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
