import 'package:flutter/material.dart';
import 'package:foodkie_express/models/item.dart';
import 'package:provider/provider.dart';
import 'package:foodkie_express/screens/home/controllers/cart_provider.dart';

class ItemQuickAddButton extends StatelessWidget {
  final MenuItemModel item;
  final VoidCallback? onAdded;

  const ItemQuickAddButton({
    Key? key,
    required this.item,
    this.onAdded,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<CartProvider>(
      builder: (context, cartProvider, _) {
        final cartItem = cartProvider.getItemById(item.id);
        final isInCart = cartItem != null;

        if (isInCart) {
          
          return Container(
            height: 36,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                
                ClipRRect(
                  borderRadius: const BorderRadius.horizontal(left: Radius.circular(17)),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => cartProvider.decrementQuantity(item.id),
                      child: Container(
                        width: 36,
                        height: 36,
                        alignment: Alignment.center,
                        child: const Icon(Icons.remove, size: 18),
                      ),
                    ),
                  ),
                ),

                
                SizedBox(
                  width: 28,
                  child: Text(
                    '${cartItem.quantity}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

                
                ClipRRect(
                  borderRadius: const BorderRadius.horizontal(right: Radius.circular(17)),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        cartProvider.incrementQuantity(item.id);
                        if (onAdded != null) onAdded!();
                      },
                      child: Container(
                        width: 36,
                        height: 36,
                        alignment: Alignment.center,
                        child: const Icon(Icons.add, size: 18),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        } else {
          
          return ElevatedButton.icon(
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Add'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
              minimumSize: const Size(0, 36),
            ),
            onPressed: item.isAvailable ? () {
              cartProvider.addItem(
                id: item.id,
                name: item.name,
                price: item.price,
              );
              if (onAdded != null) onAdded!();
            } : null,
          );
        }
      },
    );
  }
}