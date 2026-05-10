import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/auth_provider.dart';
import 'admin_dashboard_page.dart';
import 'admin_catalog_page.dart';
import 'admin_orders_page.dart';
import 'admin_customers_page.dart';
import 'admin_workers_page.dart';
import 'admin_reclamations_page.dart';
import 'vendeur_dashboard_page.dart';
import 'vendeur_catalog_page.dart';
import 'vendeur_orders_page.dart';

class AdminShellPage extends StatefulWidget {
  const AdminShellPage({super.key});
  @override
  State<AdminShellPage> createState() => _AdminShellPageState();
}

class _AdminShellPageState extends State<AdminShellPage> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    if (!auth.isAdmin) return const Scaffold(body: Center(child: Text('Access denied')));

    // Build the dynamic menu replicating App.jsx logic
    final pages = <_AdminNavItem>[
      if (auth.isSuperAdmin)
        _AdminNavItem('Dashboard', Icons.dashboard_outlined, const AdminDashboardPage()),
      if (auth.isCatalogManager)
        _AdminNavItem('Vendeur Dashboard', Icons.dashboard_outlined, const VendeurDashboardPage()),

      if (auth.isSuperAdmin || auth.isEcommerceManager)
        _AdminNavItem('Catalog', Icons.inventory_2_outlined, const AdminCatalogPage()),
      if (auth.isCatalogManager)
        _AdminNavItem('Vendeur Catalog', Icons.storefront_outlined, const VendeurCatalogPage()),

      if (auth.isSuperAdmin || auth.isEcommerceManager)
        _AdminNavItem('Orders', Icons.shopping_bag_outlined, const AdminOrdersPage()),
      if (auth.isCatalogManager)
        _AdminNavItem('Vendeur Orders', Icons.local_shipping_outlined, const VendeurOrdersPage()),

      if (auth.isSuperAdmin || auth.isEcommerceManager)
        _AdminNavItem('Reclamations', Icons.report_problem_outlined, const AdminReclamationsPage()),
      if (auth.isSuperAdmin)
        _AdminNavItem('Customers', Icons.people_outline, const AdminCustomersPage()),
      if (auth.isSuperAdmin)
        _AdminNavItem('Workers', Icons.badge_outlined, const AdminWorkersPage()),
    ];

    if (_selectedIndex >= pages.length) _selectedIndex = 0;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        title: Text(pages[_selectedIndex].title),
      ),
      drawer: Drawer(
        child: SafeArea(
          child: Column(
            children: [
              Container(
                width: double.infinity, color: AppColors.primary, padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('EMIRIO PORTAL', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    Text(auth.user?.role ?? '', style: const TextStyle(color: Colors.white70)),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: pages.length,
                  itemBuilder: (_, index) => ListTile(
                    leading: Icon(pages[index].icon),
                    title: Text(pages[index].title),
                    selected: _selectedIndex == index,
                    onTap: () { setState(() => _selectedIndex = index); Navigator.pop(context); },
                  ),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.arrow_back), title: const Text('Back to shop'),
                onTap: () => Navigator.pushReplacementNamed(context, '/'),
              ),
            ],
          ),
        ),
      ),
      body: pages[_selectedIndex].page,
    );
  }
}

class _AdminNavItem {
  final String title;
  final IconData icon;
  final Widget page;
  _AdminNavItem(this.title, this.icon, this.page);
}