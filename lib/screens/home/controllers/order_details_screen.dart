
import 'package:animated_snack_bar/animated_snack_bar.dart';
import 'package:flutter/material.dart';
import 'package:foodkie_express/screens/home/order_history_screen.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:foodkie_express/api/order_service.dart';
import 'package:foodkie_express/api/profile_service.dart';
import 'package:foodkie_express/models/order.dart';
import 'package:foodkie_express/models/profile.dart';
import 'package:foodkie_express/widgets/animated_button.dart';

import '../../../routes.dart';
import '../../../utils/printer_services.dart';
import '../../settings/bluetooth_printer_screen.dart';

class OrderDetailsScreen extends StatefulWidget {
  final String? orderId;

  const OrderDetailsScreen({Key? key, this.orderId}) : super(key: key);

  @override
  State<OrderDetailsScreen> createState() => _OrderDetailsScreenState();
}

class _OrderDetailsScreenState extends State<OrderDetailsScreen> {
  OrderModel? _order;
  RestaurantProfile? _profile;
  bool _isLoading = true;
  bool _isPrinting = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadData();
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

      
      final orderService = Provider.of<OrderService>(context, listen: false);
      final order = await orderService.getOrderById(widget.orderId!);

      if (order == null) {
        throw Exception('Order not found');
      }

      
      final profileService = Provider.of<ProfileService>(
        context,
        listen: false,
      );
      final profile = await profileService.getRestaurantProfile();

