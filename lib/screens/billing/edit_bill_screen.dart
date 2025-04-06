import 'package:animated_snack_bar/animated_snack_bar.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:foodkie_express/api/order_service.dart';
import 'package:foodkie_express/models/order.dart';
import 'package:foodkie_express/routes.dart';
import 'package:foodkie_express/screens/home/controllers/cart_provider.dart';
import 'package:foodkie_express/api/menu_service.dart';
import 'package:foodkie_express/models/item.dart';
import 'package:foodkie_express/widgets/animated_button.dart';
import 'package:lottie/lottie.dart';

class EditBillScreen extends StatefulWidget {
  final String? orderId;

  const EditBillScreen({Key? key, this.orderId}) : super(key: key);

  @override
  State<EditBillScreen> createState() => _EditBillScreenState();
}

class _EditBillScreenState extends State<EditBillScreen> {
  OrderModel? _order;
  bool _isLoading = true;
  bool _isSaving = false;
  String? _errorMessage;
  final TextEditingController _notesController = TextEditingController();
  final TextEditingController _customerNameController = TextEditingController();
  final TextEditingController _customerPhoneController = TextEditingController();
  String _paymentMethod = 'Cash';
  late CartProvider _cartProvider;
  List<MenuItemModel> _menuItems = [];
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();
  List<MenuItemModel> _searchResults = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _cartProvider = Provider.of<CartProvider>(context, listen: false);
  }

  @override
  void dispose() {
    _notesController.dispose();
    _searchController.dispose();
    _customerNameController.dispose();
    _customerPhoneController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      if (widget.orderId == null) {
        throw Exception('Order ID is required');
      }

      // Load order details
      final orderService = Provider.of<OrderService>(context, listen: false);
      final order = await orderService.getOrderById(widget.orderId!);

      if (order == null) {
        throw Exception('Order not found');
      }

      // Clear cart and populate with order items
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
      _paymentMethod = order.paymentMethod;

      // Load menu items for adding new items
      final menuService = Provider.of<MenuService>(context, listen: false);
      final items = await menuService.getMenuItems().first;

      // Set order notes
      _notesController.text = order.notes ?? '';

      setState(() {
        _order = order;
        _menuItems = items;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  void _searchItems(String query) {
    if (query.isEmpty) {
      setState(() {
        _isSearching = false;
        _searchResults = [];
      });
      return;
    }

    setState(() {
      _isSearching = true;
      _searchResults = _menuItems
          .where((item) =>
      item.name.toLowerCase().contains(query.toLowerCase()) ||
          (item.description?.toLowerCase().contains(query.toLowerCase()) ?? false))
          .toList();
    });
  }

  Future<void> _saveUpdatedOrder() async {
    // First, check if cart is empty
    if (_cartProvider.items.isEmpty) {
      AnimatedSnackBar.material(
        'Cannot save an empty order',
        type: AnimatedSnackBarType.error,
        mobileSnackBarPosition: MobileSnackBarPosition.bottom,
        desktopSnackBarPosition: DesktopSnackBarPosition.bottomCenter,
        duration: Duration(seconds: 2),
      ).show(context);
      return;
    }

    // Show confirmation dialog with customer details
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text('Confirm Order Details'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Customer Name
                TextField(
                  controller: _customerNameController,
                  decoration: InputDecoration(
                    labelText: 'Customer Name',
                    hintText: 'Enter customer name',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Customer Phone
                TextField(
                  controller: _customerPhoneController,
                  decoration: InputDecoration(
                    labelText: 'Phone Number',
                    hintText: 'Enter phone number',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 16),

                // Payment Method
                Text(
                  'Payment Method',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
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
                const SizedBox(height: 16),

                // Order Notes
                TextField(
                  controller: _notesController,
                  decoration: InputDecoration(
                    labelText: 'Order Notes',
                    hintText: 'Add any special instructions...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  maxLines: 3,
                ),

                // Total Price
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Total Items:',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    Text(
                      '${_cartProvider.totalItems}',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Total:',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '₹${_cartProvider.totalPrice.toStringAsFixed(2)}',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                // Validate customer name and phone number
                if (_customerNameController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Please enter customer name'),
                      backgroundColor: Colors.orange,
                    ),
                  );
                  return;
                }

                if (_customerPhoneController.text.trim().isEmpty ||
                    !RegExp(r'^[0-9]{10}$').hasMatch(_customerPhoneController.text.trim())) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Please enter a valid 10-digit phone number'),
                      backgroundColor: Colors.orange,
                    ),
                  );
                  return;
                }

                Navigator.of(context).pop(true);
              },
              child: const Text('Confirm'),
            ),
          ],
        ),
      ),
    );

    // If user confirms, proceed with saving
    if (result == true) {
      setState(() {
        _isSaving = true;
      });

      try {
        // Create order items from cart
        final orderItems = _cartProvider.items.map((item) =>
            OrderItem(
              id: item.id,
              name: item.name,
              price: item.price,
              quantity: item.quantity,
              notes: item.notes,
            )
        ).toList();

        // Calculate new total
        final totalAmount = _cartProvider.totalPrice;

        // Create updated order
        final updatedOrder = _order!.copyWith(
          items: orderItems,
          totalAmount: totalAmount,
          notes: _notesController.text.trim(),
          customerName: _customerNameController.text.trim(),
          customerPhone: _customerPhoneController.text.trim(),
          paymentMethod: _paymentMethod,
        );

        // Save to database
        final orderService = Provider.of<OrderService>(context, listen: false);

        // First, delete the old order
        await orderService.deleteOrder(widget.orderId!);

        // Then create a new order with the same order number
        final data = updatedOrder.toMap();
        data['orderNumber'] = _order!.orderNumber;

        // Add the order with a new ID
        final orderId = await orderService.createOrder(OrderModel.fromMap(data, ''));

        // Show success
        if (mounted) {
          AnimatedSnackBar.material(
            'Bill updated successfully',
            type: AnimatedSnackBarType.success,
            mobileSnackBarPosition: MobileSnackBarPosition.bottom,
            desktopSnackBarPosition: DesktopSnackBarPosition.bottomCenter,
            duration: Duration(seconds: 2),
          ).show(context);

          // Navigate back to order details
          Navigator.pushReplacementNamed(
            context,
            AppRoutes.orderDetails,
            arguments: {'orderId': orderId},
          );
        }
      } catch (e) {
        // Show error
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error updating bill: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } finally {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  void _addItemToCart(MenuItemModel item) {
    if (!item.isAvailable) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${item.name} is currently unavailable'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    _cartProvider.addItem(
      id: item.id,
      name: item.name,
      price: item.price,
    );
    AnimatedSnackBar.material(
      '${item.name} added to bill',
      type: AnimatedSnackBarType.success,
      mobileSnackBarPosition: MobileSnackBarPosition.bottom,
      desktopSnackBarPosition: DesktopSnackBarPosition.bottomCenter,
      duration: Duration(seconds: 2),
    ).show(context);

    // Clear search
    _searchController.clear();
    setState(() {
      _isSearching = false;
      _searchResults = [];
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        title: Text(_order != null
            ? 'Edit Bill #${_order!.orderNumber ?? _order!.id.substring(0, 6)}'
            : 'Edit Bill'),
        actions: [
          IconButton(
            onPressed: _isSaving ? null : _saveUpdatedOrder,
            icon: const Icon(Icons.save),
            tooltip: 'Save Changes',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
          ? _buildErrorView()
          : _buildEditOrderContent(),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.error_outline,
            size: 64,
            color: Colors.red,
          ),
          const SizedBox(height: 16),
          Text(
            'Error Loading Order',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              _errorMessage ?? 'Unknown error',
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _loadData,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildEditOrderContent() {
    return Column(
      children: [
        // Search bar to add items
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              labelText: 'Search menu items to add',
              hintText: 'Type to search for items',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                icon: const Icon(Icons.clear),
                onPressed: () {
                  _searchController.clear();
                  _searchItems('');
                },
              )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onChanged: _searchItems,
          ),
        ),

        // Search results
        if (_isSearching && _searchResults.isNotEmpty)
          Container(
            height: 200,
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[300]!),
              borderRadius: BorderRadius.circular(8),
            ),
            child: ListView.separated(
              padding: const EdgeInsets.all(8),
              itemCount: _searchResults.length,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final item = _searchResults[index];
                return ListTile(
                  title: Text(item.name),
                  subtitle: Text('₹${item.price.toStringAsFixed(2)}'),
                  trailing: IconButton(
                    icon: const Icon(Icons.add_circle_outline),
                    onPressed: () => _addItemToCart(item),
                  ),
                  onTap: () => _addItemToCart(item),
                );
              },
            ),
          ),

        // Current cart/bill items
        Expanded(
          child: Consumer<CartProvider>(
            builder: (context, cartProvider, _) {
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
                        'Bill is empty',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Add items from the search above',
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                    ],
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                itemCount: cartProvider.items.length,
                itemBuilder: (context, index) {
                  final item = cartProvider.items[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 10),
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item.name,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                    Text(
                                      '₹${item.price.toStringAsFixed(2)}',
                                      style: TextStyle(
                                        color: Theme.of(context).colorScheme.primary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Row(
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.remove_circle_outline),
                                    onPressed: () => cartProvider.decrementQuantity(item.id),
                                  ),
                                  Text('${item.quantity}'),
                                  IconButton(
                                    icon: const Icon(Icons.add_circle_outline),
                                    onPressed: () => cartProvider.incrementQuantity(item.id),
                                  ),
                                ],
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline, color: Colors.red),
                                onPressed: () => cartProvider.removeItem(item.id),
                              ),
                            ],
                          ),
                          if (item.notes != null && item.notes!.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Text(
                                'Note: ${item.notes}',
                                style: const TextStyle(
                                  fontStyle: FontStyle.italic,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          TextButton.icon(
                            icon: const Icon(Icons.edit_note, size: 16),
                            label: const Text('Edit Note'),
                            onPressed: () {
                              _showAddNoteDialog(item);
                            },
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),

        // Summary and actions
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
              Consumer<CartProvider>(
                builder: (context, cartProvider, _) => Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
              ),
              const SizedBox(height: 8),
              Consumer<CartProvider>(
                builder: (context, cartProvider, _) => Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Total:',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '₹${cartProvider.totalPrice.toStringAsFixed(2)}',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              AnimatedButton(
                onPressed: _isSaving ? null : _saveUpdatedOrder,
                isLoading: _isSaving,
                child: const Text('Save Changes'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showAddNoteDialog(CartItem item) {
    final noteController = TextEditingController(text: item.notes);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Add Note for ${item.name}'),
        content: TextField(
          controller: noteController,
          decoration: const InputDecoration(
            hintText: 'Enter special instructions...',
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              _cartProvider.updateItemNotes(item.id, noteController.text);
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}