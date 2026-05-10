import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../core/constants/app_colors.dart';
import '../../core/models/admin_models.dart';
import '../../core/services/admin_service.dart';

class VendeurDashboardPage extends StatefulWidget {
  const VendeurDashboardPage({super.key});

  @override
  State<VendeurDashboardPage> createState() => _VendeurDashboardPageState();
}

class _VendeurDashboardPageState extends State<VendeurDashboardPage> {
  VendeurDashboardStats? _stats;
  bool _isLoading = true;
  String _error = '';

  final List<Color> _chartColors = [
    const Color(0xFF5B5EF7),
    const Color(0xFF7C3AED),
    const Color(0xFFF59E0B),
    const Color(0xFF10B981),
    const Color(0xFFEF4444),
  ];

  @override
  void initState() {
    super.initState();
    _loadDashboard();
  }

  Future<void> _loadDashboard() async {
    setState(() {
      _isLoading = true;
      _error = '';
    });
    try {
      final stats = await AdminService.fetchVendeurDashboard();
      setState(() {
        _stats = stats;
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
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Seller Dashboard'),
        backgroundColor: AppColors.surface,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadDashboard,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.accent))
          : _error.isNotEmpty
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: AppColors.error),
            const SizedBox(height: 16),
            Text(_error, style: const TextStyle(color: AppColors.error)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadDashboard,
              child: const Text('Retry'),
            ),
          ],
        ),
      )
          : _stats == null
          ? const Center(child: Text('No data available'))
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            const Text('Seller Dashboard', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
            const SizedBox(height: 4),
            const Text('Your sales performance', style: TextStyle(color: AppColors.textSecondary)),
            const SizedBox(height: 24),

            // KPI Cards
            Row(
              children: [
                Expanded(child: _buildKpiCard('Total Sales', '${_stats!.totalSales.toStringAsFixed(2)} DT', Icons.attach_money)),
                const SizedBox(width: 12),
                Expanded(child: _buildKpiCard('Total Orders', _stats!.totalOrders.toString(), Icons.shopping_bag)),
                const SizedBox(width: 12),
                Expanded(child: _buildKpiCard('Items Sold', _stats!.totalItemsSold.toString(), Icons.inventory)),
              ],
            ),
            const SizedBox(height: 24),

            // Charts Row
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: _buildTopArticlesChart()),
                const SizedBox(width: 16),
                Expanded(child: _buildTopCategoriesChart()),
              ],
            ),
            const SizedBox(height: 24),

            // Top Articles Table
            _buildTopArticlesTable(),
          ],
        ),
      ),
    );
  }

  Widget _buildKpiCard(String title, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.accent, size: 28),
          const SizedBox(height: 12),
          Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
          const SizedBox(height: 4),
          Text(title, style: const TextStyle(color: AppColors.textSecondary)),
        ],
      ),
    );
  }

  Widget _buildTopArticlesChart() {
    if (_stats!.topArticles.isEmpty) {
      return _buildEmptyChart('No top articles data');
    }

    final articles = _stats!.topArticles;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Top Selling Articles', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textPrimary)),
          const SizedBox(height: 16),
          SizedBox(
            height: 280,
            child: PieChart(
              PieChartData(
                sections: articles.asMap().entries.map((e) {
                  final index = e.key;
                  final article = e.value;
                  return PieChartSectionData(
                    value: article.totalQuantitySold.toDouble(),
                    title: article.articleNom.length > 15
                        ? '${article.articleNom.substring(0, 12)}...'
                        : article.articleNom,
                    color: _chartColors[index % _chartColors.length],
                    radius: 80,
                    titleStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white),
                    titlePositionPercentageOffset: 0.55,
                  );
                }).toList(),
                sectionsSpace: 2,
                centerSpaceRadius: 40,
                startDegreeOffset: -90,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopCategoriesChart() {
    if (_stats!.topCategories.isEmpty) {
      return _buildEmptyChart('No top categories data');
    }

    final categories = _stats!.topCategories;
    final chartColors = [
      const Color(0xFF3B82F6),
      const Color(0xFF8B5CF6),
      const Color(0xFFEC4899),
      const Color(0xFF14B8A6),
      const Color(0xFFF97316),
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Top Categories', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textPrimary)),
          const SizedBox(height: 16),
          SizedBox(
            height: 280,
            child: PieChart(
              PieChartData(
                sections: categories.asMap().entries.map((e) {
                  final index = e.key;
                  final category = e.value;
                  return PieChartSectionData(
                    value: category.totalQuantitySold.toDouble(),
                    title: category.categoryNom.length > 15
                        ? '${category.categoryNom.substring(0, 12)}...'
                        : category.categoryNom,
                    color: chartColors[index % chartColors.length],
                    radius: 80,
                    titleStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white),
                    titlePositionPercentageOffset: 0.55,
                  );
                }).toList(),
                sectionsSpace: 2,
                centerSpaceRadius: 60,
                startDegreeOffset: -90,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyChart(String message) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: Column(
          children: [
            Icon(Icons.pie_chart_outline, size: 48, color: AppColors.textSecondary),
            const SizedBox(height: 8),
            Text(message, style: const TextStyle(color: AppColors.textSecondary)),
          ],
        ),
      ),
    );
  }

  Widget _buildTopArticlesTable() {
    if (_stats!.topArticles.isEmpty) {
      return const SizedBox.shrink();
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
          const Text('Best Selling Articles (details)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textPrimary)),
          const SizedBox(height: 16),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              headingRowColor: WidgetStateProperty.all(AppColors.surface),
              dataRowColor: WidgetStateProperty.all(Colors.transparent),
              columnSpacing: 20,
              columns: const [
                DataColumn(label: Text('Article', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary))),
                DataColumn(label: Text('Quantity Sold', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary))),
                DataColumn(label: Text('Revenue', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary))),
              ],
              rows: _stats!.topArticles.map((article) {
                return DataRow(
                  cells: [
                    DataCell(Text(article.articleNom, style: const TextStyle(color: AppColors.textPrimary))),
                    DataCell(Text(article.totalQuantitySold.toString(), style: const TextStyle(color: AppColors.textPrimary))),
                    DataCell(Text('${article.totalRevenue.toStringAsFixed(2)} DT', style: const TextStyle(color: AppColors.accent, fontWeight: FontWeight.bold))),
                  ],
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}