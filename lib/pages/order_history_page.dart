import 'dart:convert';
import 'package:flutter/material.dart';
import '../core/api/api_client.dart';
import '../core/constants/app_colors.dart';
import '../widgets/navbar.dart';

class OrderHistoryPage extends StatefulWidget {
  const OrderHistoryPage({super.key});

  @override
  State<OrderHistoryPage> createState() => _OrderHistoryPageState();
}

class _OrderHistoryPageState extends State<OrderHistoryPage> {
  List<Map<String, dynamic>> _orders = [];
  bool _loading = true;
  String _error = '';

  String _tab = 'active'; // 'active' or 'archive'
  int _displayLimit = 5;
  int _expandedOrderId = -1;

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  Future<void> _loadOrders() async {
    setState(() => _loading = true);
    try {
      final res = await ApiClient.get('/api/commandes/me?archived=${_tab == 'archive'}');
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        _orders = (data is List) ? data.cast<Map<String, dynamic>>() : [];
      } else {
        _error = 'Failed to load orders';
      }
    } catch (e) {
      _error = 'Cannot load orders';
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _changeTab(String tab) {
    setState(() {
      _tab = tab;
      _displayLimit = 5;
      _expandedOrderId = -1;
    });
    _loadOrders();
  }

  Future<void> _archiveOrder(int id) async {
    try {
      await ApiClient.patch('/api/commandes/$id/archive');
      _loadOrders();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Cannot archive order'), backgroundColor: AppColors.error));
    }
  }

  String _fmtPrice(dynamic val) => '${(double.tryParse(val.toString()) ?? 0).toStringAsFixed(3)} TND';

  String _fmtDate(dynamic val) {
    if (val == null) return '-';
    try {
      final dt = DateTime.parse(val.toString()).toLocal();
      return '${dt.day}/${dt.month}/${dt.year} ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return val.toString();
    }
  }

  String _statusLabel(String? status) {
    switch (status) {
      case "EN_ATTENTE":
      case "EN_COURS": return "In progress";
      case "CONFIRMEE": return "Confirmed";
      case "EXPEDIEE": return "Shipped";
      case "LIVREE": return "Delivered";
      case "ANNULEE": return "Cancelled";
      default: return status ?? "-";
    }
  }

  Color _statusColor(String? status) {
    switch (status) {
      case "EN_ATTENTE":
      case "EN_COURS": return const Color(0xFF0284C7); // Blue progress
      case "CONFIRMEE":
      case "EXPEDIEE": return const Color(0xFF059669); // Green ok
      case "LIVREE": return const Color(0xFF4338CA); // Indigo done
      case "ANNULEE": return const Color(0xFFDC2626); // Red bad
      default: return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final displayedOrders = _orders.take(_displayLimit).toList();
    final hasMore = _orders.length > _displayLimit;

    return MainScaffold(
      currentIndex: 4, // Assuming 4 is Profile/Orders based on typical app routing
      child: Container(
        color: const Color(0xFFF7F7FA), // Background color matches React
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 32),
          child: Center(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 1000),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(22),
                boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 40, offset: Offset(0, 20))],
              ),
              padding: const EdgeInsets.all(28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // --- Header ---
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('My Orders', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF1E2238))),
                      ElevatedButton(
                        onPressed: () => Navigator.pushNamed(context, '/catalog'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF5F63FF),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('Shop Now', style: TextStyle(fontWeight: FontWeight.bold)),
                      )
                    ],
                  ),
                  const SizedBox(height: 24),

                  // --- Tabs ---
                  Row(
                    children: [
                      _buildTabBtn('Active', 'active'),
                      const SizedBox(width: 12),
                      _buildTabBtn('Archive', 'archive'),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // --- Content ---
                  if (_loading)
                    const Center(child: Padding(padding: EdgeInsets.all(40), child: CircularProgressIndicator(color: Colors.black)))
                  else if (_error.isNotEmpty)
                    Center(child: Padding(padding: const EdgeInsets.all(40), child: Text(_error, style: const TextStyle(color: Colors.red))))
                  else if (_orders.isEmpty)
                      Container(
                        width: double.infinity, padding: const EdgeInsets.all(40),
                        decoration: BoxDecoration(border: Border.all(color: const Color(0xFFD7D9EA)), borderRadius: BorderRadius.circular(18)),
                        child: Column(
                          children: const [
                            Text('No orders found', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1F2440))),
                            SizedBox(height: 10),
                            Text('Your validated orders will appear here.', style: TextStyle(color: Color(0xFF7F86A4))),
                          ],
                        ),
                      )
                    else
                      Column(
                        children: [
                          ExpansionPanelList(
                            elevation: 0,
                            expandedHeaderPadding: EdgeInsets.zero,
                            expansionCallback: (index, isExpanded) {
                              setState(() {
                                _expandedOrderId = isExpanded ? -1 : displayedOrders[index]['id'];
                              });
                            },
                            children: displayedOrders.map<ExpansionPanel>((order) {
                              final bool isExpanded = _expandedOrderId == order['id'];
                              return ExpansionPanel(
                                isExpanded: isExpanded,
                                canTapOnHeader: true,
                                backgroundColor: Colors.transparent,
                                headerBuilder: (context, _) => _buildOrderRow(order),
                                body: _buildOrderDetails(order),
                              );
                            }).toList(),
                          ),
                          if (hasMore)
                            Padding(
                              padding: const EdgeInsets.only(top: 24),
                              child: TextButton(
                                onPressed: () => setState(() => _displayLimit += 5),
                                style: TextButton.styleFrom(
                                  backgroundColor: const Color(0xFFF3F4F6),
                                  foregroundColor: const Color(0xFF1F2937),
                                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                                ),
                                child: Text('+ Show next ${(_orders.length - _displayLimit).clamp(0, 5)} orders', style: const TextStyle(fontWeight: FontWeight.w700)),
                              ),
                            )
                        ],
                      )
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTabBtn(String title, String tabId) {
    final bool isActive = _tab == tabId;
    return GestureDetector(
      onTap: () => _changeTab(tabId),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
        decoration: BoxDecoration(
          color: isActive ? Colors.black : const Color(0xFFECECF6),
          borderRadius: BorderRadius.circular(30),
        ),
        child: Text(
          title,
          style: TextStyle(
            color: isActive ? Colors.white : const Color(0xFF4A5568),
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  // Mimics the <tr> main row in React
  Widget _buildOrderRow(Map<String, dynamic> order) {
    final bool isMobile = MediaQuery.of(context).size.width < 700;
    final statusColor = _statusColor(order['statutCommande']);

    if (isMobile) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(order['referenceCommande'] ?? '-', style: const TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF111827))),
                Text(_fmtPrice(order['total']), style: const TextStyle(fontWeight: FontWeight.w800)),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(_fmtDate(order['dateCommande']), style: const TextStyle(color: Color(0xFF6B7280), fontSize: 13)),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: statusColor.withOpacity(0.15), borderRadius: BorderRadius.circular(20)),
                  child: Text(_statusLabel(order['statutCommande']), style: TextStyle(color: statusColor, fontSize: 11, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        children: [
          Expanded(flex: 2, child: Text(order['referenceCommande'] ?? '-', style: const TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF111827)))),
          Expanded(flex: 2, child: Text(_fmtDate(order['dateCommande']), style: const TextStyle(color: Color(0xFF6B7280), fontSize: 13))),
          Expanded(flex: 2, child: Text(_fmtPrice(order['total']), style: const TextStyle(fontWeight: FontWeight.w800))),
          Expanded(flex: 2, child:
          Align(
            alignment: Alignment.centerLeft,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(color: statusColor.withOpacity(0.15), borderRadius: BorderRadius.circular(20)),
              child: Text(_statusLabel(order['statutCommande']), style: TextStyle(color: statusColor, fontSize: 11, fontWeight: FontWeight.bold)),
            ),
          )
          ),
          Expanded(flex: 2, child: Text('${order['ville'] ?? '-'} / ${order['telephone'] ?? '-'}', style: const TextStyle(fontSize: 13, color: Color(0xFF4B5563)))),
        ],
      ),
    );
  }

  // Mimics the expanded Dropdown table in React
  Widget _buildOrderDetails(Map<String, dynamic> order) {
    final List lignes = order['lignes'] ?? [];

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16, left: 16, right: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (lignes.isEmpty)
            const Text('No line items', style: TextStyle(color: Colors.grey))
          else
            ...lignes.map((line) {
              final options = [line['couleurNom'], line['taillePointure']].where((e) => e != null && e.toString().isNotEmpty).join(' • ');
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                    Expanded(
                        flex: 3,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(line['nomProduit'] ?? '-', style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF1E293B))),
                            Text(options.isEmpty ? '—' : options, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                          ],
                        )
                    ),
                    Expanded(flex: 1, child: Text('x${line['quantite']}', textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.w500))),
                    Expanded(flex: 2, child: Text(_fmtPrice(line['sousTotal']), textAlign: TextAlign.right, style: const TextStyle(fontWeight: FontWeight.bold))),
                  ],
                ),
              );
            }).toList(),

          const Divider(height: 24, color: Color(0xFFE2E8F0)),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('💳 ${order['modePaiement'] ?? "pending"}', style: const TextStyle(fontSize: 12, color: Color(0xFF4A5568))),
                  const SizedBox(height: 4),
                  Text('📍 ${order['adresseLivraison'] ?? "No address"}', style: const TextStyle(fontSize: 12, color: Color(0xFF4A5568))),
                ],
              ),
              if (!(order['archived'] ?? false))
                TextButton(
                  onPressed: () => _archiveOrder(order['id']),
                  style: TextButton.styleFrom(backgroundColor: const Color(0xFFF1F5F9), foregroundColor: const Color(0xFF64748B)),
                  child: const Text('Archive'),
                )
              else
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(20)),
                  child: const Text('archived', style: TextStyle(color: Color(0xFF64748B), fontSize: 11)),
                )
            ],
          )
        ],
      ),
    );
  }
}