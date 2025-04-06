import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:foodkie_express/api/order_service.dart';
import 'package:foodkie_express/models/order.dart';
import 'package:foodkie_express/routes.dart';
import 'package:foodkie_express/widgets/order_card.dart';
import 'package:lottie/lottie.dart';

class OrderHistoryScreen extends StatefulWidget {
  const OrderHistoryScreen({Key? key}) : super(key: key);

  @override
  State<OrderHistoryScreen> createState() => _OrderHistoryScreenState();
}

enum DateFilter { all, today, yesterday, lastWeek, lastMonth }

class _OrderHistoryScreenState extends State<OrderHistoryScreen> {
  String _filterStatus = 'all';
  DateFilter _dateFilter = DateFilter.all;
  DateTime? _startDate;
  DateTime? _endDate;
  bool _isFilterExpanded = false;

  final List<String> _statusFilters = [
    'all',
    'pending',
    'processing',
    'completed',
    'cancelled',
  ];

  void _setDateRange(DateFilter filter) {
    final now = DateTime.now();
    setState(() {
      _dateFilter = filter;

      switch (filter) {
        case DateFilter.all:
          _startDate = null;
          _endDate = null;
          break;
        case DateFilter.today:
          _startDate = DateTime(now.year, now.month, now.day);
          _endDate = now;
          break;
        case DateFilter.yesterday:
          final yesterday = now.subtract(const Duration(days: 1));
          _startDate = DateTime(yesterday.year, yesterday.month, yesterday.day);
          _endDate = DateTime(
            yesterday.year,
            yesterday.month,
            yesterday.day,
            23,
            59,
            59,
          );
          break;
        case DateFilter.lastWeek:
          _startDate = now.subtract(const Duration(days: 7));
          _endDate = now;
          break;
        case DateFilter.lastMonth:
          _startDate = DateTime(now.year, now.month - 1, now.day);
          _endDate = now;
          break;
      }
    });
  }

  void _showDateRangePicker() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2022),
      lastDate: DateTime.now(),
      initialDateRange: DateTimeRange(
        start: _startDate ?? DateTime.now().subtract(const Duration(days: 7)),
        end: _endDate ?? DateTime.now(),
      ),
    );

    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });
    }
  }

  // Reset all filters
  void _clearAllFilters() {
    setState(() {
      _filterStatus = 'all';
      _startDate = null;
      _endDate = null;
      _dateFilter = DateFilter.all;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Filter section with ExpansionPanelList
          ExpansionPanelList(
            expansionCallback: (int index, bool isExpanded) {
              setState(() {
                _isFilterExpanded = !_isFilterExpanded;
              });
            },
            children: [
              ExpansionPanel(
                headerBuilder: (context, isExpanded) {
                  return ListTile(
                    title: Text(
                      'Order Filters',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    trailing:  InkWell(
                      onTap: _clearAllFilters,
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: Theme.of(context).colorScheme.outline,
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                             'Clear Filters',
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
                body: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Time Period Filters
                      Text(
                        'Time Period',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: FilterChip(
                                label: const Text('All Time'),
                                selected: _dateFilter == DateFilter.all,
                                onSelected: (selected) {
                                  if (selected) {
                                    _setDateRange(DateFilter.all);
                                  }
                                },
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: FilterChip(
                                label: const Text('Today'),
                                selected: _dateFilter == DateFilter.today,
                                onSelected: (selected) {
                                  if (selected) {
                                    _setDateRange(DateFilter.today);
                                  }
                                },
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: FilterChip(
                                label: const Text('Yesterday'),
                                selected: _dateFilter == DateFilter.yesterday,
                                onSelected: (selected) {
                                  if (selected) {
                                    _setDateRange(DateFilter.yesterday);
                                  }
                                },
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: FilterChip(
                                label: const Text('Last Week'),
                                selected: _dateFilter == DateFilter.lastWeek,
                                onSelected: (selected) {
                                  if (selected) {
                                    _setDateRange(DateFilter.lastWeek);
                                  }
                                },
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: FilterChip(
                                label: const Text('Last Month'),
                                selected: _dateFilter == DateFilter.lastMonth,
                                onSelected: (selected) {
                                  if (selected) {
                                    _setDateRange(DateFilter.lastMonth);
                                  }
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Status Filters
                      Text(
                        'Order Status',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: _statusFilters.map((status) {
                            return Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: FilterChip(
                                label: Text(
                                  status == 'all'
                                      ? 'All'
                                      : StringExtension(status).capitalize(),
                                ),
                                selected: _filterStatus == status,
                                onSelected: (selected) {
                                  if (selected) {
                                    setState(() {
                                      _filterStatus = status;
                                    });
                                  }
                                },
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Custom Date Range Picker
                      InkWell(
                        onTap: _showDateRangePicker,
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: Theme.of(context).colorScheme.outline,
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.date_range),
                              const SizedBox(width: 8),
                              Text(
                                _startDate != null && _endDate != null
                                    ? '${DateFormat('MMM d').format(_startDate!)} - ${DateFormat('MMM d').format(_endDate!)}'
                                    : 'Select Date Range',
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                isExpanded: _isFilterExpanded,

              ),
            ],
          ),

          // Orders list
          Expanded(
            child: StreamBuilder<List<OrderModel>>(
              stream: Provider.of<OrderService>(context).getOrders(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                final orders = snapshot.data ?? [];

                // Apply filters
                var filteredOrders = orders;

                // Apply status filter
                if (_filterStatus != 'all') {
                  filteredOrders = filteredOrders
                      .where((order) => order.status == _filterStatus)
                      .toList();
                }

                // Apply date range filter
                if (_startDate != null && _endDate != null) {
                  final endDateWithTime = DateTime(
                    _endDate!.year,
                    _endDate!.month,
                    _endDate!.day,
                    23,
                    59,
                    59,
                  );

                  filteredOrders = filteredOrders.where((order) {
                    if (order.createdAt == null) return false;

                    final orderDate = order.createdAt!.toDate();
                    return orderDate.isAfter(_startDate!) &&
                        orderDate.isBefore(endDateWithTime);
                  }).toList();
                }

                if (filteredOrders.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Lottie.asset(
                          'assets/animations/empty_orders.json',
                          height: 200,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No orders found',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Try adjusting your filters',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: filteredOrders.length,
                  itemBuilder: (context, index) {
                    return OrderCard(
                      order: filteredOrders[index],
                      onTap: () {
                        Navigator.pushNamed(
                          context,
                          AppRoutes.orderDetails,
                          arguments: {'orderId': filteredOrders[index].id},
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// Extension to capitalize first letter of string
extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${substring(1)}";
  }
}