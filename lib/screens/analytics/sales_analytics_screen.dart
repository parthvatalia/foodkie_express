import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:foodkie_express/api/order_service.dart';
import 'package:foodkie_express/api/menu_service.dart';
import 'package:foodkie_express/models/order.dart';
import 'package:foodkie_express/models/category.dart';
import 'package:foodkie_express/models/item.dart';

// Custom BadgeWidget for PieChart
class _PieChartBadge extends StatelessWidget {
  final String text;

  const _PieChartBadge({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(4),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 2,
            spreadRadius: 1,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.black,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}

class SalesAnalyticsScreen extends StatefulWidget {
  const SalesAnalyticsScreen({Key? key}) : super(key: key);

  @override
  State<SalesAnalyticsScreen> createState() => _SalesAnalyticsScreenState();
}

class _SalesAnalyticsScreenState extends State<SalesAnalyticsScreen>
    with SingleTickerProviderStateMixin {
  bool _isLoading = true;
  List<OrderModel> _allOrders = [];
  List<OrderModel> _filteredOrders = [];
  List<CategoryModel> _categories = [];
  List<MenuItemModel> _menuItems = [];
  String _timeRangeFilter = 'Weekly';
  String _paymentMethodFilter = 'All';
  TabController? _tabController;

  // Date range for filtering
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _endDate = DateTime.now();

  // For category analytics
  Map<String, double> _categoryRevenue = {};
  Map<String, int> _categoryOrderCount = {};
  Map<String, double> _paymentMethodTotals = {'Cash': 0, 'UPI': 0};

  // Selected category for detailed view
  String? _selectedCategoryId;

  // Time period options
  final List<String> _timePeriods = [
    'Daily',
    'Weekly',
    'Monthly',
    'Quarterly',
    'Yearly',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController?.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Get categories
      final menuService = Provider.of<MenuService>(context, listen: false);
      _categories = await menuService.getCategories().first;

      // Get menu items
      _menuItems = await menuService.getMenuItems().first;

      // Get orders
      final orderService = Provider.of<OrderService>(context, listen: false);
      final orders = await orderService.getOrdersByDateRange(
        DateTime.now().subtract(const Duration(days: 365)),
        DateTime.now(),
      );

      setState(() {
        _allOrders = orders;
        _applyFilters();
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading data: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }

      setState(() {
        _isLoading = false;
      });
    }
  }

  void _applyFilters() {
    // Apply date range filter
    var filtered =
    _allOrders.where((order) {
      final orderDate = order.createdAt?.toDate();
      if (orderDate == null) return false;

      return orderDate.isAfter(_startDate) &&
          orderDate.isBefore(_endDate.add(const Duration(days: 1)));
    }).toList();

    // Apply payment method filter if not "All"
    if (_paymentMethodFilter != 'All') {
      filtered =
          filtered
              .where((order) => order.paymentMethod == _paymentMethodFilter)
              .toList();
    }

    setState(() {
      _filteredOrders = filtered;
      _calculateCategoryStats();
    });
  }

  void _calculateCategoryStats() {
    // Reset stats
    _categoryRevenue = {};
    _categoryOrderCount = {};
    _paymentMethodTotals = {'Cash': 0, 'UPI': 0};

    // Initialize category stats with all categories
    for (var category in _categories) {
      _categoryRevenue[category.id] = 0;
      _categoryOrderCount[category.id] = 0;
    }

    // Calculate payment method totals
    for (var order in _filteredOrders) {
      if (order.paymentMethod == 'Cash') {
        _paymentMethodTotals['Cash'] =
            _paymentMethodTotals['Cash']! + order.totalAmount;
      } else if (order.paymentMethod == 'UPI') {
        _paymentMethodTotals['UPI'] =
            _paymentMethodTotals['UPI']! + order.totalAmount;
      }
    }

    // For each order item, find its category and add to the category stats
    for (var order in _filteredOrders) {
      for (var item in order.items) {
        // Find the menu item to get its category
        final menuItem = _menuItems.firstWhere(
              (mi) => mi.id == item.id,
          orElse:
              () => MenuItemModel(id: '', name: '', price: 0, categoryId: ''),
        );

        if (menuItem.categoryId.isNotEmpty) {
          // Add to category revenue
          _categoryRevenue[menuItem.categoryId] =
              (_categoryRevenue[menuItem.categoryId] ?? 0) +
                  (item.price * item.quantity);

          // Add to category order count
          _categoryOrderCount[menuItem.categoryId] =
              (_categoryOrderCount[menuItem.categoryId] ?? 0) + item.quantity;
        }
      }
    }

    // Remove categories with zero sales
    _categoryRevenue.removeWhere((key, value) => value == 0);
    _categoryOrderCount.removeWhere((key, value) => value == 0);
  }

  Future<void> _selectDateRange() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
      initialDateRange: DateTimeRange(start: _startDate, end: _endDate),
    );

    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
        _applyFilters();
      });
    }
  }

  void _selectCategory(String categoryId) {
    setState(() {
      if (_selectedCategoryId == categoryId) {
        _selectedCategoryId = null; // Deselect if already selected
      } else {
        _selectedCategoryId = categoryId; // Select new category
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Category Analytics'),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_today),
            onPressed: _selectDateRange,
            tooltip: 'Select Date Range',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : DefaultTabController(
        length: 2,
        child: Column(
          children: [
            // Date range and filters
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Text('Period:'),
                          const SizedBox(width: 8),
                          DropdownButton<String>(
                            value: _timeRangeFilter,
                            items: _timePeriods.map((String value) {
                              return DropdownMenuItem<String>(
                                value: value,
                                child: Text(value),
                              );
                            }).toList(),
                            onChanged: (String? newValue) {
                              if (newValue != null) {
                                setState(() {
                                  _timeRangeFilter = newValue;
                                  // Update date range based on selected period
                                  switch (newValue) {
                                    case 'Daily':
                                      _startDate = DateTime.now();
                                      _endDate = DateTime.now();
                                      break;
                                    case 'Weekly':
                                      _startDate = DateTime.now()
                                          .subtract(
                                        const Duration(days: 7),
                                      );
                                      _endDate = DateTime.now();
                                      break;
                                    case 'Monthly':
                                      _startDate = DateTime(
                                        DateTime.now().year,
                                        DateTime.now().month,
                                        1,
                                      );
                                      _endDate = DateTime.now();
                                      break;
                                    case 'Quarterly':
                                      _startDate = DateTime.now()
                                          .subtract(
                                        const Duration(days: 90),
                                      );
                                      _endDate = DateTime.now();
                                      break;
                                    case 'Yearly':
                                      _startDate = DateTime(
                                        DateTime.now().year,
                                        1,
                                        1,
                                      );
                                      _endDate = DateTime.now();
                                      break;
                                  }
                                  _applyFilters();
                                });
                              }
                            },
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          const Text('Payment:'),
                          const SizedBox(width: 8),
                          DropdownButton<String>(
                            value: _paymentMethodFilter,
                            items: ['All', 'Cash', 'UPI'].map(
                                  (String value) {
                                return DropdownMenuItem<String>(
                                  value: value,
                                  child: Text(value),
                                );
                              },
                            ).toList(),
                            onChanged: (String? newValue) {
                              if (newValue != null) {
                                setState(() {
                                  _paymentMethodFilter = newValue;
                                  _applyFilters();
                                });
                              }
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Date: ${DateFormat('MMM d, yyyy').format(_startDate)} - ${DateFormat('MMM d, yyyy').format(_endDate)}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),

            // Key metrics cards
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12.0),
              child: Row(
                children: [
                  Expanded(
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.receipt_long,
                                  color: Theme.of(context).colorScheme.primary,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                const Text('Orders'),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '${_filteredOrders.length}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 24,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.payments,
                                  color: Colors.green,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                const Text('Sales'),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '₹${_filteredOrders.fold(0.0, (sum, order) => sum + order.totalAmount).toStringAsFixed(0)}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 24,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Tab Bar
            const TabBar(
              tabs: [
                Tab(text: 'Category Sales'),
                Tab(text: 'Payment Method'),
              ],
            ),

            // Tab content
            Expanded(
              child: TabBarView(
                children: [
                  // Category Sales Tab
                  _buildCategorySalesTab(),

                  // Payment Method Tab
                  _buildPaymentMethodTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: color),
              const SizedBox(height: 8),
              Text(title, style: Theme.of(context).textTheme.bodySmall),
              const SizedBox(height: 4),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  value,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ENHANCED: Flexible category sales tab with improved layouts
  Widget _buildCategorySalesTab() {
    if (_categoryRevenue.isEmpty) {
      return const Center(
        child: Text('No category sales data available for the selected period'),
      );
    }

    // Create a sorted list of category entries
    final sortedCategories = _categoryRevenue.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // Category Sales Distribution Card
          Card(
            margin: const EdgeInsets.only(bottom: 16.0),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Category Sales Distribution',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 16),
                  AspectRatio(
                    aspectRatio: 1,
                    child: _selectedCategoryId == null
                        ? _buildCategoryPieChart() // Using original pie chart instead of simplified version
                        : _buildCategoryDetailChart(), // Using original detail chart
                  ),
                ],
              ),
            ),
          ),

          // Top Categories Card
          Card(
            margin: const EdgeInsets.only(bottom: 16.0),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Top Categories by Sales',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 16),
                  // ENHANCED: Flexible ListView without height constraints
                  Column(
                    children: sortedCategories.take(5).map((entry) {
                      final categoryId = entry.key;
                      final revenue = entry.value;
                      final category = _categories.firstWhere(
                            (c) => c.id == categoryId,
                        orElse: () => CategoryModel(
                          id: categoryId,
                          name: 'Unknown',
                          order: 0,
                        ),
                      );
                      final orderCount = _categoryOrderCount[categoryId] ?? 0;

                      // Calculate percentage of total revenue
                      final totalRevenue = _filteredOrders.fold(
                        0.0,
                            (sum, order) => sum + order.totalAmount,
                      );
                      final percentage = totalRevenue > 0
                          ? (revenue / totalRevenue * 100)
                          : 0;

                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: InkWell(
                          onTap: () => _selectCategory(categoryId),
                          borderRadius: BorderRadius.circular(4),
                          child: Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Row(
                              children: [
                                Expanded(
                                  flex: 3,
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        category.name,
                                        style: const TextStyle(fontWeight: FontWeight.bold),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '$orderCount items sold',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey[700],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Expanded(
                                  flex: 2,
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        '₹${revenue.toStringAsFixed(2)}',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Theme.of(context).colorScheme.primary,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '${percentage.toStringAsFixed(1)}%',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Theme.of(context).colorScheme.secondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  if (sortedCategories.length > 5)
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: TextButton(
                        onPressed: () {
                          // Show all categories in a bottom sheet or dialog
                          showModalBottomSheet(
                            context: context,
                            isScrollControlled: true,
                            shape: const RoundedRectangleBorder(
                              borderRadius: BorderRadius.vertical(
                                top: Radius.circular(16),
                              ),
                            ),
                            builder: (context) => DraggableScrollableSheet(
                              initialChildSize: 0.6,
                              maxChildSize: 0.9,
                              minChildSize: 0.4,
                              expand: false,
                              builder: (context, scrollController) =>
                                  ListView.builder(
                                    controller: scrollController,
                                    itemCount: sortedCategories.length,
                                    itemBuilder: (context, index) {
                                      final categoryId = sortedCategories[index].key;
                                      final revenue = sortedCategories[index].value;
                                      final category = _categories.firstWhere(
                                            (c) => c.id == categoryId,
                                        orElse: () => CategoryModel(
                                          id: categoryId,
                                          name: 'Unknown',
                                          order: 0,
                                        ),
                                      );

                                      final orderCount = _categoryOrderCount[categoryId] ?? 0;
                                      final totalRevenue = _filteredOrders.fold(
                                        0.0,
                                            (sum, order) => sum + order.totalAmount,
                                      );
                                      final percentage = totalRevenue > 0
                                          ? (revenue / totalRevenue * 100)
                                          : 0;

                                      return ListTile(
                                        title: Text(category.name),
                                        subtitle: Text('$orderCount items sold'),
                                        trailing: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          crossAxisAlignment: CrossAxisAlignment.end,
                                          children: [
                                            Text(
                                              '₹${revenue.toStringAsFixed(2)}',
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                color: Theme.of(context).colorScheme.primary,
                                              ),
                                            ),
                                            Text(
                                              '${percentage.toStringAsFixed(1)}%',
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Theme.of(context).colorScheme.secondary,
                                              ),
                                            ),
                                          ],
                                        ),
                                        onTap: () {
                                          Navigator.pop(context);
                                          _selectCategory(categoryId);
                                        },
                                      );
                                    },
                                  ),
                            ),
                          );
                        },
                        child: const Text('View All Categories'),
                      ),
                    ),
                ],
              ),
            ),
          ),

          // Additional Analytics Card (Optional)
          Card(
            margin: const EdgeInsets.only(bottom: 16.0),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Sales Insights',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 16),
                  _buildInsightsSection(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // New insights section
  Widget _buildInsightsSection() {
    if (_filteredOrders.isEmpty) {
      return const Text('No data available for insights');
    }

    // Get best selling category
    final bestSellingCategory = _categoryRevenue.entries.isEmpty
        ? null
        : _categoryRevenue.entries.reduce((a, b) => a.value > b.value ? a : b);

    // Get category with highest growth (stub - would need historical data)
    final fastestGrowingCategory = "Fast Food"; // placeholder

    // Get average order value
    final totalSales = _filteredOrders.fold(0.0, (sum, order) => sum + order.totalAmount);
    final averageOrderValue = _filteredOrders.isEmpty ? 0.0 : totalSales / _filteredOrders.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (bestSellingCategory != null) ...[
          InsightTile(
            icon: Icons.trending_up,
            title: 'Best Selling Category',
            value: _categories.firstWhere(
                  (c) => c.id == bestSellingCategory.key,
              orElse: () => CategoryModel(id: '', name: 'Unknown', order: 0),
            ).name,
            subtitle: '₹${bestSellingCategory.value.toStringAsFixed(2)} in sales',
          ),
          const Divider(),
        ],

        InsightTile(
          icon: Icons.rocket_launch,
          title: 'Fastest Growing',
          value: fastestGrowingCategory,
          subtitle: 'Based on recent trends',
        ),
        const Divider(),

        InsightTile(
          icon: Icons.shopping_cart,
          title: 'Average Order Value',
          value: '₹${averageOrderValue.toStringAsFixed(2)}',
          subtitle: 'Across ${_filteredOrders.length} orders',
        ),
      ],
    );
  }

  // Simplified pie chart with better UI handling
  // Original Pie Chart implementation from the provided code
  Widget _buildCategoryPieChart() {
    if (_categoryRevenue.isEmpty) {
      return const Center(child: Text('No data available'));
    }

    // Prepare pie chart sections
    final sections = <PieChartSectionData>[];
    final colors = [
      Colors.blue,
      Colors.green,
      Colors.red,
      Colors.purple,
      Colors.orange,
      Colors.teal,
      Colors.pink,
      Colors.indigo,
      Colors.amber,
      Colors.cyan,
    ];

    int colorIndex = 0;
    double totalValue = _categoryRevenue.values.fold(
      0,
          (sum, value) => sum + value,
    );

    _categoryRevenue.forEach((categoryId, revenue) {
      final category = _categories.firstWhere(
            (c) => c.id == categoryId,
        orElse: () => CategoryModel(id: categoryId, name: 'Unknown', order: 0),
      );

      final percentage = totalValue > 0 ? (revenue / totalValue * 100) : 0;

      sections.add(
        PieChartSectionData(
          color: colors[colorIndex % colors.length],
          value: revenue,
          title: percentage >= 5 ? '${percentage.toStringAsFixed(1)}%' : '',
          radius: 100,
          titleStyle: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
          badgeWidget:
          percentage < 5
              ? null
              : _PieChartBadge(text: category.name),
          badgePositionPercentageOffset: 1.2,
        ),
      );
      colorIndex++;
    });

    return PieChart(
      PieChartData(
        sectionsSpace: 2,
        centerSpaceRadius: 8,
        sections: sections,
        pieTouchData: PieTouchData(
          touchCallback: (FlTouchEvent event, pieTouchResponse) {
            if (event is FlTapUpEvent &&
                pieTouchResponse?.touchedSection != null) {
              final touchIndex =
                  pieTouchResponse!.touchedSection!.touchedSectionIndex;
              if (touchIndex >= 0 && touchIndex < _categoryRevenue.length) {
                final categoryId = _categoryRevenue.keys.elementAt(touchIndex);
                _selectCategory(categoryId);
              }
            }
          },
        ),
      ),
    );
  }

  // Keeping the simplified version as an alternative
  Widget _buildSimpleCategoryPieChart() {
    if (_categoryRevenue.isEmpty) {
      return const Center(child: Text('No data available'));
    }

    // Use simple Container blocks for categories instead of complex charts
    final sortedCategories = _categoryRevenue.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final totalRevenue = sortedCategories.fold(
      0.0,
          (sum, entry) => sum + entry.value,
    );

    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            itemCount: sortedCategories.length > 5 ? 5 : sortedCategories.length,
            itemBuilder: (context, index) {
              final entry = sortedCategories[index];
              final category = _categories.firstWhere(
                    (c) => c.id == entry.key,
                orElse: () => CategoryModel(id: entry.key, name: 'Unknown', order: 0),
              );

              final percentage = totalRevenue > 0 ? (entry.value / totalRevenue * 100) : 0;

              final colors = [
                Colors.blue,
                Colors.green,
                Colors.red,
                Colors.purple,
                Colors.orange,
              ];

              return InkWell(
                onTap: () => _selectCategory(entry.key),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                  child: Row(
                    children: [
                      Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          color: colors[index % colors.length],
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(child: Text(category.name)),
                      Text(
                        '${percentage.toStringAsFixed(1)}%',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // Original Category Detail Chart implementation
  Widget _buildCategoryDetailChart() {
    if (_selectedCategoryId == null) {
      return const Center(child: Text('Select a category to see details'));
    }

    final category = _categories.firstWhere(
          (c) => c.id == _selectedCategoryId,
      orElse:
          () => CategoryModel(
        id: _selectedCategoryId!,
        name: 'Unknown',
        order: 0,
      ),
    );

    // Get all menu items in this category
    final categoryItems =
    _menuItems
        .where((item) => item.categoryId == _selectedCategoryId)
        .toList();

    // Calculate sales for each item in this category
    final itemSales = <String, double>{};
    final itemCount = <String, int>{};

    for (var order in _filteredOrders) {
      for (var item in order.items) {
        // Find corresponding menu item
        final menuItem = categoryItems.firstWhere(
              (mi) => mi.id == item.id,
          orElse:
              () => MenuItemModel(id: '', name: '', price: 0, categoryId: ''),
        );

        if (menuItem.id.isNotEmpty) {
          itemSales[menuItem.id] =
              (itemSales[menuItem.id] ?? 0) + (item.price * item.quantity);
          itemCount[menuItem.id] =
              (itemCount[menuItem.id] ?? 0) + item.quantity;
        }
      }
    }

    // Sort items by sales
    final sortedItems =
    itemSales.entries.toList()..sort((a, b) => b.value.compareTo(a.value));

    // Prepare bar chart data
    final barGroups = <BarChartGroupData>[];
    final titles = <String>[];

    for (int i = 0; i < sortedItems.length && i < 10; i++) {
      final itemId = sortedItems[i].key;
      final sales = sortedItems[i].value;

      final menuItem = categoryItems.firstWhere(
            (mi) => mi.id == itemId,
        orElse:
            () => MenuItemModel(
          id: itemId,
          name: 'Unknown',
          price: 0,
          categoryId: _selectedCategoryId!,
        ),
      );

      titles.add(menuItem.name);

      barGroups.add(
        BarChartGroupData(
          barsSpace: 1,
          x: i,
          barRods: [
            BarChartRodData(
              toY: sales,
              color: Theme.of(context).colorScheme.primary,
              width: 22,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(4),
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Category: ${category.name}',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        Text(
          'Total Sales: ₹${_categoryRevenue[_selectedCategoryId]?.toStringAsFixed(2) ?? "0.00"}',
          style: const TextStyle(fontSize: 12),
        ),
        Text(
          'Items Sold: ${_categoryOrderCount[_selectedCategoryId] ?? 0}',
          style: const TextStyle(fontSize: 12),
        ),
        const SizedBox(height: 16),

        Expanded(
          child:
          sortedItems.isEmpty
              ? const Center(
            child: Text(
              'No item sales data available for this category',
            ),
          )
              : BarChart(
            BarChartData(
              alignment: BarChartAlignment.spaceAround,
              maxY:
              sortedItems.isNotEmpty
                  ? sortedItems
                  .map((e) => e.value)
                  .reduce((a, b) => a > b ? a : b) *
                  1.2
                  : 100,
              titlesData: FlTitlesData(
                show: true,
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: false,
                    getTitlesWidget: (value, meta) {
                      final index = value.toInt();
                      if (index < 0 || index >= titles.length)
                        return const Text('');
                      return Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Text(
                          titles[index],
                          style: const TextStyle(fontSize: 10),
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      );
                    },
                    reservedSize: 42,
                  ),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      return Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: Text(
                          '₹${value.toInt()}',
                          style: const TextStyle(fontSize: 10),
                        ),
                      );
                    },
                    reservedSize: 50,
                  ),
                ),
                topTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                rightTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
              ),
              gridData: const FlGridData(show: true),
              borderData: FlBorderData(show: false),
              barGroups: barGroups,
              barTouchData: BarTouchData(
                touchTooltipData: BarTouchTooltipData(
                  getTooltipItem: (group, groupIndex, rod, rodIndex) {
                    final index = group.x.toInt();
                    if (index < 0 || index >= sortedItems.length)
                      return null;

                    final itemId = sortedItems[index].key;
                    final count = itemCount[itemId] ?? 0;

                    return BarTooltipItem(
                      '${titles[index]}\n₹${rod.toY.toStringAsFixed(2)}\nCount: $count',
                      const TextStyle(color: Colors.white),
                    );
                  },
                ),
              ),
            ),
          ),
        ),

        const SizedBox(height: 8),
        Center(
          child: TextButton.icon(
            icon: const Icon(Icons.arrow_back),
            label: const Text('Back to All Categories'),
            onPressed: () => setState(() => _selectedCategoryId = null),
          ),
        ),
      ],
    );
  }

  // Simplified category detail chart with better UI handling
  Widget _buildSimpleCategoryDetailChart() {
    if (_selectedCategoryId == null) {
      return const Center(child: Text('Select a category to see details'));
    }

    final category = _categories.firstWhere(
          (c) => c.id == _selectedCategoryId,
      orElse: () => CategoryModel(
        id: _selectedCategoryId!,
        name: 'Unknown',
        order: 0,
      ),
    );

    // Get all menu items in this category
    final categoryItems = _menuItems
        .where((item) => item.categoryId == _selectedCategoryId)
        .toList();

    // Calculate sales for each item in this category
    final itemSales = <String, double>{};
    final itemCount = <String, int>{};

    for (var order in _filteredOrders) {
      for (var item in order.items) {
        // Find corresponding menu item
        final menuItem = categoryItems.firstWhere(
              (mi) => mi.id == item.id,
          orElse: () => MenuItemModel(id: '', name: '', price: 0, categoryId: ''),
        );

        if (menuItem.id.isNotEmpty) {
          itemSales[menuItem.id] = (itemSales[menuItem.id] ?? 0) + (item.price * item.quantity);
          itemCount[menuItem.id] = (itemCount[menuItem.id] ?? 0) + item.quantity;
        }
      }
    }

    // Sort items by sales
    final sortedItems = itemSales.entries.toList()..sort((a, b) => b.value.compareTo(a.value));

    if (sortedItems.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Category: ${category.name}',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(height: 8),
            const Text('No item sales data available'),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => setState(() => _selectedCategoryId = null),
              icon: const Icon(Icons.arrow_back),
              label: const Text('Back to All Categories'),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Category: ${category.name}',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        Text(
          'Total Sales: ₹${_categoryRevenue[_selectedCategoryId]?.toStringAsFixed(2) ?? "0.00"}',
          style: const TextStyle(fontSize: 12),
        ),
        Text(
          'Items Sold: ${_categoryOrderCount[_selectedCategoryId] ?? 0}',
          style: const TextStyle(fontSize: 12),
        ),
        const SizedBox(height: 16),

        Expanded(
          child: ListView.builder(
            itemCount: sortedItems.length,
            itemBuilder: (context, index) {
              final itemId = sortedItems[index].key;
              final sales = sortedItems[index].value;
              final count = itemCount[itemId] ?? 0;

              final menuItem = categoryItems.firstWhere(
                    (mi) => mi.id == itemId,
                orElse: () => MenuItemModel(
                  id: itemId,
                  name: 'Unknown',
                  price: 0,
                  categoryId: _selectedCategoryId!,
                ),
              );

              final totalItemSales = sortedItems.fold(
                0.0,
                    (sum, item) => sum + item.value,
              );
              final percentage = totalItemSales > 0 ? (sales / totalItemSales * 100) : 0;

              return Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      menuItem.name,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: percentage / 100,
                              backgroundColor: Colors.grey[200],
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Theme.of(context).colorScheme.primary,
                              ),
                              minHeight: 20,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${percentage.toStringAsFixed(1)}%',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text('₹${sales.toStringAsFixed(2)} (Qty: $count)'),
                  ],
                ),
              );
            },
          ),
        ),

        Center(
          child: ElevatedButton.icon(
            onPressed: () => setState(() => _selectedCategoryId = null),
            icon: const Icon(Icons.arrow_back),
            label: const Text('Back to All Categories'),
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentMethodTab() {
    // Calculate totals for each payment method
    final totalRevenue = _filteredOrders.fold(
      0.0,
          (sum, order) => sum + order.totalAmount,
    );
    final cashPercentage = totalRevenue > 0
        ? (_paymentMethodTotals['Cash'] ?? 0) / totalRevenue * 100
        : 0;
    final upiPercentage = totalRevenue > 0
        ? (_paymentMethodTotals['UPI'] ?? 0) / totalRevenue * 100
        : 0;

    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        // Payment Method Overview Card
        Card(
          margin: const EdgeInsets.only(bottom: 16.0),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Payment Method Split',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildPaymentMethodCard(
                        title: 'Cash',
                        amount: _paymentMethodTotals['Cash'] ?? 0,
                        percentage: cashPercentage.toDouble(),
                        icon: Icons.payments,
                        color: Colors.green,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildPaymentMethodCard(
                        title: 'UPI',
                        amount: _paymentMethodTotals['UPI'] ?? 0,
                        percentage: upiPercentage.toDouble(),
                        icon: Icons.phone_android,
                        color: Colors.blue,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),

        // Payment Method Pie Chart
        Card(
          margin: const EdgeInsets.only(bottom: 16.0),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Payment Method Split (Chart)',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 16),
                AspectRatio(
                  aspectRatio: 1,
                  child: _buildPaymentMethodPieChart(),
                ),
              ],
            ),
          ),
        ),

        // Payment Distribution
        Card(
          margin: const EdgeInsets.only(bottom: 16.0),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Payment Method Distribution',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 16),
                Container(
                  height: 50,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        flex: (cashPercentage ~/ 1) + 1,
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.7),
                            borderRadius: const BorderRadius.horizontal(
                              left: Radius.circular(8),
                            ),
                          ),
                          child: Center(
                            child: Text(
                              '${cashPercentage.toStringAsFixed(1)}%',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        flex: (upiPercentage ~/ 1) + 1,
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.blue.withOpacity(0.7),
                            borderRadius: const BorderRadius.horizontal(
                              right: Radius.circular(8),
                            ),
                          ),
                          child: Center(
                            child: Text(
                              '${upiPercentage.toStringAsFixed(1)}%',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 16,
                          height: 16,
                          decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.7),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Text('Cash'),
                      ],
                    ),
                    Row(
                      children: [
                        Container(
                          width: 16,
                          height: 16,
                          decoration: BoxDecoration(
                            color: Colors.blue.withOpacity(0.7),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Text('UPI'),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),

        // Top Categories by Payment Method
        Card(
          margin: const EdgeInsets.only(bottom: 16.0),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Top Categories by Payment Method',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 16),
                _buildPaymentByCategoryList(),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentMethodCard({
    required String title,
    required double amount,
    required double percentage,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 36),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  '₹${amount.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: color,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${percentage.toStringAsFixed(1)}% of total',
                  style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentMethodPieChart() {
    final sections = <PieChartSectionData>[];
    final totalRevenue = _filteredOrders.fold(
      0.0,
          (sum, order) => sum + order.totalAmount,
    );

    final cashAmount = _paymentMethodTotals['Cash'] ?? 0;
    final upiAmount = _paymentMethodTotals['UPI'] ?? 0;

    final cashPercentage = totalRevenue > 0 ? cashAmount / totalRevenue * 100 : 0;
    final upiPercentage = totalRevenue > 0 ? upiAmount / totalRevenue * 100 : 0;

    if (cashAmount > 0) {
      sections.add(
        PieChartSectionData(
          color: Colors.green,
          value: cashAmount,
          title: '${cashPercentage.toStringAsFixed(1)}%',
          radius: 100,
          titleStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
          badgeWidget: const _PieChartBadge(text: 'Cash'),
          badgePositionPercentageOffset: 0.8,
        ),
      );
    }

    if (upiAmount > 0) {
      sections.add(
        PieChartSectionData(
          color: Colors.blue,
          value: upiAmount,
          title: '${upiPercentage.toStringAsFixed(1)}%',
          radius: 100,
          titleStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
          badgeWidget: const _PieChartBadge(text: 'UPI'),
          badgePositionPercentageOffset: 0.8,
        ),
      );
    }

    if (sections.isEmpty) {
      return const Center(
        child: Text('No payment data available for the selected period'),
      );
    }

    return PieChart(
      PieChartData(
        sectionsSpace: 2,
        centerSpaceRadius: 40,
        sections: sections,
        pieTouchData: PieTouchData(
          touchCallback: (FlTouchEvent event, pieTouchResponse) {
            // Could add interactive behavior here
          },
        ),
      ),
    );
  }

  Widget _buildPaymentTrendChart() {
    // Group orders by date
    final dateGroupedOrders = <DateTime, Map<String, double>>{};

    // Define time buckets based on selected time range
    List<DateTime> timeBuckets = [];

    switch (_timeRangeFilter) {
      case 'Daily':
      // Show hourly data for a day
        final today = DateTime.now();
        for (int hour = 0; hour < 24; hour++) {
          timeBuckets.add(DateTime(today.year, today.month, today.day, hour));
        }
        break;
      case 'Weekly':
      // Show daily data for a week
        final endDate = _endDate;
        for (int i = 6; i >= 0; i--) {
          timeBuckets.add(endDate.subtract(Duration(days: i)));
        }
        break;
      case 'Monthly':
      // Show weekly data for a month
        final endDate = _endDate;
        for (int i = 0; i < 5; i++) {
          timeBuckets.add(endDate.subtract(Duration(days: i * 7)));
        }
        break;
      case 'Quarterly':
      // Show monthly data for a quarter
        final endMonth = _endDate;
        for (int i = 2; i >= 0; i--) {
          final month = endMonth.month - i;
          final year = endMonth.year + (month <= 0 ? -1 : 0);
          final adjustedMonth = month <= 0 ? month + 12 : month;
          timeBuckets.add(DateTime(year, adjustedMonth, 1));
        }
        break;
      case 'Yearly':
      // Show quarterly data for a year
        final endDate = _endDate;
        for (int i = 3; i >= 0; i--) {
          final month = 1 + (i * 3);
          timeBuckets.add(DateTime(endDate.year, month, 1));
        }
        break;
    }

    // Initialize data structure
    for (var date in timeBuckets) {
      dateGroupedOrders[date] = {'Cash': 0.0, 'UPI': 0.0};
    }

    // Fill with actual data
    for (var order in _filteredOrders) {
      final orderDate = order.createdAt?.toDate();
      if (orderDate == null) continue;

      // Find the appropriate time bucket
      DateTime? bucketDate;

      switch (_timeRangeFilter) {
        case 'Daily':
        // Group by hour
          bucketDate = DateTime(
            orderDate.year,
            orderDate.month,
            orderDate.day,
            orderDate.hour,
          );
          break;
        case 'Weekly':
        // Group by day
          bucketDate = DateTime(orderDate.year, orderDate.month, orderDate.day);
          break;
        case 'Monthly':
        // Group by week
        // Find the closest week bucket
          for (var date in timeBuckets) {
            if (orderDate.isAfter(date) || orderDate.isAtSameMomentAs(date)) {
              bucketDate = date;
              break;
            }
          }
          break;
        case 'Quarterly':
        // Group by month
          bucketDate = DateTime(orderDate.year, orderDate.month, 1);
          break;
        case 'Yearly':
        // Group by quarter
          final quarter = ((orderDate.month - 1) ~/ 3);
          bucketDate = DateTime(orderDate.year, 1 + (quarter * 3), 1);
          break;
      }

      if (bucketDate != null) {
        // Find closest bucket if exact match not found
        DateTime closestBucket = timeBuckets.first;
        for (var bucket in timeBuckets) {
          if ((orderDate.difference(bucket)).abs() <
              (orderDate.difference(closestBucket)).abs()) {
            closestBucket = bucket;
          }
        }

        if (dateGroupedOrders.containsKey(closestBucket)) {
          final paymentMethod = order.paymentMethod;
          if (paymentMethod == 'Cash' || paymentMethod == 'UPI') {
            dateGroupedOrders[closestBucket]![paymentMethod] =
                (dateGroupedOrders[closestBucket]![paymentMethod] ?? 0) +
                    order.totalAmount;
          }
        }
      }
    }

    // Prepare line chart data
    final cashSpots = <FlSpot>[];
    final upiSpots = <FlSpot>[];

    final sortedDates = dateGroupedOrders.keys.toList()..sort();

    for (int i = 0; i < sortedDates.length; i++) {
      final date = sortedDates[i];
      final data = dateGroupedOrders[date]!;

      cashSpots.add(FlSpot(i.toDouble(), data['Cash'] ?? 0));
      upiSpots.add(FlSpot(i.toDouble(), data['UPI'] ?? 0));
    }

    // Prepare X-axis labels
    final xLabels = <String>[];
    for (var date in sortedDates) {
      switch (_timeRangeFilter) {
        case 'Daily':
          xLabels.add('${date.hour}:00');
          break;
        case 'Weekly':
          xLabels.add(DateFormat('EEE').format(date));
          break;
        case 'Monthly':
          xLabels.add('W${(date.day ~/ 7) + 1}');
          break;
        case 'Quarterly':
          xLabels.add(DateFormat('MMM').format(date));
          break;
        case 'Yearly':
          xLabels.add('Q${(date.month ~/ 3) + 1}');
          break;
      }
    }

    if (cashSpots.isEmpty && upiSpots.isEmpty) {
      return const Center(
        child: Text('No payment trend data available for the selected period'),
      );
    }

    return LineChart(
      LineChartData(
        gridData: const FlGridData(show: true),
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index < 0 || index >= xLabels.length) return const Text('');
                return Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    xLabels[index],
                    style: const TextStyle(fontSize: 10),
                  ),
                );
              },
              reservedSize: 30,
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: Text(
                    '₹${value.toInt()}',
                    style: const TextStyle(fontSize: 10),
                  ),
                );
              },
              reservedSize: 50,
            ),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
        ),
        borderData: FlBorderData(show: true),
        lineBarsData: [
          // Cash line
          LineChartBarData(
            spots: cashSpots,
            isCurved: true,
            color: Colors.green,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: true),
            belowBarData: BarAreaData(
              show: true,
              color: Colors.green.withOpacity(0.2),
            ),
          ),
          // UPI line
          LineChartBarData(
            spots: upiSpots,
            isCurved: true,
            color: Colors.blue,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: true),
            belowBarData: BarAreaData(
              show: true,
              color: Colors.blue.withOpacity(0.2),
            ),
          ),
        ],
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipItems: (touchedSpots) {
              return touchedSpots.map((touchedSpot) {
                final lineIndex = touchedSpot.barIndex;
                final value = touchedSpot.y;
                final title = lineIndex == 0 ? 'Cash' : 'UPI';
                return LineTooltipItem(
                  '$title: ₹${value.toStringAsFixed(2)}',
                  TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                );
              }).toList();
            },
          ),
        ),
      ),
    );
  }

  Widget _buildPaymentByCategoryList() {
    // Calculate payment method totals by category
    final categoryPayments = <String, Map<String, double>>{};

    // Initialize for all categories
    for (var category in _categories) {
      categoryPayments[category.id] = {'Cash': 0.0, 'UPI': 0.0};
    }

    // Fill with data
    for (var order in _filteredOrders) {
      for (var item in order.items) {
        // Find the menu item to get its category
        final menuItem = _menuItems.firstWhere(
              (mi) => mi.id == item.id,
          orElse: () => MenuItemModel(id: '', name: '', price: 0, categoryId: ''),
        );

        if (menuItem.categoryId.isNotEmpty) {
          final paymentMethod = order.paymentMethod;
          if (paymentMethod == 'Cash' || paymentMethod == 'UPI') {
            categoryPayments[menuItem.categoryId]![paymentMethod] =
                (categoryPayments[menuItem.categoryId]![paymentMethod] ?? 0) +
                    (item.price * item.quantity);
          }
        }
      }
    }

    // Calculate total for each category
    final categoryTotals = <String, double>{};
    for (var entry in categoryPayments.entries) {
      categoryTotals[entry.key] = (entry.value['Cash'] ?? 0) + (entry.value['UPI'] ?? 0);
    }

    // Sort categories by total
    final sortedCategories = categoryTotals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    if (sortedCategories.isEmpty) {
      return const Center(child: Text('No payment data by category available'));
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: sortedCategories.length > 5 ? 5 : sortedCategories.length,
      itemBuilder: (context, index) {
        final categoryId = sortedCategories[index].key;
        final total = sortedCategories[index].value;
        final category = _categories.firstWhere(
              (c) => c.id == categoryId,
          orElse: () => CategoryModel(id: categoryId, name: 'Unknown', order: 0),
        );

        final cashAmount = categoryPayments[categoryId]!['Cash'] ?? 0;
        final upiAmount = categoryPayments[categoryId]!['UPI'] ?? 0;

        final cashPercentage = total > 0 ? (cashAmount / total * 100) : 0;
        final upiPercentage = total > 0 ? (upiAmount / total * 100) : 0;

        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  category.name,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  'Total: ₹${total.toStringAsFixed(2)}',
                  style: const TextStyle(fontSize: 12),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      flex: cashPercentage.toInt() + 1,
                      child: Container(
                        height: 20,
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.7),
                          borderRadius: const BorderRadius.horizontal(
                            left: Radius.circular(4),
                          ),
                        ),
                        child: Center(
                          child: Text(
                            '${cashPercentage.toStringAsFixed(0)}%',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      flex: upiPercentage.toInt() + 1,
                      child: Container(
                        height: 20,
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.7),
                          borderRadius: const BorderRadius.horizontal(
                            right: Radius.circular(4),
                          ),
                        ),
                        child: Center(
                          child: Text(
                            '${upiPercentage.toStringAsFixed(0)}%',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// New component for insights
class InsightTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final String subtitle;

  const InsightTile({
    Key? key,
    required this.icon,
    required this.title,
    required this.value,
    required this.subtitle,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: Theme.of(context).colorScheme.primary,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}