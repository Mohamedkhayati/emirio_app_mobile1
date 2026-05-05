import 'package:flutter/material.dart';
import '../../../admin/presentation/widgets/admin_shell.dart';

class VendeurCatalogPage extends StatelessWidget {
  final String baseUrl;

  const VendeurCatalogPage({
    super.key,
    required this.baseUrl,
  });

  @override
  Widget build(BuildContext context) {
    return AdminShell(
      title: 'My Catalog',
      panelTitle: 'Catalog Manager Panel',
      currentPath: '/vendeur/catalog',
      child: AdminPageFrame(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AdminSectionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AdminSectionTitle(
                    title: 'Manage your catalog',
                    subtitle: 'This follows the vendeur catalog structure from your frontend admin pages.',
                    trailing: AdminActionButton(
                      text: 'Add article',
                      onPressed: () {
                        // You can use baseUrl here if needed
                        // For example: navigate to add article page with baseUrl
                      },
                      primary: true,
                      icon: Icons.add_rounded,
                    ),
                  ),
                  const SizedBox(height: 14),
                  const AdminSearchField(hint: 'Search my articles...'),
                ],
              ),
            ),
            const SizedBox(height: 18),
            const _SellerCatalogCard(title: 'Espadrille Premium', info: '4 colors • 8 sizes • Stock healthy'),
            const SizedBox(height: 12),
            const _SellerCatalogCard(title: 'Leather Belt', info: '2 colors • Accessory variation'),
          ],
        ),
      ),
    );
  }
}

class _SellerCatalogCard extends StatelessWidget {
  final String title;
  final String info;

  const _SellerCatalogCard({
    required this.title,
    required this.info,
  });

  @override
  Widget build(BuildContext context) {
    return AdminListTileCard(
      leading: Container(
        width: 58,
        height: 58,
        decoration: BoxDecoration(
          color: AdminPalette.bgSoft,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AdminPalette.stroke),
        ),
        child: const Icon(Icons.inventory_2_rounded, color: AdminPalette.primary),
      ),
      title: title,
      subtitle: info,
      footer: Row(
        children: [
          Expanded(
            child: AdminActionButton(
              text: 'Edit article',
              onPressed: () {},
              icon: Icons.edit_rounded,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: AdminActionButton(
              text: 'Manage stock',
              onPressed: () {},
              primary: true,
              icon: Icons.warehouse_rounded,
            ),
          ),
        ],
      ),
    );
  }
}