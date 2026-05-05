import 'package:flutter/material.dart';
import '../../../admin/presentation/widgets/admin_shell.dart';

class VendeurOrdersPage extends StatelessWidget {
  const VendeurOrdersPage({super.key});

  @override
  Widget build(BuildContext context) {
    return AdminShell(
      title: 'Seller Orders',
      panelTitle: 'Catalog Manager Panel',
      currentPath: '/vendeur/orders',
      child: AdminPageFrame(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const AdminSectionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AdminSectionTitle(
                    title: 'Orders assigned to seller',
                    subtitle: 'Styled like your vendeur orders list with customer, status, date, and actions.',
                  ),
                  SizedBox(height: 14),
                  AdminSearchField(hint: 'Search by customer or order...'),
                ],
              ),
            ),
            const SizedBox(height: 18),
            const _SellerOrderRow(
              customer: 'Mohamed Khayati',
              ref: '#V-1001',
              total: '132.000 TND',
              status: 'Pending',
            ),
            const SizedBox(height: 12),
            const _SellerOrderRow(
              customer: 'Sarra Amri',
              ref: '#V-1002',
              total: '84.000 TND',
              status: 'Sent',
            ),
          ],
        ),
      ),
    );
  }
}

class _SellerOrderRow extends StatelessWidget {
  final String customer;
  final String ref;
  final String total;
  final String status;

  const _SellerOrderRow({
    required this.customer,
    required this.ref,
    required this.total,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    return AdminListTileCard(
      leading: CircleAvatar(
        radius: 24,
        backgroundColor: AdminPalette.primary.withValues(alpha: 0.10),
        child: const Icon(Icons.local_shipping_rounded, color: AdminPalette.primary),
      ),
      title: '$customer • $ref',
      subtitle: total,
      trailing: AdminBadge(
        text: status,
        bg: status == 'Sent' ? const Color(0xFFEDEEFF) : AdminPalette.warningBg,
        fg: status == 'Sent' ? AdminPalette.primary : const Color(0xFFB45309),
      ),
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
              text: 'Update',
              onPressed: () {},
              primary: true,
              icon: Icons.update_rounded,
            ),
          ),
        ],
      ),
    );
  }
}