import 'package:flutter/material.dart';
import '../widgets/admin_shell.dart';

class OrdersPage extends StatelessWidget {
  const OrdersPage({super.key});

  @override
  Widget build(BuildContext context) {
    return AdminShell(
      title: 'Orders',
      panelTitle: 'Administrator Panel',
      currentPath: '/admin/orders',
      child: AdminPageFrame(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const AdminSectionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AdminSectionTitle(
                    title: 'Orders management',
                    subtitle: 'Order rows, status badges, customer info, totals, and action controls.',
                  ),
                  SizedBox(height: 14),
                  AdminSearchField(hint: 'Search by customer or order...'),
                ],
              ),
            ),
            const SizedBox(height: 18),
            const Column(
              children: [
                _OrderCard(
                  customer: 'Mohamed Khayati',
                  reference: '#CMD-1001',
                  date: '04 May 2026',
                  total: '178.500 TND',
                  status: 'Pending',
                ),
                SizedBox(height: 12),
                _OrderCard(
                  customer: 'Sarra Amri',
                  reference: '#CMD-1002',
                  date: '04 May 2026',
                  total: '95.000 TND',
                  status: 'Sent',
                ),
                SizedBox(height: 12),
                _OrderCard(
                  customer: 'Ali Louati',
                  reference: '#CMD-1003',
                  date: '03 May 2026',
                  total: '210.300 TND',
                  status: 'Closed',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  final String customer;
  final String reference;
  final String date;
  final String total;
  final String status;

  const _OrderCard({
    required this.customer,
    required this.reference,
    required this.date,
    required this.total,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;

    switch (status) {
      case 'Sent':
        bg = const Color(0xFFEDEEFF);
        fg = AdminPalette.primary;
        break;
      case 'Closed':
        bg = AdminPalette.okBg;
        fg = AdminPalette.ok;
        break;
      default:
        bg = AdminPalette.warningBg;
        fg = const Color(0xFFB45309);
    }

    return AdminListTileCard(
      leading: CircleAvatar(
        radius: 24,
        backgroundColor: AdminPalette.primary.withValues(alpha: 0.12),
        child: const Icon(Icons.receipt_long_rounded, color: AdminPalette.primary),
      ),
      title: '$customer • $reference',
      subtitle: '$date • $total',
      trailing: AdminBadge(text: status, bg: bg, fg: fg),
      footer: Row(
        children: [
          Expanded(
            child: AdminActionButton(
              text: 'Details',
              onPressed: () {},
              icon: Icons.visibility_rounded,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: AdminActionButton(
              text: 'History',
              onPressed: () {},
              primary: true,
              icon: Icons.history_rounded,
            ),
          ),
        ],
      ),
    );
  }
}