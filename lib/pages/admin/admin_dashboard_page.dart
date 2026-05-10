import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../core/constants/app_colors.dart';
import '../../core/models/admin_models.dart';
import '../../core/services/admin_service.dart';

class AdminDashboardPage extends StatefulWidget {
  const AdminDashboardPage({super.key});

  @override
  State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage> {
  bool _isLoading = true;
  String _error = '';

  // Dashboard data
  int _totalVisits = 0;
  int _visitsToday = 0;
  int _totalOrders = 0;
  double _totalRevenue = 0;
  double _averageOrderValue = 0;
  List<DailySale> _dailySales = [];
  List<TopItem> _topArticles = [];
  List<TopItem> _topCategories = [];
  List<RadarCategory> _radarCategories = [];
  Map<String, int> _ordersByStatus = {};
  Map<String, int> _ordersByPaymentStatus = {};

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    setState(() {
      _isLoading = true;
      _error = '';
    });

    try {
      final results = await Future.wait([
        AdminService.fetchVisits(),
        AdminService.fetchOrdersStats(),
        AdminService.fetchDailySales(),
        AdminService.fetchTopArticles(),
        AdminService.fetchTopCategories(),
        AdminService.fetchRadarCategories(),
      ]);

      final visitsData = results[0] as Map<String, dynamic>;
      final ordersData = results[1] as Map<String, dynamic>;
      final dailySalesData = results[2] as Map<String, dynamic>;
      final topArticlesData = results[3] as List<TopItem>;
      final topCategoriesData = results[4] as List<TopItem>;
      final radarData = results[5] as List<RadarCategory>;

      setState(() {
        _totalVisits = visitsData['totalVisits'] ?? 0;
        _visitsToday = visitsData['visitsToday'] ?? 0;
        _totalOrders = ordersData['totalOrders'] ?? 0;
        _totalRevenue = (ordersData['totalRevenue'] ?? 0).toDouble();
        _averageOrderValue = (ordersData['averageOrderValue'] ?? 0).toDouble();
        _ordersByStatus = Map<String, int>.from(ordersData['ordersByStatus'] ?? {});
        _ordersByPaymentStatus = Map<String, int>.from(ordersData['ordersByPaymentStatus'] ?? {});

        final labels = dailySalesData['labels'] as List? ?? [];
        final sales = dailySalesData['sales'] as List? ?? [];
        _dailySales = [];
        for (int i = 0; i < labels.length; i++) {
          _dailySales.add(DailySale(
            label: labels[i].toString(),
            sales: i < sales.length ? (sales[i] ?? 0).toDouble() : 0,
          ));
        }

        _topArticles = topArticlesData;
        _topCategories = topCategoriesData;
        _radarCategories = radarData;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(child: CircularProgressIndicator(color: AppColors.accent)),
      );
    }

    if (_error.isNotEmpty) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 48, color: AppColors.error),
              const SizedBox(height: 16),
              Text(_error, style: const TextStyle(color: AppColors.error)),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadDashboardData,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Dashboard'),
        backgroundColor: AppColors.surface,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadDashboardData,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            const Text('Complete Analytics', style: TextStyle(fontSize: 16, color: AppColors.textSecondary)),
            const SizedBox(height: 24),

            // KPI Cards - Fixed with proper sizing
            _buildKpiGrid(),
            const SizedBox(height: 24),

            // Daily Sales Line Chart
            _buildDailySalesChart(),
            const SizedBox(height: 24),

            // Two Doughnut Charts - Responsive
            LayoutBuilder(
              builder: (context, constraints) {
                if (constraints.maxWidth < 600) {
                  return Column(
                    children: [
                      _buildOrdersByStatusChart(),
                      const SizedBox(height: 16),
                      _buildPaymentStatusChart(),
                    ],
                  );
                } else {
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: _buildOrdersByStatusChart()),
                      const SizedBox(width: 16),
                      Expanded(child: _buildPaymentStatusChart()),
                    ],
                  );
                }
              },
            ),
            const SizedBox(height: 24),

            // Radar Chart (using BarChart as fallback)
            _buildRadarChart(),
            const SizedBox(height: 24),

            // Top Articles & Categories
            LayoutBuilder(
              builder: (context, constraints) {
                if (constraints.maxWidth < 600) {
                  return Column(
                    children: [
                      _buildTopArticlesChart(),
                      const SizedBox(height: 16),
                      _buildTopCategoriesChart(),
                    ],
                  );
                } else {
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: _buildTopArticlesChart()),
                      const SizedBox(width: 16),
                      Expanded(child: _buildTopCategoriesChart()),
                    ],
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildKpiGrid() {
    final kpis = [
      _KpiData('Total visits', _totalVisits.toString(), Icons.visibility),
      _KpiData('Visits today', _visitsToday.toString(), Icons.today),
      _KpiData('Orders', _totalOrders.toString(), Icons.shopping_bag),
      _KpiData('Revenue (€)', _totalRevenue.toStringAsFixed(2), Icons.attach_money),
      _KpiData('Avg order value', '${_averageOrderValue.toStringAsFixed(2)} €', Icons.trending_up),
    ];

    // Use Wrap with spacing instead of GridView to avoid height constraints
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: kpis.map((kpi) {
        return Container(
          width: (MediaQuery.of(context).size.width - 60) / 2,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(kpi.icon, color: AppColors.accent, size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      kpi.value,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      kpi.title,
                      style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildDailySalesChart() {
    if (_dailySales.isEmpty) {
      return _buildEmptyCard('No sales data');
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Daily Sales (last 30 days)', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
          const SizedBox(height: 16),
          SizedBox(
            height: 220,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(show: true, drawVerticalLine: false),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: true, reservedSize: 35),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: _dailySales.length > 15 ? _dailySales.length / 6 : 1,
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        if (index >= 0 && index < _dailySales.length && index % 5 == 0) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              _dailySales[index].label.length > 5
                                  ? '${_dailySales[index].label.substring(0, 5)}...'
                                  : _dailySales[index].label,
                              style: const TextStyle(fontSize: 8, color: AppColors.textSecondary),
                            ),
                          );
                        }
                        return const Text('');
                      },
                    ),
                  ),
                  rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: _dailySales.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value.sales)).toList(),
                    isCurved: true,
                    color: AppColors.accent,
                    barWidth: 2,
                    isStrokeCapRound: true,
                    dotData: FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      color: AppColors.accent.withOpacity(0.2),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrdersByStatusChart() {
    if (_ordersByStatus.isEmpty) {
      return _buildEmptyCard('No order status data');
    }

    final entries = _ordersByStatus.entries.toList();
    final colors = [AppColors.success, AppColors.warning, AppColors.error];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Orders by Status', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
          const SizedBox(height: 16),
          SizedBox(
            height: 200,
            child: PieChart(
              PieChartData(
                sections: entries.asMap().entries.map((e) {
                  final index = e.key;
                  final entry = e.value;
                  return PieChartSectionData(
                    value: entry.value.toDouble(),
                    title: entry.key.length > 10 ? '${entry.key.substring(0, 8)}...' : entry.key,
                    color: colors[index % colors.length],
                    radius: 50,
                    titleStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white),
                  );
                }).toList(),
                sectionsSpace: 2,
                centerSpaceRadius: 30,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentStatusChart() {
    if (_ordersByPaymentStatus.isEmpty) {
      return _buildEmptyCard('No payment status data');
    }

    final entries = _ordersByPaymentStatus.entries.toList();
    final colors = [AppColors.success, AppColors.error, AppColors.warning];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Payment Status', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
          const SizedBox(height: 16),
          SizedBox(
            height: 200,
            child: PieChart(
              PieChartData(
                sections: entries.asMap().entries.map((e) {
                  final index = e.key;
                  final entry = e.value;
                  return PieChartSectionData(
                    value: entry.value.toDouble(),
                    title: entry.key.length > 10 ? '${entry.key.substring(0, 8)}...' : entry.key,
                    color: colors[index % colors.length],
                    radius: 50,
                    titleStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white),
                  );
                }).toList(),
                sectionsSpace: 2,
                centerSpaceRadius: 30,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRadarChart() {
    if (_radarCategories.isEmpty) {
      return _buildEmptyCard('No category data');
    }

    final maxValue = _radarCategories.map((rc) => rc.value).reduce((a, b) => a > b ? a : b);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Category Performance', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
          const SizedBox(height: 16),
          SizedBox(
            height: 220,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: maxValue * 1.1,
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 35,
                      getTitlesWidget: (value, meta) {
                        return Text('${value.toInt()}', style: const TextStyle(fontSize: 9, color: AppColors.textSecondary));
                      },
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 50,
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        if (index >= 0 && index < _radarCategories.length) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              _radarCategories[index].name.length > 8
                                  ? '${_radarCategories[index].name.substring(0, 6)}...'
                                  : _radarCategories[index].name,
                              style: const TextStyle(fontSize: 9, color: AppColors.textSecondary),
                              textAlign: TextAlign.center,
                            ),
                          );
                        }
                        return const Text('');
                      },
                    ),
                  ),
                  rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                gridData: FlGridData(show: true),
                borderData: FlBorderData(show: false),
                barGroups: _radarCategories.asMap().entries.map((e) {
                  return BarChartGroupData(
                    x: e.key,
                    barRods: [
                      BarChartRodData(
                        toY: e.value.value,
                        color: AppColors.accent,
                        width: 25,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopArticlesChart() {
    if (_topArticles.isEmpty) {
      return _buildEmptyCard('No top articles data');
    }

    final maxRevenue = _topArticles.map((a) => a.revenue).reduce((a, b) => a > b ? a : b);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Top 5 Selling Articles', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
          const SizedBox(height: 16),
          SizedBox(
            height: 220,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: maxRevenue * 1.1,
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 35,
                      getTitlesWidget: (value, meta) {
                        return Text('${value.toInt()}', style: const TextStyle(fontSize: 9, color: AppColors.textSecondary));
                      },
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 50,
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        if (index >= 0 && index < _topArticles.length) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              _topArticles[index].name.length > 10
                                  ? '${_topArticles[index].name.substring(0, 8)}...'
                                  : _topArticles[index].name,
                              style: const TextStyle(fontSize: 9, color: AppColors.textSecondary),
                              textAlign: TextAlign.center,
                            ),
                          );
                        }
                        return const Text('');
                      },
                    ),
                  ),
                  rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                gridData: FlGridData(show: true),
                borderData: FlBorderData(show: false),
                barGroups: _topArticles.asMap().entries.map((e) {
                  return BarChartGroupData(
                    x: e.key,
                    barRods: [
                      BarChartRodData(
                        toY: e.value.revenue,
                        color: AppColors.accent,
                        width: 25,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopCategoriesChart() {
    if (_topCategories.isEmpty) {
      return _buildEmptyCard('No top categories data');
    }

    final maxRevenue = _topCategories.map((c) => c.revenue).reduce((a, b) => a > b ? a : b);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Top 5 Categories by Revenue', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
          const SizedBox(height: 16),
          SizedBox(
            height: 220,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: maxRevenue * 1.1,
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 35,
                      getTitlesWidget: (value, meta) {
                        return Text('${value.toInt()}', style: const TextStyle(fontSize: 9, color: AppColors.textSecondary));
                      },
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 50,
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        if (index >= 0 && index < _topCategories.length) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              _topCategories[index].name.length > 10
                                  ? '${_topCategories[index].name.substring(0, 8)}...'
                                  : _topCategories[index].name,
                              style: const TextStyle(fontSize: 9, color: AppColors.textSecondary),
                              textAlign: TextAlign.center,
                            ),
                          );
                        }
                        return const Text('');
                      },
                    ),
                  ),
                  rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                gridData: FlGridData(show: true),
                borderData: FlBorderData(show: false),
                barGroups: _topCategories.asMap().entries.map((e) {
                  return BarChartGroupData(
                    x: e.key,
                    barRods: [
                      BarChartRodData(
                        toY: e.value.revenue,
                        color: AppColors.accent,
                        width: 25,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyCard(String message) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: Text(message, style: const TextStyle(color: AppColors.textSecondary)),
      ),
    );
  }
}

class _KpiData {
  final String title;
  final String value;
  final IconData icon;

  _KpiData(this.title, this.value, this.icon);
}