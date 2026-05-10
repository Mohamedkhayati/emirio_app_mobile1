import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../core/constants/app_colors.dart';

// Import all admin pages
import 'admin_dashboard_page.dart';
import 'admin_catalog_page.dart';
import 'admin_orders_page.dart';
import 'admin_customers_page.dart';
import 'admin_workers_page.dart';
import 'admin_reclamations_page.dart';
import 'vendeur_dashboard_page.dart';
import 'vendeur_catalog_page.dart';
import 'vendeur_orders_page.dart';

class AdminLayout extends StatefulWidget {
  const AdminLayout({super.key});

  @override
  State<AdminLayout> createState() => _AdminLayoutState();
}

class _AdminLayoutState extends State<AdminLayout> {
  String _currentSection = '';
  bool _isSidebarCollapsed = false;

  @override
  void initState() {
    super.initState();
    _setDefaultSection();
    debugPrint('🔍 AdminLayout - initState called');
  }

  void _setDefaultSection() {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    debugPrint('🔍 AdminLayout - User role: ${auth.role}, isSuperAdmin: ${auth.isSuperAdmin}, isCatalogManager: ${auth.isCatalogManager}, isEcommerceManager: ${auth.isEcommerceManager}');

    if (auth.isSuperAdmin) {
      _currentSection = 'customers';
      debugPrint('🔍 AdminLayout - Setting default section to: customers');
    } else if (auth.isCatalogManager) {
      _currentSection = 'catalog';
      debugPrint('🔍 AdminLayout - Setting default section to: catalog');
    } else if (auth.isEcommerceManager) {
      _currentSection = 'orders';
      debugPrint('🔍 AdminLayout - Setting default section to: orders');
    } else {
      debugPrint('🔍 AdminLayout - No valid role found!');
    }
  }

  List<AdminMenuItem> _getMenuItems() {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final items = <AdminMenuItem>[];
    debugPrint('🔍 AdminLayout - Building menu for role: ${auth.role}');

    if (auth.isSuperAdmin) {
      debugPrint('🔍 AdminLayout - Adding SuperAdmin menu items');
      items.add(AdminMenuItem(
        key: 'customers',
        label: 'Clients',
        icon: Icons.people_outline,
        page: const AdminCustomersPage(),
      ));
      items.add(AdminMenuItem(
        key: 'workers',
        label: 'Workers',
        icon: Icons.person_outline,
        page: const AdminWorkersPage(),
      ));
      items.add(AdminMenuItem(
        key: 'catalog',
        label: 'Catalog',
        icon: Icons.inventory_2_outlined,
        page: const AdminCatalogPage(),
      ));
      items.add(AdminMenuItem(
        key: 'dashboard',
        label: 'Dashboard',
        icon: Icons.dashboard_outlined,
        page: const AdminDashboardPage(),
      ));
      items.add(AdminMenuItem(
        key: 'orders',
        label: 'Orders',
        icon: Icons.shopping_bag_outlined,
        page: const AdminOrdersPage(),
      ));
      items.add(AdminMenuItem(
        key: 'reclamations',
        label: 'Reclamations',
        icon: Icons.support_agent_outlined,
        page: const AdminReclamationsPage(),
      ));
    } else if (auth.isCatalogManager) {
      debugPrint('🔍 AdminLayout - Adding CatalogManager menu items');
      items.add(AdminMenuItem(
        key: 'catalog',
        label: 'Catalog',
        icon: Icons.inventory_2_outlined,
        page: const VendeurCatalogPage(),
      ));
      items.add(AdminMenuItem(
        key: 'dashboard',
        label: 'Dashboard',
        icon: Icons.dashboard_outlined,
        page: const VendeurDashboardPage(),
      ));
      items.add(AdminMenuItem(
        key: 'orders',
        label: 'Orders',
        icon: Icons.shopping_bag_outlined,
        page: const VendeurOrdersPage(),
      ));
    } else if (auth.isEcommerceManager) {
      debugPrint('🔍 AdminLayout - Adding EcommerceManager menu items');
      items.add(AdminMenuItem(
        key: 'catalog',
        label: 'Catalog',
        icon: Icons.inventory_2_outlined,
        page: const AdminCatalogPage(),
      ));
      items.add(AdminMenuItem(
        key: 'orders',
        label: 'Orders',
        icon: Icons.shopping_bag_outlined,
        page: const AdminOrdersPage(),
      ));
      items.add(AdminMenuItem(
        key: 'reclamations',
        label: 'Reclamations',
        icon: Icons.support_agent_outlined,
        page: const AdminReclamationsPage(),
      ));
    }

    debugPrint('🔍 AdminLayout - Total menu items: ${items.length}');
    return items;
  }

