import 'package:flutter/material.dart';

class QuantitySelector extends StatelessWidget {
  final int quantity;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;
  final int minQuantity;
  final int maxQuantity;
  final double width;
  final double height;

  const QuantitySelector({
    Key? key,
    required this.quantity,
    required this.onIncrement,
    required this.onDecrement,
    this.minQuantity = 1,
    this.maxQuantity = 99,
    this.width = 100,
    this.height = 36,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        border: Border.all(
          color: Theme.of(context).colorScheme.outline,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Decrement Button
          IconButton(
            icon: const Icon(Icons.remove),
            onPressed: quantity > minQuantity ? onDecrement : null,
            iconSize: 18,
            splashRadius: 20,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(maxWidth: 30),
          ),

          // Quantity Display
          Text(
            '$quantity',
            style: Theme.of(context).textTheme.titleMedium,
          ),

          // Increment Button
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: quantity < maxQuantity ? onIncrement : null,
            iconSize: 18,
            splashRadius: 20,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(maxWidth: 30),
          ),
        ],
      ),
    );
  }
}