import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/constants/app_colors.dart';
import '../../core/models/admin_models.dart';
import '../../core/services/admin_service.dart';

class AdminOrdersPage extends StatefulWidget {
  const AdminOrdersPage({super.key});

  @override
  State<AdminOrdersPage> createState() => _AdminOrdersPageState();
}

class _AdminOrdersPageState extends State<AdminOrdersPage> {
  List<AdminOrder> _allOrders = [];
  List<AdminOrder> _filteredOrders = [];
  bool _isLoading = true;
  String _error = '';
  int? _busyOrderId;

  // Filters
  String _searchQuery = '';
  OrderTab _currentTab = OrderTab.pending;
  String _sortBy = 'newest';
  int _currentPage = 1;
  static const int _pageSize = 5;

  // History modal
  AdminOrder? _selectedOrder;
  List<OrderHistoryEntry> _historyEntries = [];
  bool _historyLoading = false;
  String _historyError = '';

  // Payments modal
  AdminOrder? _selectedOrderForPayments;
  List<PaymentTransaction> _paymentsList = [];
  bool _paymentsLoading = false;
  String _paymentsError = '';

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
      final orders = await AdminService.fetchOrders();
      setState(() {
        _allOrders = orders;
        _applyFilters();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void _applyFilters() {
    List<AdminOrder> filtered = _allOrders.where((order) {
      final tabKey = OrderTabExtension.fromOrderStatus(order.statutCommande);
      return tabKey == _currentTab;
    }).toList();

    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      filtered = filtered.where((order) {
        final customerName = order.customerFullName.toLowerCase();
        final ref = order.referenceCommande.toLowerCase();
        final email = order.emailClient.toLowerCase();
        final phone = (order.telephone ?? '').toLowerCase();
        return customerName.contains(query) ||
            ref.contains(query) ||
            email.contains(query) ||
            phone.contains(query);
      }).toList();
    }

    switch (_sortBy) {
      case 'oldest':
        filtered.sort((a, b) => a.dateCommande.compareTo(b.dateCommande));
        break;
      case 'amount-high':
        filtered.sort((a, b) => b.total.compareTo(a.total));
        break;
      case 'amount-low':
        filtered.sort((a, b) => a.total.compareTo(b.total));
        break;
      default:
        filtered.sort((a, b) => b.dateCommande.compareTo(a.dateCommande));
    }

    setState(() {
      _filteredOrders = filtered;
      _currentPage = 1;
    });
  }

  List<AdminOrder> get _pagedOrders {
    final start = (_currentPage - 1) * _pageSize;
    final end = start + _pageSize;
    if (start >= _filteredOrders.length) return [];
    return _filteredOrders.sublist(start, end > _filteredOrders.length ? _filteredOrders.length : end);
  }

  int get _totalPages => (_filteredOrders.length / _pageSize).ceil();

  Future<void> _confirmOrder(int id) async {
    setState(() => _busyOrderId = id);
    try {
      await AdminService.confirmOrder(id);
      await _loadOrders();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Order confirmed')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      setState(() => _busyOrderId = null);
    }
  }

  Future<void> _cancelOrder(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Order'),
        content: const Text('Are you sure you want to cancel this order?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('No')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Yes, Cancel', style: TextStyle(color: AppColors.error))),
        ],
      ),
    );
    if (confirm != true) return;

    setState(() => _busyOrderId = id);
    try {
      await AdminService.cancelOrder(id);
      await _loadOrders();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Order cancelled')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      setState(() => _busyOrderId = null);
    }
  }

  Future<void> _markDelivered(int id) async {
    setState(() => _busyOrderId = id);
    try {
      await AdminService.markDelivered(id);
      await _loadOrders();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Order marked as delivered')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      setState(() => _busyOrderId = null);
    }
  }

  Future<void> _reviewPayment(int id, bool accepted) async {
    setState(() => _busyOrderId = id);
    try {
      await AdminService.reviewPayment(id, accepted);
      await _loadOrders();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(accepted ? 'Payment accepted' : 'Payment rejected')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      setState(() => _busyOrderId = null);
    }
  }

  Future<void> _showHistoryModal(AdminOrder order) async {
    setState(() {
      _selectedOrder = order;
      _historyEntries = [];
      _historyLoading = true;
      _historyError = '';
    });
    try {
      final history = await AdminService.fetchOrderHistory(order.id);
      setState(() {
        _historyEntries = history;
        _historyLoading = false;
      });
      await showDialog(
        context: context,
        builder: (context) => OrderHistoryModal(
          order: order,
          historyEntries: _historyEntries,
          isLoading: _historyLoading,
          error: _historyError,
        ),
      );
    } catch (e) {
      setState(() {
        _historyError = e.toString();
        _historyLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading history: $e'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  Future<void> _showPaymentsModal(AdminOrder order) async {
    setState(() {
      _selectedOrderForPayments = order;
      _paymentsList = [];
      _paymentsLoading = true;
      _paymentsError = '';
    });
    try {
      final payments = await AdminService.fetchOrderPayments(order.id);
      setState(() {
        _paymentsList = payments;
        _paymentsLoading = false;
      });
      await showDialog(
        context: context,
        builder: (context) => PaymentsModal(
          order: order,
          payments: _paymentsList,
          isLoading: _paymentsLoading,
          error: _paymentsError,
        ),
      );
    } catch (e) {
      setState(() {
        _paymentsError = e.toString();
        _paymentsLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading payments: $e'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  void _openUrl(String url) async {
    final Uri uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Order Management'),
        backgroundColor: AppColors.surface,
        elevation: 0,
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadOrders, tooltip: 'Refresh'),
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
            ElevatedButton(onPressed: _loadOrders, child: const Text('Retry')),
          ],
        ),
      )
          : Column(
        children: [
          // Search and Sort bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    style: const TextStyle(color: AppColors.textPrimary),
                    decoration: InputDecoration(
                      hintText: 'Search orders...',
                      hintStyle: const TextStyle(color: AppColors.textSecondary),
                      prefixIcon: const Icon(Icons.search, color: AppColors.textSecondary),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      filled: true,
                      fillColor: AppColors.surface,
                    ),
                    onChanged: (value) {
                      _searchQuery = value;
                      _applyFilters();
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.border),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _sortBy,
                      dropdownColor: AppColors.surface,
                      style: const TextStyle(color: AppColors.textPrimary),
                      items: const [
                        DropdownMenuItem(value: 'newest', child: Text('Sort: Newest')),
                        DropdownMenuItem(value: 'oldest', child: Text('Sort: Oldest')),
                        DropdownMenuItem(value: 'amount-high', child: Text('Sort: Amount high')),
                        DropdownMenuItem(value: 'amount-low', child: Text('Sort: Amount low')),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          _sortBy = value;
                          _applyFilters();
                        }
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Tabs
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: OrderTab.values.map((tab) {
                final isActive = _currentTab == tab;
                return Expanded(
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _currentTab = tab;
                        _applyFilters();
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                            color: isActive ? AppColors.accent : Colors.transparent,
                            width: 2,
                          ),
                        ),
                      ),
                      child: Text(
                        tab.label,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: isActive ? AppColors.accent : AppColors.textSecondary,
                          fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),

          // Orders list
          _filteredOrders.isEmpty
              ? const Expanded(child: Center(child: Text('No orders found')))
              : Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _pagedOrders.length,
              itemBuilder: (_, i) {
                final order = _pagedOrders[i];
                final isBusy = _busyOrderId == order.id;
                final statusUpper = order.statutCommande.toUpperCase();
                final isConfirmed = statusUpper == 'CONFIRMEE';
                final isCancelled = statusUpper == 'ANNULEE';
                final isDelivered = statusUpper == 'LIVREE';
                final paymentStatusUpper = order.statutPaiement.toUpperCase();
                final isPaymentAccepted = paymentStatusUpper == 'ACCEPTE';
                final isPaymentRejected = paymentStatusUpper == 'REFUSE';

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  color: AppColors.card,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
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
                                            ? order.customerFullName.split(' ').map((p) => p[0]).join('').toUpperCase()
                                            : 'U',
                                        style: const TextStyle(fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(order.customerFullName, style: const TextStyle(fontWeight: FontWeight.bold)),
                                        Text(order.emailClient, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: AdminService.getOrderStatusColor(order.statutCommande).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                AdminService.getOrderStatusLabel(order.statutCommande),
                                style: TextStyle(color: AdminService.getOrderStatusColor(order.statutCommande), fontSize: 12),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Text(order.referenceCommande, style: const TextStyle(fontWeight: FontWeight.w500)),
                            const SizedBox(width: 16),
                            Icon(Icons.calendar_today, size: 12, color: AppColors.textSecondary),
                            const SizedBox(width: 4),
                            Text(_formatDate(order.dateCommande), style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        if (order.lignes.isNotEmpty)
                          SizedBox(
                            height: 50,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount: order.lignes.length > 3 ? 3 : order.lignes.length,
                              itemBuilder: (_, j) {
                                final line = order.lignes[j];
                                return Container(
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
                                      errorBuilder: (_, __, ___) => Icon(Icons.image_not_supported, size: 30, color: AppColors.textSecondary),
                                    )
                                        : Center(
                                      child: Text(
                                        (line.articleNom ?? '?')[0].toUpperCase(),
                                        style: const TextStyle(fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            const Text('Total: ', style: TextStyle(color: AppColors.textSecondary)),
                            Text(
                              '${order.total.toStringAsFixed(2)} DT',
                              style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.accent, fontSize: 16),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _buildActionButton('History', () => _showHistoryModal(order), isBusy),
                            _buildActionButton('Payments', () => _showPaymentsModal(order), isBusy),
                            if (!isConfirmed && !isCancelled && !isDelivered)
                              _buildActionButton('Confirm', () => _confirmOrder(order.id), isBusy, primary: true),
                            if (!isCancelled && !isDelivered)
                              _buildActionButton('Cancel', () => _cancelOrder(order.id), isBusy, isDanger: true),
                            if (!isDelivered && isConfirmed)
                              _buildActionButton('Delivered', () => _markDelivered(order.id), isBusy, primary: true),
                            if (!isPaymentAccepted && !isPaymentRejected && !isDelivered)
                              _buildActionButton('Accept Payment', () => _reviewPayment(order.id, true), isBusy, primary: true),
                            if (!isPaymentAccepted && !isPaymentRejected && !isDelivered)
                              _buildActionButton('Reject Payment', () => _reviewPayment(order.id, false), isBusy, isDanger: true),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Text('Payment: ', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: AdminService.getPaymentStatusColor(order.statutPaiement).withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      order.statutPaiement,
                                      style: TextStyle(fontSize: 10, color: AdminService.getPaymentStatusColor(order.statutPaiement)),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(order.modePaiement, style: const TextStyle(fontSize: 12)),
                                ],
                              ),
                              if (order.cardLast4 != null)
                                Text('Card **** ${order.cardLast4}', style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                              if (order.d17Phone != null)
                                Text('D17: ${order.d17Phone}', style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                              if (order.paymentInstructions != null)
                                Text(order.paymentInstructions!, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            if (order.invoiceUrl != null)
                              TextButton.icon(
                                onPressed: () => _openUrl(order.invoiceUrl!),
                                icon: const Icon(Icons.receipt, size: 16),
                                label: const Text('Invoice'),
                              ),
                            if (order.signatureDataUrl != null)
                              TextButton.icon(
                                onPressed: () => _openUrl(order.signatureDataUrl!),
                                icon: const Icon(Icons.edit, size: 16),
                                label: const Text('Signature'),
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

          // Pagination
          if (_totalPages > 1)
            Container(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left),
                    onPressed: _currentPage > 1 ? () => setState(() => _currentPage--) : null,
                  ),
                  Text('Page $_currentPage of $_totalPages'),
                  IconButton(
                    icon: const Icon(Icons.chevron_right),
                    onPressed: _currentPage < _totalPages ? () => setState(() => _currentPage++) : null,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildActionButton(String label, VoidCallback onPressed, bool isBusy, {bool primary = false, bool isDanger = false}) {
    return ElevatedButton(
      onPressed: isBusy ? null : onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: primary ? AppColors.accent : (isDanger ? AppColors.error : AppColors.card),
        foregroundColor: primary || isDanger ? Colors.white : AppColors.textPrimary,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        minimumSize: const Size(0, 32),
      ),
      child: Text(label, style: const TextStyle(fontSize: 12)),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}

// ============== HISTORY MODAL (OUTSIDE THE STATE CLASS) ==============
class OrderHistoryModal extends StatelessWidget {
  final AdminOrder order;
  final List<OrderHistoryEntry> historyEntries;
  final bool isLoading;
  final String error;

  const OrderHistoryModal({
    super.key,
    required this.order,
    required this.historyEntries,
    required this.isLoading,
    required this.error,
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
                const Text('Order History', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                Text(order.referenceCommande, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
              ],
            ),
          ),
          IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
        ],
      ),
      content: SizedBox(
        width: 500,
        height: 400,
        child: isLoading
            ? const Center(child: CircularProgressIndicator(color: AppColors.accent))
            : error.isNotEmpty
            ? Center(child: Text(error, style: const TextStyle(color: AppColors.error)))
            : historyEntries.isEmpty
            ? const Center(child: Text('No history found'))
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
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.accent.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(entry.typeAction, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500)),
                    ),
                    const SizedBox(width: 8),
                    Text(_formatDate(entry.dateAction), style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                  ],
                ),
                const SizedBox(height: 8),
                if (entry.ancienStatut != null || entry.nouveauStatut != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text('Status: ${entry.ancienStatut ?? '-'} → ${entry.nouveauStatut ?? '-'}', style: const TextStyle(fontSize: 12)),
                  ),
                if (entry.details != null)
                  Text(entry.details!, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                if (entry.utilisateurNom != null)
                  Text('By: ${entry.utilisateurNom}', style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
              ],
            );
          },
        ),
      ),
    );
  }
}

// ============== PAYMENTS MODAL (OUTSIDE THE STATE CLASS) ==============
class PaymentsModal extends StatelessWidget {
  final AdminOrder order;
  final List<PaymentTransaction> payments;
  final bool isLoading;
  final String error;

  const PaymentsModal({
    super.key,
    required this.order,
    required this.payments,
    required this.isLoading,
    required this.error,
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
                const Text('Payment Transactions', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                Text(order.referenceCommande, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
              ],
            ),
          ),
          IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
        ],
      ),
      content: SizedBox(
        width: 550,
        height: 400,
        child: isLoading
            ? const Center(child: CircularProgressIndicator(color: AppColors.accent))
            : error.isNotEmpty
            ? Center(child: Text(error, style: const TextStyle(color: AppColors.error)))
            : payments.isEmpty
            ? const Center(child: Text('No payment records found'))
            : ListView.separated(
          itemCount: payments.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (_, i) {
            final pmt = payments[i];
            final statusColor = AdminService.getPaymentStatusColor(pmt.statutPaiement);
            return Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Text(pmt.modePaiement, style: const TextStyle(fontWeight: FontWeight.bold)),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: statusColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(pmt.statutPaiement, style: TextStyle(fontSize: 10, color: statusColor)),
                          ),
                        ],
                      ),
                      Text('${pmt.montant.toStringAsFixed(2)} DT', style: const TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.calendar_today, size: 12, color: AppColors.textSecondary),
                      const SizedBox(width: 4),
                      Text(_formatDate(pmt.datePaiement), style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                      if (pmt.referenceTransaction != null) ...[
                        const SizedBox(width: 16),
                        Icon(Icons.receipt, size: 12, color: AppColors.textSecondary),
                        const SizedBox(width: 4),
                        Text('Ref: ${pmt.referenceTransaction}', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                      ],
                    ],
                  ),
                  if (pmt.details != null) ...[
                    const SizedBox(height: 8),
                    Text(pmt.details!, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                  ],
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}