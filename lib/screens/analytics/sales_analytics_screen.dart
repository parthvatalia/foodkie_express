import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:foodkie_express/api/order_service.dart';
import 'package:foodkie_express/models/order.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_charts/flutter_charts.dart';

class SalesAnalyticsScreen extends StatefulWidget {
  const SalesAnalyticsScreen({Key? key}) : super(key: key);

  @override
  State<SalesAnalyticsScreen> createState() => _SalesAnalyticsScreenState();
}

class _SalesAnalyticsScreenState extends State<SalesAnalyticsScreen> with SingleTickerProviderStateMixin {
  bool _isLoading = true;
  List<OrderModel> _allOrders = [];
  List<OrderModel> _filteredOrders = [];
  String _timeRangeFilter = 'Daily';
  String _paymentMethodFilter = 'All';
  TabController? _tabController;

  // Total amounts
  double _totalSales = 0;
  int _totalOrders = 0;
  double _averageOrderValue = 0;
  Map<String, double> _paymentMethodTotals = {
    'Cash': 0,
    'UPI': 0,
  };

  // Date range for filtering
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _endDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController!.addListener(_handleTabChange);
    _loadOrders();
  }

  @override
  void dispose() {
    _tabController?.dispose();
    super.dispose();
  }

  void _handleTabChange() {
    if (_tabController!.indexIsChanging) {
      setState(() {
        switch (_tabController!.index) {
          case 0:
            _timeRangeFilter = 'Daily';
            break;
          case 1:
            _timeRangeFilter = 'Weekly';
            break;
          case 2:
            _timeRangeFilter = 'Monthly';
            break;
        }
        _applyFilters();
      });
    }
  }

  Future<void> _loadOrders() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final orderService = Provider.of<OrderService>(context, listen: false);

      // Load orders from the last 90 days
      final startDate = DateTime.now().subtract(const Duration(days: 90));
      final endDate = DateTime.now();

      final orders = await orderService.getOrdersByDateRange(startDate, endDate);

      // Set initial date range based on available data
      if (orders.isNotEmpty) {
        final firstOrderDate = orders.last.createdAt?.toDate() ?? startDate;
        _startDate = firstOrderDate.isAfter(startDate) ? startDate : firstOrderDate;
      }

      setState(() {
        _allOrders = orders;
        _applyFilters();
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading orders: ${e.toString()}'),
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
    // Filter by date range
    var filtered = _allOrders.where((order) {
      final orderDate = order.createdAt?.toDate();
      if (orderDate == null) return false;

      return orderDate.isAfter(_startDate) &&
          orderDate.isBefore(_endDate.add(const Duration(days: 1)));
    }).toList();

    // Filter by payment method if not "All"
    if (_paymentMethodFilter != 'All') {
      filtered = filtered.where((order) =>
      order.paymentMethod == _paymentMethodFilter).toList();
    }

    // Calculate totals
    _totalSales = filtered.fold(0, (sum, order) => sum + order.totalAmount);
    _totalOrders = filtered.length;
    _averageOrderValue = _totalOrders > 0 ? _totalSales / _totalOrders : 0;

    // Calculate payment method totals
    _paymentMethodTotals = {
      'Cash': filtered.where((o) => o.paymentMethod == 'Cash')
          .fold(0, (sum, order) => sum + order.totalAmount),
      'UPI': filtered.where((o) => o.paymentMethod == 'UPI')
          .fold(0, (sum, order) => sum + order.totalAmount),
    };

    setState(() {
      _filteredOrders = filtered;
    });
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sales Analytics'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Daily'),
            Tab(text: 'Weekly'),
            Tab(text: 'Monthly'),
          ],
        ),
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
          : Column(
        children: [
          // Payment Method Filter
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                const Text('Payment Method:'),
                const SizedBox(width: 16),
                DropdownButton<String>(
                  value: _paymentMethodFilter,
                  items: ['All', 'Cash', 'UPI'].map((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    if (newValue != null) {
                      setState(() {
                        _paymentMethodFilter = newValue;
                        _applyFilters();
                      });
                    }
                  },
                ),
                const Spacer(),
                Text(
                  'Date: ${DateFormat('MMM d').format(_startDate)} - ${DateFormat('MMM d').format(_endDate)}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),

          // Summary Cards
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              children: [
                _buildSummaryCard(
                  title: 'Total Sales',
                  value: '₹${_totalSales.toStringAsFixed(2)}',
                  icon: Icons.attach_money,
                  color: Colors.green,
                ),
                const SizedBox(width: 16),
                _buildSummaryCard(
                  title: 'Orders',
                  value: _totalOrders.toString(),
                  icon: Icons.receipt_long,
                  color: Colors.blue,
                ),
                const SizedBox(width: 16),
                _buildSummaryCard(
                  title: 'Avg Order',
                  value: '₹${_averageOrderValue.toStringAsFixed(2)}',
                  icon: Icons.shopping_cart,
                  color: Colors.purple,
                ),
              ],
            ),
          ),

          // Payment Method Breakdown
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Payment Method Breakdown',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _buildPaymentMethodCard(
                            title: 'Cash',
                            amount: _paymentMethodTotals['Cash'] ?? 0,
                            icon: Icons.money,
                            color: Colors.green,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildPaymentMethodCard(
                            title: 'UPI',
                            amount: _paymentMethodTotals['UPI'] ?? 0,
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
          ),

          // Chart
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: _buildChart(),
                ),
              ),
            ),
          ),
        ],
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
              Text(
                title,
                style: Theme.of(context).textTheme.bodySmall,
              ),
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

  Widget _buildPaymentMethodCard({
    required String title,
    required double amount,
    required IconData icon,
    required Color color,
  }) {
    final percentage = _totalSales > 0 ? (amount / _totalSales * 100) : 0.0;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '₹${amount.toStringAsFixed(2)}',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          Text(
            '${percentage.toStringAsFixed(1)}%',
            style: TextStyle(color: color, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildChart() {
    if (_filteredOrders.isEmpty) {
      return const Center(
        child: Text('No data available for the selected period'),
      );
    }

    switch (_timeRangeFilter) {
      case 'Daily':
        return _buildDailyChart();
      case 'Weekly':
        return _buildWeeklyChart();
      case 'Monthly':
        return _buildMonthlyChart();
      default:
        return _buildDailyChart();
    }
  }




  Widget _buildDailyChart() {
    // Group orders by day
    final Map<DateTime, List<OrderModel>> groupedData = {};

    for (var order in _filteredOrders) {
      if (order.createdAt != null) {
        final date = DateTime(
          order.createdAt!.toDate().year,
          order.createdAt!.toDate().month,
          order.createdAt!.toDate().day,
        );

        if (!groupedData.containsKey(date)) {
          groupedData[date] = [];
        }

        groupedData[date]!.add(order);
      }
    }

    // Create chart data
    final sortedDates = groupedData.keys.toList()..sort((a, b) => a.compareTo(b));

    // If no data, show message
    if (sortedDates.isEmpty) {
      return const Center(
        child: Text('No daily data available for the selected period'),
      );
    }

    // Calculate max value for scaling
    double maxSales = 0;
    for (var date in sortedDates) {
      final dayTotal = groupedData[date]!.fold(0.0,
              (sum, order) => sum + order.totalAmount);
      if (dayTotal > maxSales) {
        maxSales = dayTotal;
      }
    }

    return Column(
      children: [
        const Padding(
          padding: EdgeInsets.all(8.0),
          child: Text("Daily Sales", style: TextStyle(fontWeight: FontWeight.bold)),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 20, bottom: 10),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final chartWidth = constraints.maxWidth;
                final chartHeight = constraints.maxHeight;
                final barWidth = (chartWidth - 40) / sortedDates.length;

                return Stack(
                  children: [
                    // Y-axis line (left side)
                    Positioned(
                      left: 30,
                      top: 0,
                      bottom: 20,
                      child: Container(
                        width: 1,
                        color: Colors.grey,
                      ),
                    ),

                    // X-axis line (bottom)
                    Positioned(
                      left: 30,
                      right: 10,
                      bottom: 20,
                      child: Container(
                        height: 1,
                        color: Colors.grey,
                      ),
                    ),

                    // Y-axis labels
                    Positioned(
                      left: 0,
                      top: 0,
                      bottom: 20,
                      width: 30,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text('₹${maxSales.toInt()}', style: const TextStyle(fontSize: 10)),
                          Text('₹${(maxSales / 2).toInt()}', style: const TextStyle(fontSize: 10)),
                          const Text('₹0', style: TextStyle(fontSize: 10)),
                        ],
                      ),
                    ),

                    // Bars
                    Positioned(
                      left: 30,
                      right: 10,
                      top: 0,
                      bottom: 0,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: List.generate(sortedDates.length, (index) {
                          final date = sortedDates[index];
                          final dayTotal = groupedData[date]!.fold(0.0,
                                  (sum, order) => sum + order.totalAmount);

                          // Calculate bar height as percentage of max value
                          final barHeight = maxSales > 0
                              ? (dayTotal / maxSales) * (chartHeight - 30)
                              : 0.0;

                          return Tooltip(
                            message: '${DateFormat('MMM d').format(date)}\n₹${dayTotal.toStringAsFixed(2)}',
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                Container(
                                  width: barWidth > 20 ? 20 : barWidth - 4,
                                  height: barHeight,
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).colorScheme.primary,
                                    borderRadius: const BorderRadius.vertical(
                                        top: Radius.circular(4)
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 5),
                                SizedBox(
                                  width: barWidth,
                                  child: Text(
                                    DateFormat(barWidth > 40 ? 'MMM d' : 'd').format(date),
                                    style: const TextStyle(fontSize: 9),
                                    textAlign: TextAlign.center,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                )
                              ],
                            ),
                          );
                        }),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildWeeklyChart() {
    // Group orders by week
    final Map<String, List<OrderModel>> groupedData = {};

    for (var order in _filteredOrders) {
      if (order.createdAt != null) {
        final date = order.createdAt!.toDate();
        // Calculate week number
        final weekNumber = (date.difference(DateTime(date.year, 1, 1)).inDays / 7).ceil();
        final weekKey = '${date.year}-W$weekNumber';

        if (!groupedData.containsKey(weekKey)) {
          groupedData[weekKey] = [];
        }

        groupedData[weekKey]!.add(order);
      }
    }

    // Create chart data
    final List<String> weekLabels = [];
    final List<BarChartGroupData> barGroups = [];

    final sortedWeeks = groupedData.keys.toList()..sort();

    for (int i = 0; i < sortedWeeks.length; i++) {
      final week = sortedWeeks[i];
      final totalForWeek = groupedData[week]!
          .fold(0.0, (sum, order) => sum + order.totalAmount);

      // Use week number for label
      final weekNumber = week.split('-W')[1];
      weekLabels.add('W$weekNumber');

      barGroups.add(
        BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(
              toY: totalForWeek,
              color: Theme.of(context).colorScheme.primary,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
              width: 20,
            ),
          ],
        ),
      );
    }

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              return BarTooltipItem(
                '₹${rod.toY.toStringAsFixed(2)}',
                const TextStyle(color: Colors.white),
              );
            },
          ),
        ),
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index >= 0 && index < weekLabels.length) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      weekLabels[index],
                      style: const TextStyle(fontSize: 10),
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              getTitlesWidget: (value, meta) {
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: Text(
                    '₹${value.toInt()}',
                    style: const TextStyle(fontSize: 10),
                  ),
                );
              },
            ),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
        ),
        borderData: FlBorderData(
          show: true,
        ),
        barGroups: barGroups,
      ),
    );
  }

  Widget _buildMonthlyChart() {
    // Group orders by month
    final Map<String, List<OrderModel>> groupedData = {};

    for (var order in _filteredOrders) {
      if (order.createdAt != null) {
        final date = order.createdAt!.toDate();
        final monthKey = '${date.year}-${date.month.toString().padLeft(2, '0')}';

        if (!groupedData.containsKey(monthKey)) {
          groupedData[monthKey] = [];
        }

        groupedData[monthKey]!.add(order);
      }
    }

    // Prepare data for pie chart
    final List<PieChartSectionData> sections = [];
    final Map<String, double> monthlySales = {};

    for (var entry in groupedData.entries) {
      final monthTotal = entry.value.fold(0.0, (sum, order) => sum + order.totalAmount);
      monthlySales[entry.key] = monthTotal;
    }

    // Convert to proper month names for display
    final Map<String, String> monthNames = {};
    for (var monthKey in monthlySales.keys) {
      final parts = monthKey.split('-');
      final year = int.parse(parts[0]);
      final month = int.parse(parts[1]);

      monthNames[monthKey] = DateFormat('MMM yyyy').format(DateTime(year, month));
    }

    // Create pie chart sections with different colors
    final List<Color> sectionColors = [
      Colors.blue,
      Colors.green,
      Colors.red,
      Colors.purple,
      Colors.orange,
      Colors.teal,
      Colors.pink,
      Colors.amber,
      Colors.indigo,
      Colors.cyan,
      Colors.brown,
      Colors.lime,
    ];

    int colorIndex = 0;
    for (var entry in monthlySales.entries) {
      sections.add(
        PieChartSectionData(
          color: sectionColors[colorIndex % sectionColors.length],
          value: entry.value,
          title: '${monthNames[entry.key]}\n₹${entry.value.toStringAsFixed(0)}',
          radius: 100,
          titleStyle: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      );
      colorIndex++;
    }

    // If we have data, show the pie chart
    if (sections.isNotEmpty) {
      return Column(
        children: [
          Expanded(
            child: PieChart(
              PieChartData(
                sectionsSpace: 2,
                centerSpaceRadius: 40,
                sections: sections,
                borderData:  FlBorderData(show: false),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Monthly Revenue Distribution',
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ],
      );
    } else {
      return const Center(
        child: Text('No monthly data available'),
      );
    }
  }
}