      setState(() {
        _order = order;
        _profile = profile;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _printReceipt() async {
    final printerService = PrinterService();

    if (_order == null) return;

    setState(() {
      _isPrinting = true;
    });

    bool bluetoothEnabled = await printerService.isBluetoothEnabled();
    if (!bluetoothEnabled) {
      AnimatedSnackBar.material(
        'Please enable Bluetooth to print',
        type: AnimatedSnackBarType.info,
        mobileSnackBarPosition: MobileSnackBarPosition.bottom,
        desktopSnackBarPosition: DesktopSnackBarPosition.bottomCenter,
        duration: const Duration(seconds: 2),
      ).show(context);

      return;
    }

    
    Map<String, String>? savedPrinter =
        await printerService.getSavedBluetoothPrinter();
    if (savedPrinter == null) {
      
      bool setupPrinter =
          await showDialog(
            context: context,
            builder:
                (context) => AlertDialog(
                  title: const Text('No Printer Set Up'),
                  content: const Text(
                    'You need to set up a printer to print receipts. Would you like to do that now?',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('No'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text('Yes'),
                    ),
                  ],
                ),
          ) ??
          false;

      if (setupPrinter && context.mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const BluetoothPrinterSelectionScreen(),
          ),
        );
      }
      return;
    }

    
    bool connected = await printerService.isPrinterConnected();
    if (!connected) {
      
      bool setupPrinter =
          await showDialog(
            context: context,
            builder:
                (context) => AlertDialog(
                  title: const Text('Printer Not Connected'),
                  content: Text(
                    'Your printer "${savedPrinter['name']}" is not connected. Make sure it is turned on and within range, or select a different printer.',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text('Select Printer'),
                    ),
                  ],
                ),
          ) ??
          false;

      if (setupPrinter && context.mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const BluetoothPrinterSelectionScreen(),
          ),
        );
      }
      return;
    }

    try {
      final items =
          _order!.items
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
        'total': _order!.totalAmount,
        'notes': _order!.notes,
        'customerName': _order!.customerName,
        'customerPhone': _order!.customerPhone,
        'paymentMethod': _order!.paymentMethod,
        'timestamp':
            _order!.createdAt?.toDate().toString() ?? DateTime.now().toString(),
        
        'restaurant': {
          'name': _profile?.name ?? 'Foodkie Express',
          'address': _profile?.formattedAddress ?? '',
          'email': _profile?.email ?? '',
          'logoUrl': _profile?.logoUrl,
        },
        'orderNumber': _order!.orderNumber ?? _order!.id.substring(0, 6),
      };

      final success = await printerService.printReceipt(receiptData);

      if (mounted) {
        AnimatedSnackBar.material(
          success ? 'Receipt printed successfully' : 'Failed to print receipt',
          type:
              success
                  ? AnimatedSnackBarType.success
                  : AnimatedSnackBarType.error,
          mobileSnackBarPosition: MobileSnackBarPosition.bottom,
          desktopSnackBarPosition: DesktopSnackBarPosition.bottomCenter,
          duration: const Duration(seconds: 2),
        ).show(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Printer error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isPrinting = false;
        });
      }
    }
  }

  Future<void> _updateOrderStatus(String status) async {
    if (_order == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final orderService = Provider.of<OrderService>(context, listen: false);
      await orderService.updateOrderStatus(widget.orderId!, status);

      
      await _loadData();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Order status updated to ${status.toUpperCase()}'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to update status: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _order != null
              ? 'Order #${_order!.orderNumber ?? _order!.id.substring(0, 6)}'
              : 'Order Details',
        ),
        actions: [
          if (_order != null)
            IconButton(
              icon: const Icon(Icons.print),
              onPressed: _isPrinting ? null : _printReceipt,
              tooltip: 'Print Receipt',
            ),
        ],
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _errorMessage != null
              ? _buildErrorView()
              : _order != null
              ? _buildOrderDetails()
              : const Center(child: Text('No order data available')),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: Colors.red),
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
          ElevatedButton(onPressed: _loadData, child: const Text('Retry')),
        ],
      ),
    );
  }

  Widget _buildOrderDetails() {
    
    final createdAt =
        _order!.createdAt != null
            ? DateFormat(
              'MMM dd, yyyy • hh:mm a',
            ).format(_order!.createdAt!.toDate())
            : 'N/A';

    final updatedAt =
        _order!.updatedAt != null
            ? DateFormat(
              'MMM dd, yyyy • hh:mm a',
            ).format(_order!.updatedAt!.toDate())
            : 'N/A';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            margin: const EdgeInsets.only(bottom: 16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Order #${_order!.orderNumber ?? _order!.id.substring(0, 6)}',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.green,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          _order!.paymentMethod.capitalize(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Created:',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                      Text(
                        createdAt,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                  if (_order!.updatedAt != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Updated:',
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(color: Colors.grey[600]),
                          ),
                          Text(
                            updatedAt,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 12),
                  
                  if (_profile != null) ...[
                    const Divider(),
                    Text(
                      _profile!.name,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (_profile!.address != null &&
                        _profile!.address!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          _profile!.formattedAddress,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ),
                  ],
                ],
              ),
            ),
          ),
          if (_order!.customerName!.isNotEmpty ||
              _order!.customerPhone!.isNotEmpty)
            Card(
              margin: const EdgeInsets.only(bottom: 16),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (_order!.customerName!.isNotEmpty)
                      Text(
                        _order!.customerName.toString(),
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    if (_order!.customerPhone!.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        '${_order!.customerPhone}',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w300,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          
          Text(
            'Order Items',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Card(
            margin: const EdgeInsets.only(bottom: 16),
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _order!.items.length,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final item = _order!.items[index];
                return ListTile(
                  title: Text(
                    item.name,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle:
                      item.notes != null && item.notes!.isNotEmpty
                          ? Text(
                            'Note: ${item.notes}',
                            style: TextStyle(
                              fontStyle: FontStyle.italic,
                              color: Colors.grey[600],
                            ),
                          )
                          : null,
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${item.quantity} x ',
                        style: TextStyle(color: Colors.grey[700]),
                      ),
                      Text(
                        '₹${item.price.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),

          
          if (_order!.notes != null && _order!.notes!.isNotEmpty) ...[
            Text(
              'Order Notes',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Card(
              margin: const EdgeInsets.only(bottom: 16),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(_order!.notes!),
              ),
            ),
          ],

          
          Text(
            'Order Summary',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Card(
            margin: const EdgeInsets.only(bottom: 24),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Total Items:'),
                      Text('${_order!.items.length}'),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Total Quantity:'),
                      Text(
                        '${_order!.items.fold(0, (sum, item) => sum + item.quantity)}',
                      ),
                    ],
                  ),
                  const Divider(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Total Amount:',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        '₹${_order!.totalAmount.toStringAsFixed(2)}',
                        style: Theme.of(
                          context,
                        ).textTheme.titleMedium?.copyWith(
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

          
          Row(
            children: [
              Expanded(
                child: AnimatedButton(
                  onPressed: () {
                    Navigator.pushReplacementNamed(
                      context,
                      AppRoutes.editBill,
                      arguments: {'orderId': widget.orderId},
                    );
                  },
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [Text('Add Food')],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: AnimatedButton(
                  onPressed: _isPrinting ? null : _printReceipt,
                  isLoading: _isPrinting,
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.print),
                      SizedBox(width: 8),
                      Text('Print Receipt'),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    Color bgColor;
    Color textColor;

    switch (status) {
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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
          color: textColor,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }
}
