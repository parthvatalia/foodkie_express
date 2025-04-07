import 'package:animated_snack_bar/animated_snack_bar.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:foodkie_express/api/order_service.dart';
import 'package:foodkie_express/models/order.dart';
import 'package:foodkie_express/routes.dart';
import 'package:foodkie_express/screens/home/controllers/cart_provider.dart';
import 'package:foodkie_express/widgets/animated_button.dart';
import 'package:foodkie_express/widgets/cart_item.dart';
import 'package:lottie/lottie.dart';

import '../../utils/printer_services.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({Key? key}) : super(key: key);

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  final TextEditingController _notesController = TextEditingController();
  final TextEditingController _customerNameController = TextEditingController();
  final TextEditingController _customerPhoneController =
      TextEditingController();

  bool _isProcessing = false;
  final bool _showCustomerDetails = false;
  String _paymentMethod = 'Cash';

  @override
  void dispose() {
    _notesController.dispose();
    _customerNameController.dispose();
    _customerPhoneController.dispose();
    super.dispose();
  }

  Future<void> _placeOrder() {
    
    return _showCustomerDetailsBottomSheet(
      onConfirm: () async {
        final cartProvider = Provider.of<CartProvider>(context, listen: false);

        if (cartProvider.items.isEmpty) {
          AnimatedSnackBar.material(
            'Cart is empty',
            type: AnimatedSnackBarType.info,
            mobileSnackBarPosition: MobileSnackBarPosition.bottom,
            desktopSnackBarPosition: DesktopSnackBarPosition.bottomCenter,
            duration: const Duration(seconds: 2),
          ).show(context);
          return;
        }

        setState(() {
          _isProcessing = true;
        });

        try {
          
          final orderItems =
              cartProvider.items
                  .map(
                    (item) => OrderItem(
                      id: item.id,
                      name: item.name,
                      price: item.price,
                      quantity: item.quantity,
                      notes: item.notes,
                    ),
                  )
                  .toList();

          
          final newOrder = OrderModel.create(
            items: orderItems,
            totalAmount: cartProvider.totalPrice,
            notes: _notesController.text.trim(),
            customerName: _customerNameController.text.trim(),
            customerPhone: _customerPhoneController.text.trim(),
            paymentMethod: _paymentMethod,
          );

          
          final orderService = Provider.of<OrderService>(
            context,
            listen: false,
          );
          final orderId = await orderService.createOrder(newOrder);

          
          cartProvider.clearCart();

          
          _showOrderSuccess(orderId);
        } catch (e) {
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );

          setState(() {
            _isProcessing = false;
          });
        }
      },
    );
  }

  Future<void> _printReceipt() {
    
    return _showCustomerDetailsBottomSheet(
      onConfirm: () async {
        final cartProvider = Provider.of<CartProvider>(context, listen: false);

        if (cartProvider.items.isEmpty) {
          AnimatedSnackBar.material(
            'Cart is empty',
            type: AnimatedSnackBarType.info,
            mobileSnackBarPosition: MobileSnackBarPosition.bottom,
            desktopSnackBarPosition: DesktopSnackBarPosition.bottomCenter,
            duration: const Duration(seconds: 2),
          ).show(context);
          return;
        }

        setState(() {
          _isProcessing = true;
        });

        try {
          final printerService = PrinterService();

          final items =
              cartProvider.items
                  .map(
                    (item) => {
                      'name': item.name,
                      'price': item.price,
                      'quantity': item.quantity,
                      'total': item.price * item.quantity,
                    },
                  )
                  .toList();

          final receiptData = {
            'items': items,
            'total': cartProvider.totalPrice,
            'notes': _notesController.text.trim(),
            'timestamp': DateTime.now().toString(),
            'customerName': _customerNameController.text.trim(),
            'customerPhone': _customerPhoneController.text.trim(),
            'paymentMethod': _paymentMethod,
          };

          final success = await printerService.printReceipt(receiptData);

          if (success) {
            AnimatedSnackBar.material(
              'Receipt printed successfully',
              type: AnimatedSnackBarType.success,
              mobileSnackBarPosition: MobileSnackBarPosition.bottom,
              desktopSnackBarPosition: DesktopSnackBarPosition.bottomCenter,
              duration: const Duration(seconds: 2),
            ).show(context);
          } else {
            AnimatedSnackBar.material(
              'Failed to print receipt',
              type: AnimatedSnackBarType.error,
              mobileSnackBarPosition: MobileSnackBarPosition.bottom,
              desktopSnackBarPosition: DesktopSnackBarPosition.bottomCenter,
              duration: const Duration(seconds: 2),
            ).show(context);
          }
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Printer error: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        } finally {
          setState(() {
            _isProcessing = false;
          });
        }
      },
    );
  }

  Future<void> _showCustomerDetailsBottomSheet({
    required Future<void> Function() onConfirm,
  }) {
    
    String localPaymentMethod = _paymentMethod;

    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder:
          (bottomSheetContext) => StatefulBuilder(
            builder:
                (context, setModalState) => Padding(
                  padding: EdgeInsets.only(
                    bottom: MediaQuery.of(bottomSheetContext).viewInsets.bottom,
                    left: 16,
                    right: 16,
                    top: 16,
                  ),
                  child: Form(
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            'Customer Details',
                            style:
                                Theme.of(
                                  bottomSheetContext,
                                ).textTheme.headlineSmall,
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),

                          
                          TextFormField(
                            controller: _customerNameController,
                            decoration: InputDecoration(
                              labelText: 'Customer Name',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Please enter customer name';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),

                          
                          TextFormField(
                            controller: _customerPhoneController,
                            decoration: InputDecoration(
                              labelText: 'Phone Number',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            keyboardType: TextInputType.phone,
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Please enter phone number';
                              }
                              
                              if (!RegExp(
                                r'^[0-9]{10}$',
                              ).hasMatch(value.trim())) {
                                return 'Please enter a valid 10-digit phone number';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),

                          
                          Text(
                            'Payment Method',
                            style:
                                Theme.of(
                                  bottomSheetContext,
                                ).textTheme.titleMedium,
                          ),
                          Row(
                            children: [
                              Expanded(
                                child: RadioListTile<String>(
                                  title: const Text('Cash'),
                                  value: 'Cash',
                                  groupValue: localPaymentMethod,
                                  onChanged: (value) {
                                    setModalState(() {
                                      localPaymentMethod = value!;
                                    });
                                    
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
                                  groupValue: localPaymentMethod,
                                  onChanged: (value) {
                                    setModalState(() {
                                      localPaymentMethod = value!;
                                    });
                                    
                                    setState(() {
                                      _paymentMethod = value!;
                                    });
                                  },
                                  contentPadding: EdgeInsets.zero,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          
                          TextField(
                            controller: _notesController,
                            decoration: InputDecoration(
                              labelText: 'Order Notes',
                              hintText: 'Add any special instructions...',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            maxLines: 2,
                          ),
                          const SizedBox(height: 16),

                          
                          ElevatedButton(
                            onPressed: () {
                              
                              Navigator.pop(bottomSheetContext);

                              
                              Future.microtask(() {
                                onConfirm();
                              });
                            },
                            child: const Text('Confirm'),
                          ),
                          const SizedBox(height: 16),
                        ],
                      ),
                    ),
                  ),
                ),
          ),
    );
  }

  void _showOrderSuccess(String orderId) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Lottie.asset(
                      'assets/animations/order_success.json',
                      height: 150,
                      repeat: false,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Order Placed!',
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Order #$orderId has been placed successfully.',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        TextButton(
                          onPressed: () {
                            Navigator.pop(context);
                            Navigator.pop(context);
                          },
                          child: const Text('Back to Menu'),
                        ),
                        ElevatedButton(
                          onPressed: () {
                            Navigator.pop(context);
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
                  ],
                ),
              ),
            ),
          ),
    );

    setState(() {
      _isProcessing = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cart'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: () {
              final cartProvider = Provider.of<CartProvider>(
                context,
                listen: false,
              );
              if (cartProvider.items.isNotEmpty) {
                _showClearCartDialog();
              }
            },
          ),
        ],
      ),
      body: Consumer<CartProvider>(
        builder: (context, cartProvider, child) {
          if (cartProvider.items.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Lottie.asset(
                    'assets/animations/empty_cart.json',
                    height: 200,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Your cart is empty',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Add items from the menu to get started',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back),
                    label: const Text('Back to Menu'),
                  ),
                ],
              ),
            );
          }

          return Column(
            children: [
              
              Expanded(
                flex: 2,
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: cartProvider.items.length,
                  itemBuilder: (context, index) {
                    final item = cartProvider.items[index];
                    return CartItemWidget(
                      item: item,
                      onIncrement:
                          () => cartProvider.incrementQuantity(item.id),
                      onDecrement:
                          () => cartProvider.decrementQuantity(item.id),
                      onRemove: () => cartProvider.removeItem(item.id),
                      onNotesChanged:
                          (notes) =>
                              cartProvider.updateItemNotes(item.id, notes),
                    );
                  },
                ),
              ),

              

              
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, -5),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,

                      children: [
                        Row(
                          children: [
                            Text(
                              'Total Items:',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            Text(
                              '${cartProvider.totalItems}',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Text(
                              'Total:',
                              style: Theme.of(context).textTheme.titleLarge
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            Text(
                              '₹${cartProvider.totalPrice.toStringAsFixed(2)}',
                              style: Theme.of(
                                context,
                              ).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        
                        Expanded(
                          flex: 1,
                          child: AnimatedButton(
                            onPressed: _isProcessing ? null : _printReceipt,
                            isLoading: _isProcessing,
                            backgroundColor:
                                Theme.of(
                                  context,
                                ).colorScheme.secondaryContainer,
                            foregroundColor:
                                Theme.of(
                                  context,
                                ).colorScheme.onSecondaryContainer,
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.print),
                                SizedBox(width: 8),
                                Text('Print'),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        
                        Expanded(
                          flex: 2,
                          child: AnimatedButton(
                            onPressed: _isProcessing ? null : _placeOrder,
                            isLoading: _isProcessing,
                            child: const Text('Place Order'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showClearCartDialog() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Clear Cart'),
            content: const Text(
              'Are you sure you want to clear all items from your cart?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  Provider.of<CartProvider>(context, listen: false).clearCart();
                },
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: const Text('Clear'),
              ),
            ],
          ),
    );
  }
}
