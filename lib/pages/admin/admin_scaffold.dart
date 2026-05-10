import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';

// These would be your individual screen widgets
import 'admin_dashboard_page.dart';
import 'admin_catalog_page.dart';
import 'admin_orders_page.dart';
import 'admin_customers_page.dart';
import 'admin_workers_page.dart';
import 'admin_reclamations_page.dart';

class AdminScaffold extends StatefulWidget {
  const AdminScaffold({super.key});

  @override
  State<AdminScaffold> createState() => _AdminScaffoldState();
}

class _AdminScaffoldState extends State<AdminScaffold> {
  int _selectedIndex = 0;

  // Replicating your React normalizeRole logic
  bool get _isAdminGeneral {
    final role = context.read<AuthProvider>().user?.role;
    return role == 'Administrateur' || role == 'ADMIN' || role == 'ADMINGENERAL';
  }

  bool get _isCatalogManager {
    final role = context.read<AuthProvider>().user?.role;
    return role == 'Gestionnaire de catalogue' || role == 'VENDEUR' || role == 'SELLER';
  }

  bool get _isEcommerceManager {
    final role = context.read<AuthProvider>().user?.role;
    return role == 'Responsable e-commerce' || role == 'CONTROLEUR' || role == 'CONTROLLER';
  }

  // Build the list of allowed tabs dynamically based on roles (matching React)
  List<AdminTab> get _allowedTabs {
    List<AdminTab> tabs = [];

    if (_isAdminGeneral) {
      tabs.add(AdminTab(title: 'Dashboard', icon: Icons.dashboard, page: const AdminDashboardPage()));
      tabs.add(AdminTab(title: 'Catalog', icon: Icons.inventory_2, page: const AdminCatalogPage()));
      tabs.add(AdminTab(title: 'Orders', icon: Icons.shopping_cart, page: const AdminOrdersPage()));
      tabs.add(AdminTab(title: 'Customers', icon: Icons.people, page: const AdminCustomersPage()));
      tabs.add(AdminTab(title: 'Workers', icon: Icons.badge, page: const AdminWorkersPage()));
      tabs.add(AdminTab(title: 'Reclamations', icon: Icons.support_agent, page: const AdminReclamationsPage()));
    } else if (_isCatalogManager) {
      tabs.add(AdminTab(title: 'Dashboard', icon: Icons.dashboard, page: const AdminDashboardPage()));
      tabs.add(AdminTab(title: 'Catalog', icon: Icons.inventory_2, page: const AdminCatalogPage()));
      tabs.add(AdminTab(title: 'Orders', icon: Icons.shopping_cart, page: const AdminOrdersPage()));
    } else if (_isEcommerceManager) {
      tabs.add(AdminTab(title: 'Catalog', icon: Icons.inventory_2, page: const AdminCatalogPage()));
      tabs.add(AdminTab(title: 'Orders', icon: Icons.shopping_cart, page: const AdminOrdersPage()));
      tabs.add(AdminTab(title: 'Reclamations', icon: Icons.support_agent, page: const AdminReclamationsPage()));
    }

    return tabs;
  }

  String _getPanelTitle() {
    if (_isAdminGeneral) return 'Administrator Panel';
    if (_isEcommerceManager) return 'E-commerce Manager Panel';
    if (_isCatalogManager) return 'Catalog Manager Panel';
    return 'Panel';
  }

  @override
  Widget build(BuildContext context) {
    final tabs = _allowedTabs;

    // Security catch: If user has no valid role, deny access
    if (tabs.isEmpty) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.security, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              const Text('Access denied. You do not have permission to view this page.',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => Navigator.pushReplacementNamed(context, '/'),
                child: const Text('Return Home'),
              )
            ],
          ),
        ),
      );
    }

    // Ensure index is within bounds if role changes
    if (_selectedIndex >= tabs.length) {
      _selectedIndex = 0;
    }

    final bool isDesktop = MediaQuery.of(context).size.width > 900;

    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB), // Matching --bg from your CSS
      appBar: isDesktop ? null : AppBar(
        title: Text(tabs[_selectedIndex].title, style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
      ),
      drawer: isDesktop ? null : _buildSidebar(tabs),
      body: Row(
        children: [
          if (isDesktop) _buildSidebar(tabs),

          // Main Content Area (Outlet equivalent)
          Expanded(
            child: Column(
              children: [
                // Top Header (Optional for Desktop)
                if (isDesktop)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    color: Colors.white,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          tabs[_selectedIndex].title,
                          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
                        ),
                        // You can add language switcher or profile icon here
                      ],
                    ),
                  ),

                // The actual page content
                Expanded(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 250),
                    child: tabs[_selectedIndex].page, // Render selected page
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebar(List<AdminTab> tabs) {
    return Container(
      width: 250,
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Sidebar Top Brand
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('EMIRIO',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
                const SizedBox(height: 4),
                Text(_getPanelTitle(),
                    style: const TextStyle(fontSize: 12, color: Colors.grey)),
              ],
            ),
          ),

          const Divider(height: 1, color: Color(0xFFE9ECF8)),

          // Sidebar Menu Links
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
              itemCount: tabs.length,
              itemBuilder: (context, index) {
                final bool isActive = _selectedIndex == index;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: InkWell(
                    onTap: () {
                      setState(() => _selectedIndex = index);
                      // Close drawer if on mobile
                      if (MediaQuery.of(context).size.width <= 900) {
                        Navigator.pop(context);
                      }
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        gradient: isActive
                            ? const LinearGradient(colors: [Color(0xFF5B5EF7), Color(0xFF7C3AED)]) // --primary and --primary-2
                            : null,
                        color: isActive ? null : Colors.transparent,
                      ),
                      child: Row(
                        children: [
                          Icon(
                            tabs[index].icon,
                            color: isActive ? Colors.white : const Color(0xFF4B5168),
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            tabs[index].title,
                            style: TextStyle(
                              color: isActive ? Colors.white : const Color(0xFF4B5168),
                              fontWeight: FontWeight.bold,
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

          // Logout Button at bottom
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: OutlinedButton.icon(
              onPressed: () {
                context.read<AuthProvider>().logout();
                Navigator.pushReplacementNamed(context, '/auth');
              },
              icon: const Icon(Icons.logout, color: Colors.red),
              label: const Text('Logout', style: TextStyle(color: Colors.red)),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 48),
                side: const BorderSide(color: Colors.red),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          )
        ],
      ),
    );
  }
}

// Simple model to hold Tab data
class AdminTab {
  final String title;
  final IconData icon;
  final Widget page;

  AdminTab({required this.title, required this.icon, required this.page});
}