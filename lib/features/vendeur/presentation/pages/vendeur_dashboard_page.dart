import 'package:flutter/material.dart';
import '../../../admin/presentation/widgets/admin_shell.dart';

class VendeurDashboardPage extends StatelessWidget {
  const VendeurDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return AdminShell(
      title: 'Seller Dashboard',
      panelTitle: 'Catalog Manager Panel',
      currentPath: '/vendeur/dashboard',
      child: AdminPageFrame(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GridView.count(
              crossAxisCount: MediaQuery.of(context).size.width > 760 ? 2 : 1,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 14,
              mainAxisSpacing: 14,
              childAspectRatio: 2.3,
              children: const [
                AdminStatCard(
                  label: 'Total Sales',
                  value: '8,240 TND',
                  icon: Icons.payments_rounded,
                  tone: AdminPalette.primary,
                ),
                AdminStatCard(
                  label: 'Total Orders',
                  value: '96',
                  icon: Icons.shopping_bag_rounded,
                  tone: Color(0xFF10B981),
                ),
                AdminStatCard(
                  label: 'Items Sold',
                  value: '214',
                  icon: Icons.inventory_rounded,
                  tone: Color(0xFFF59E0B),
                ),
                AdminStatCard(
                  label: 'Products on Sale',
                  value: '12',
                  icon: Icons.local_offer_rounded,
                  tone: Color(0xFFEF4444),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}