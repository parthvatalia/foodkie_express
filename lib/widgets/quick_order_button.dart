import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:foodkie_express/screens/home/controllers/cart_provider.dart';

class QuickOrderButton extends StatelessWidget {
  final VoidCallback onPressed;

  const QuickOrderButton({
    Key? key,
    required this.onPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<CartProvider>(
      builder: (context, cartProvider, _) {
        final hasItems = cartProvider.items.isNotEmpty;

        return FloatingActionButton.extended(
          onPressed: onPressed,
          backgroundColor: hasItems
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).colorScheme.primaryContainer,
          label: Row(
            children: [
              Icon(
                hasItems ? Icons.receipt : Icons.add_shopping_cart,
                color: hasItems
                    ? Colors.white
                    : Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Text(
                hasItems
                    ? 'Place Order (${cartProvider.totalItems})'
                    : 'Quick Order',
                style: TextStyle(
                  color: hasItems
                      ? Colors.white
                      : Theme.of(context).colorScheme.primary,
                ),
              ),
              if (hasItems) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '₹${cartProvider.totalPrice.toStringAsFixed(0)}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}