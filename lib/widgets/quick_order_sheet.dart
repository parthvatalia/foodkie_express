import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:foodkie_express/models/order.dart';
import 'package:foodkie_express/api/order_service.dart';
import 'package:foodkie_express/screens/home/controllers/cart_provider.dart';
import 'package:foodkie_express/models/item.dart';
import 'package:foodkie_express/routes.dart';
import 'package:foodkie_express/widgets/animated_button.dart';

class QuickOrderSheet extends StatefulWidget {
  final List<MenuItemModel>? preSelectedItems;
  final bool isEditMode;
  final String? orderId;

  const QuickOrderSheet({
    Key? key,
    this.preSelectedItems,
    this.isEditMode = false,
    this.orderId,
  }) : super(key: key);

  static Future<void> show({
    required BuildContext context,
    List<MenuItemModel>? preSelectedItems,
    bool isEditMode = false,
    String? orderId,
  }) async {
    return await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => QuickOrderSheet(
        preSelectedItems: preSelectedItems,
        isEditMode: isEditMode,
        orderId: orderId,
      ),
    );
  }

  @override
  State<QuickOrderSheet> createState() => _QuickOrderSheetState();
}

class _QuickOrderSheetState extends State<QuickOrderSheet> {
  final _customerNameController = TextEditingController();
  final _customerPhoneController = TextEditingController();
  final _notesController = TextEditingController();

  String _paymentMethod = 'Cash';
  bool _isProcessing = false;
  bool _showCustomerDetails = false;
  late CartProvider _cartProvider;

  
  final double _sheetHeight = 0.6; 

  @override
  void initState() {
    super.initState();
    _cartProvider = Provider.of<CartProvider>(context, listen: false);

    
    if (!widget.isEditMode) {
      _cartProvider.clearCart();

      
      if (widget.preSelectedItems != null) {
        for (var item in widget.preSelectedItems!) {
          _cartProvider.addItem(
            id: item.id,
            name: item.name,
            price: item.price,
          );
        }
      }
    } else {
      
      _loadOrderData();
    }
  }

