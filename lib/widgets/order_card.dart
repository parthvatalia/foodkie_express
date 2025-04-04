import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:foodkie_express/models/order.dart';

class OrderCard extends StatelessWidget {
  final OrderModel order;
  final VoidCallback onTap;

  const OrderCard({
    Key? key,
    required this.order,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Order Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Order Number
                  Text(
                    'Order #${order.orderNumber ?? order.id.substring(0, 6)}',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  // Status Chip
                  _buildStatusChip(context),
                ],
              ),

              // Divider
              Divider(
                height: 24,
                thickness: 1,
                color: Colors.grey[200],
              ),

              // Order Items
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Items:',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildItemsList(context),
                ],
              ),

              // Divider
              Divider(
                height: 24,
                thickness: 1,
                color: Colors.grey[200],
              ),

              // Order Footer
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Order Date
                  if (order.createdAt != null)
                    Text(
                      DateFormat('MMM dd, yyyy • hh:mm a').format(order.createdAt!.toDate()),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),

                  // Total
                  Text(
                    '₹${order.totalAmount.toStringAsFixed(2)}',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusChip(BuildContext context) {
    Color bgColor;
    Color textColor;

    switch (order.status) {
      case 'pending':
        bgColor = Colors.orange[50]!;
        textColor = Colors.orange[700]!;
        break;
      case 'processing':
        bgColor = Colors.blue[50]!;
        textColor = Colors.blue[700]!;
        break;
      case 'completed':
        bgColor = Colors.green[50]!;
        textColor = Colors.green[700]!;
        break;
      case 'cancelled':
        bgColor = Colors.red[50]!;
        textColor = Colors.red[700]!;
        break;
      default:
        bgColor = Colors.grey[50]!;
        textColor = Colors.grey[700]!;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        order.status.capitalize(),
        style: TextStyle(
          color: textColor,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _buildItemsList(BuildContext context) {
    // Display up to 3 items, and "more" if there are additional items
    final displayItems = order.items.take(3).toList();
    final hasMore = order.items.length > 3;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ...displayItems.map((item) => Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Text(
            '${item.quantity}x ${item.name}',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        )),
        if (hasMore)
          Text(
            '+ ${order.items.length - 3} more items',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.grey[600],
              fontStyle: FontStyle.italic,
            ),
          ),
      ],
    );
  }
}

// Extension to capitalize first letter
extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${substring(1)}";
  }
}