  String _getPanelTitle() {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    if (auth.isSuperAdmin) return 'Administrator Panel';
    if (auth.isEcommerceManager) return 'E-commerce Manager Panel';
    if (auth.isCatalogManager) return 'Catalog Manager Panel';
    return 'Panel';
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final menuItems = _getMenuItems();

    debugPrint('🔍 AdminLayout - Build called, menuItems count: ${menuItems.length}, currentSection: $_currentSection');

    if (menuItems.isEmpty) {
      debugPrint('🔍 AdminLayout - No menu items, showing access denied');
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.security, size: 64, color: AppColors.error),
              const SizedBox(height: 16),
              Text(
                'Access denied. Your role (${auth.normalizedRole}) is not allowed to access this page.',
                style: const TextStyle(color: AppColors.error),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => Navigator.pushReplacementNamed(context, '/'),
                child: const Text('Return to Home'),
              ),
            ],
          ),
        ),
      );
    }

    if (!menuItems.any((item) => item.key == _currentSection)) {
      debugPrint('🔍 AdminLayout - Invalid section, resetting to first');
      _currentSection = menuItems.first.key;
    }

    final currentPage = menuItems.firstWhere((item) => item.key == _currentSection).page;
    debugPrint('🔍 AdminLayout - Rendering page for section: $_currentSection');

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Row(
          children: [
            // Sidebar
            Container(
              width: 260,
              decoration: BoxDecoration(
                color: AppColors.surface,
                border: Border(right: BorderSide(color: AppColors.border)),
              ),
              child: Column(
                children: [
                  // Brand Section
                  Container(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'EMIRIO',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.5,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _getPanelTitle(),
                          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1, color: AppColors.border),

                  // Menu Items
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                      itemCount: menuItems.length,
                      itemBuilder: (context, index) {
                        final item = menuItems[index];
                        final isActive = _currentSection == item.key;

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: InkWell(
                            onTap: () {
                              debugPrint('🔍 AdminLayout - Tapped on: ${item.key}');
                              setState(() {
                                _currentSection = item.key;
                              });
                            },
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                color: isActive ? AppColors.accent : Colors.transparent,
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    item.icon,
                                    color: isActive ? Colors.white : AppColors.textSecondary,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    item.label,
                                    style: TextStyle(
                                      color: isActive ? Colors.white : AppColors.textPrimary,
                                      fontWeight: FontWeight.w500,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                  // Logout Button
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        debugPrint('🔍 AdminLayout - Logout pressed');
                        await auth.logout();
                        if (mounted) {
                          Navigator.pushReplacementNamed(context, '/auth');
                        }
                      },
                      icon: const Icon(Icons.logout, color: AppColors.error),
                      label: const Text('Logout', style: TextStyle(color: AppColors.error)),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 45),
                        side: const BorderSide(color: AppColors.error),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Main Content - FIXED with proper scrolling
            Expanded(
              child: Container(
                color: AppColors.background,
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.all(16),
                  child: currentPage,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class AdminMenuItem {
  final String key;
  final String label;
  final IconData icon;
  final Widget page;

  AdminMenuItem({
    required this.key,
    required this.label,
    required this.icon,
    required this.page,
  });
}