  @override
  void dispose() {
    _customerNameController.dispose();
    _customerPhoneController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _loadOrderData() async {
    if (widget.orderId == null) return;

    setState(() {
      _isProcessing = true;
    });

    try {
      final orderService = Provider.of<OrderService>(context, listen: false);
      final order = await orderService.getOrderById(widget.orderId!);

      if (order != null) {
        
        _cartProvider.clearCart();

        
        for (var item in order.items) {
          _cartProvider.addItem(
            id: item.id,
            name: item.name,
            price: item.price,
            quantity: item.quantity,
            notes: item.notes,
          );
        }

        
        _customerNameController.text = order.customerName ?? '';
        _customerPhoneController.text = order.customerPhone ?? '';
        _notesController.text = order.notes ?? '';

        
        setState(() {
          _paymentMethod = order.paymentMethod;
          
          _showCustomerDetails = order.customerName?.isNotEmpty == true ||
              order.customerPhone?.isNotEmpty == true;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading order: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  Future<void> _processOrder() async {
    if (_cartProvider.items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please add items to the order'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isProcessing = true;
    });

    try {
      
      final orderItems = _cartProvider.items.map((item) =>
          OrderItem(
            id: item.id,
            name: item.name,
            price: item.price,
            quantity: item.quantity,
            notes: item.notes,
          )
      ).toList();

      final orderService = Provider.of<OrderService>(context, listen: false);

      if (widget.isEditMode && widget.orderId != null) {
        
        
        await orderService.deleteOrder(widget.orderId!);

        
        final updatedOrder = OrderModel.create(
          items: orderItems,
          totalAmount: _cartProvider.totalPrice,
          notes: _notesController.text.trim(),
          customerName: _customerNameController.text.trim(),
          customerPhone: _customerPhoneController.text.trim(),
          paymentMethod: _paymentMethod,
        );

        final newOrderId = await orderService.createOrder(updatedOrder);

        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Order updated successfully'),
              backgroundColor: Colors.green,
            ),
          );

          
          Navigator.pop(context); 
          Navigator.pushReplacementNamed(
            context,
            AppRoutes.orderDetails,
            arguments: {'orderId': newOrderId},
          );
        }
      } else {
        
        final newOrder = OrderModel.create(
          items: orderItems,
          totalAmount: _cartProvider.totalPrice,
          notes: _notesController.text.trim(),
          customerName: _customerNameController.text.trim(),
          customerPhone: _customerPhoneController.text.trim(),
          paymentMethod: _paymentMethod,
        );

        final orderId = await orderService.createOrder(newOrder);

        
        _cartProvider.clearCart();

        
        if (mounted) {
          Navigator.pop(context); 

          
          _showOrderSuccess(context, orderId);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error processing order: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  void _showOrderSuccess(BuildContext context, String orderId) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green, size: 30),
            SizedBox(width: 10),
            Text('Order Placed!'),
          ],
        ),
        content: Text('Order #$orderId has been created successfully.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushNamed(
                context,
                AppRoutes.orderDetails,
                arguments: {'orderId': orderId},
              );
            },
            child: const Text('View Order'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return StatefulBuilder(
      builder: (context, setModalState) {
        return DraggableScrollableSheet(
          initialChildSize: _sheetHeight,
          minChildSize: 0.4,
          maxChildSize: 0.95,
          expand: false,
          builder: (context, scrollController) {
            return Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 10,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: Column(
                children: [
                  
                  Container(
                    width: 40,
                    height: 5,
                    margin: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),

                  
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          widget.isEditMode ? 'Edit Order' : 'Quick Order',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                  ),

                  
                  Expanded(
                    child: ListView(
                      controller: scrollController,
                      padding: const EdgeInsets.all(20),
                      children: [
                        
                        Row(
                          children: [
                            Text(
                              'Customer Details',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(width: 10),
                            Switch(
                              value: _showCustomerDetails,
                              onChanged: (value) {
                                setState(() {
                                  _showCustomerDetails = value;
                                });
                              },
                            ),
                          ],
                        ),

                        
                        if (_showCustomerDetails)
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            child: Column(
                              children: [
                                Row(
                                  children: [
                                    
                                    Expanded(
                                      child: TextField(
                                        controller: _customerNameController,
                                        decoration: InputDecoration(
                                          labelText: 'Name',
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          contentPadding: const EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 10,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    
                                    Expanded(
                                      child: TextField(
                                        controller: _customerPhoneController,
                                        decoration: InputDecoration(
                                          labelText: 'Phone',
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          contentPadding: const EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 10,
                                          ),
                                        ),
                                        keyboardType: TextInputType.phone,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 20),
                              ],
                            ),
                          ),

                        
                        Text(
                          'Order Items',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 10),

                        
                        Consumer<CartProvider>(
                          builder: (context, cart, _) {
                            if (cart.items.isEmpty) {
                              return Center(
                                child: Padding(
                                  padding: const EdgeInsets.all(20.0),
                                  child: Text(
                                    'No items added yet',
                                    style: TextStyle(color: Colors.grey[600]),
                                  ),
                                ),
                              );
                            }

                            return Column(
                              children: cart.items.map((item) {
                                return Card(
                                  margin: const EdgeInsets.only(bottom: 10),
                                  child: Padding(
                                    padding: const EdgeInsets.all(10.0),
                                    child: Row(
                                      children: [
                                        
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                item.name,
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              Text(
                                                '₹${item.price.toStringAsFixed(2)}',
                                                style: TextStyle(
                                                  color: Theme.of(context).colorScheme.primary,
                                                ),
                                              ),
                                              if (item.notes != null && item.notes!.isNotEmpty)
                                                Text(
                                                  'Note: ${item.notes}',
                                                  style: const TextStyle(
                                                    fontStyle: FontStyle.italic,
                                                    fontSize: 12,
                                                  ),
                                                ),
                                            ],
                                          ),
                                        ),

                                        
                                        Container(
                                          decoration: BoxDecoration(
                                            border: Border.all(color: Colors.grey[300]!),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Row(
                                            children: [
                                              
                                              IconButton(
                                                icon: const Icon(Icons.remove),
                                                iconSize: 16,
                                                padding: EdgeInsets.zero,
                                                constraints: const BoxConstraints(
                                                  minWidth: 30,
                                                  minHeight: 30,
                                                ),
                                                onPressed: () => cart.decrementQuantity(item.id),
                                              ),

                                              
                                              SizedBox(
                                                width: 30,
                                                child: Text(
                                                  '${item.quantity}',
                                                  textAlign: TextAlign.center,
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ),

                                              
                                              IconButton(
                                                icon: const Icon(Icons.add),
                                                iconSize: 16,
                                                padding: EdgeInsets.zero,
                                                constraints: const BoxConstraints(
                                                  minWidth: 30,
                                                  minHeight: 30,
                                                ),
                                                onPressed: () => cart.incrementQuantity(item.id),
                                              ),
                                            ],
                                          ),
                                        ),

                                        
                                        IconButton(
                                          icon: const Icon(Icons.delete_outline, color: Colors.red),
                                          onPressed: () => cart.removeItem(item.id),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              }).toList(),
                            );
                          },
                        ),

                        const SizedBox(height: 20),

                        
                        OutlinedButton.icon(
                          icon: const Icon(Icons.add),
                          label: const Text('Add Custom Item'),
                          onPressed: () => _showAddCustomItemDialog(context),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),

                        const SizedBox(height: 20),

                        
                        TextField(
                          controller: _notesController,
                          decoration: InputDecoration(
                            labelText: 'Order Notes',
                            hintText: 'Any special instructions...',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          maxLines: 2,
                        ),

                        const SizedBox(height: 20),

                        
                        Text(
                          'Payment Method',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 10),

                        
                        Row(
                          children: [
                            Expanded(
                              child: RadioListTile<String>(
                                title: const Text('Cash'),
                                value: 'Cash',
                                groupValue: _paymentMethod,
                                onChanged: (value) {
                                  setState(() {
                                    _paymentMethod = value!;
                                  });
                                },
                                contentPadding: EdgeInsets.zero,
                              ),
                            ),
                            Expanded(
                              child: RadioListTile<String>(
                                title: const Text('UPI'),
                                value: 'UPI',
                                groupValue: _paymentMethod,
                                onChanged: (value) {
                                  setState(() {
                                    _paymentMethod = value!;
                                  });
                                },
                                contentPadding: EdgeInsets.zero,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 30),
                      ],
                    ),
                  ),

                  
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 5,
                          offset: const Offset(0, -3),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        
                        Consumer<CartProvider>(
                          builder: (context, cart, _) => Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Total (${cart.totalItems} items):',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                '₹${cart.totalPrice.toStringAsFixed(2)}',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 10),

                        
                        AnimatedButton(
                          onPressed: _isProcessing ? null : _processOrder,
                          isLoading: _isProcessing,
                          child: Text(
                            widget.isEditMode ? 'Update Order' : 'Place Order',
                            style: const TextStyle(fontSize: 16),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showAddCustomItemDialog(BuildContext context) {
    final nameController = TextEditingController();
    final priceController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Custom Item'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Item Name',
                hintText: 'Enter item name',
              ),
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: priceController,
              decoration: const InputDecoration(
                labelText: 'Price (₹)',
                hintText: 'Enter price',
                prefixText: '₹ ',
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              
              final name = nameController.text.trim();
              final priceText = priceController.text.trim();

              if (name.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please enter an item name'))
                );
                return;
              }

              final price = double.tryParse(priceText);
              if (price == null || price <= 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please enter a valid price'))
                );
                return;
              }

              
              _cartProvider.addCustomItem(
                name: name,
                price: price,
              );

              Navigator.pop(context);
            },
            child: const Text('Add Item'),
          ),
        ],
      ),
    );
  }
}