import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/models/admin_models.dart';
import '../../core/services/admin_service.dart';

class VendeurOrdersPage extends StatefulWidget {
  const VendeurOrdersPage({super.key});

  @override
  State<VendeurOrdersPage> createState() => _VendeurOrdersPageState();
}

class _VendeurOrdersPageState extends State<VendeurOrdersPage> {
  List<VendeurOrder> _orders = [];
  List<VendeurOrder> _filteredOrders = [];
  bool _isLoading = true;
  String _error = '';
  String _searchQuery = '';

  // History modal
  VendeurOrder? _selectedOrder;
  List<VendeurOrderHistoryEntry> _historyEntries = [];
  bool _historyLoading = false;

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  Future<void> _loadOrders() async {
    setState(() {
      _isLoading = true;
      _error = '';
    });
    try {
      final orders = await AdminService.fetchVendeurOrders();
      setState(() {
        _orders = orders;
        _filteredOrders = orders;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void _filterOrders(String query) {
    setState(() {
      _searchQuery = query;
      if (query.isEmpty) {
        _filteredOrders = _orders;
      } else {
        final lowerQuery = query.toLowerCase();
        _filteredOrders = _orders.where((order) =>
        order.customerFullName.toLowerCase().contains(lowerQuery) ||
            order.referenceCommande.toLowerCase().contains(lowerQuery) ||
            order.emailClient.toLowerCase().contains(lowerQuery)
        ).toList();
      }
    });
  }

  Future<void> _showHistoryModal(VendeurOrder order) async {
    setState(() {
      _selectedOrder = order;
      _historyEntries = [];
      _historyLoading = true;
    });
    try {
      final history = await AdminService.fetchVendeurOrderHistory(order.id);
      setState(() {
        _historyEntries = history;
        _historyLoading = false;
      });
      await showDialog(
        context: context,
        builder: (context) => _OrderHistoryModal(
          order: order,
          historyEntries: _historyEntries,
          isLoading: _historyLoading,
        ),
      );
    } catch (e) {
      setState(() {
        _historyEntries = [];
        _historyLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading history: $e'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  Color _getStatusColor(String status) {
    return AdminService.getVendeurOrderStatusColor(status);
  }

  String _getStatusLabel(String status) {
    return AdminService.getVendeurOrderStatusLabel(status);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('My Orders'),
        backgroundColor: AppColors.surface,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadOrders,
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
              onPressed: _loadOrders,
              child: const Text('Retry'),
            ),
          ],
        ),
      )
          : Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: InputDecoration(
                hintText: 'Search by customer or order #...',
                hintStyle: const TextStyle(color: AppColors.textSecondary),
                prefixIcon: const Icon(Icons.search, color: AppColors.textSecondary),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                filled: true,
                fillColor: AppColors.surface,
              ),
              onChanged: _filterOrders,
            ),
          ),

          // Orders count
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Text(
                  '${_filteredOrders.length} orders found',
                  style: const TextStyle(color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // Orders list
          Expanded(
            child: _filteredOrders.isEmpty
                ? const Center(child: Text('No orders found', style: TextStyle(color: AppColors.textSecondary)))
                : ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _filteredOrders.length,
              itemBuilder: (_, i) {
                final order = _filteredOrders[i];
                final lines = order.lignesVendeur;
                final thumbs = lines.length > 3 ? lines.sublist(0, 3) : lines;
                final moreCount = lines.length - 3;
                final statusColor = _getStatusColor(order.statutCommande);
                final statusLabel = _getStatusLabel(order.statutCommande);

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  color: AppColors.card,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header row with customer and status
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Row(
                                children: [
                                  Container(
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      color: AppColors.accent.withOpacity(0.2),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Center(
                                      child: Text(
                                        order.customerFullName.isNotEmpty
                                            ? order.customerFullName.split(' ').map((p) => p.isNotEmpty ? p[0] : '').join('').toUpperCase()
                                            : 'U',
                                        style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          order.customerFullName,
                                          style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                                        ),
                                        Text(
                                          order.emailClient,
                                          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: statusColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                statusLabel,
                                style: TextStyle(fontSize: 12, color: statusColor),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // Order reference and date
                        Row(
                          children: [
                            Text(
                              order.referenceCommande,
                              style: const TextStyle(fontWeight: FontWeight.w500, color: AppColors.textPrimary),
                            ),
                            const SizedBox(width: 16),
                            Icon(Icons.calendar_today, size: 12, color: AppColors.textSecondary),
                            const SizedBox(width: 4),
                            Text(
                              _formatDate(order.dateCommande),
                              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // Product thumbnails
                        if (lines.isNotEmpty)
                          SizedBox(
                            height: 50,
                            child: Row(
                              children: [
                                ...thumbs.map((line) => Container(
                                  width: 50,
                                  height: 50,
                                  margin: const EdgeInsets.only(right: 8),
                                  decoration: BoxDecoration(
                                    color: AppColors.border,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: line.imageUrl != null && line.imageUrl!.isNotEmpty
                                        ? Image.network(
                                      line.imageUrl!,
                                      width: 50,
                                      height: 50,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) => Container(
                                        color: AppColors.border,
                                        child: Center(
                                          child: Text(
                                            line.articleNom.isNotEmpty ? line.articleNom[0].toUpperCase() : '?',
                                            style: const TextStyle(fontWeight: FontWeight.bold),
                                          ),
                                        ),
                                      ),
                                    )
                                        : Center(
                                      child: Text(
                                        line.articleNom.isNotEmpty ? line.articleNom[0].toUpperCase() : '?',
                                        style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                                      ),
                                    ),
                                  ),
                                )),
                                if (moreCount > 0)
                                  Container(
                                    width: 50,
                                    height: 50,
                                    decoration: BoxDecoration(
                                      color: AppColors.border,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Center(
                                      child: Text(
                                        '+$moreCount',
                                        style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textSecondary),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        const SizedBox(height: 12),

                        // Total and action
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Total', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                                Text(
                                  '${order.total.toStringAsFixed(2)} DT',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: AppColors.accent,
                                  ),
                                ),
                              ],
                            ),
                            OutlinedButton(
                              onPressed: () => _showHistoryModal(order),
                              style: OutlinedButton.styleFrom(
                                side: BorderSide(color: AppColors.border),
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              ),
                              child: const Text('History', style: TextStyle(color: AppColors.textPrimary)),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// Order History Modal
class _OrderHistoryModal extends StatelessWidget {
  final VendeurOrder order;
  final List<VendeurOrderHistoryEntry> historyEntries;
  final bool isLoading;

  const _OrderHistoryModal({
    required this.order,
    required this.historyEntries,
    required this.isLoading,
  });

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Order History', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                Text(order.referenceCommande, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, color: AppColors.textSecondary),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
      content: SizedBox(
        width: 450,
        height: 400,
        child: isLoading
            ? const Center(child: CircularProgressIndicator(color: AppColors.accent))
            : historyEntries.isEmpty
            ? const Center(child: Text('No history found', style: TextStyle(color: AppColors.textSecondary)))
            : ListView.separated(
          itemCount: historyEntries.length,
          separatorBuilder: (_, __) => const Divider(color: AppColors.border),
          itemBuilder: (_, i) {
            final entry = historyEntries[i];
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: AppColors.accent,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            entry.typeAction,
                            style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                          ),
                          Text(
                            _formatDate(entry.dateAction),
                            style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                if (entry.ancienStatut != null || entry.nouveauStatut != null)
                  Padding(
                    padding: const EdgeInsets.only(left: 20),
                    child: Text(
                      'From: ${entry.ancienStatut ?? '-'} → To: ${entry.nouveauStatut ?? '-'}',
                      style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                    ),
                  ),
                if (entry.details != null)
                  Padding(
                    padding: const EdgeInsets.only(left: 20, top: 4),
                    child: Text(
                      entry.details!,
                      style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                    ),
                  ),
                const SizedBox(height: 8),
              ],
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close', style: TextStyle(color: AppColors.textSecondary)),
        ),
      ],
    );
  }
}