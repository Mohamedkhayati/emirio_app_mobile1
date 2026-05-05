import 'package:flutter/material.dart';
import '../widgets/admin_shell.dart';

class AdminPage extends StatelessWidget {
  const AdminPage({super.key});

  @override
  Widget build(BuildContext context) {
    return AdminShell(
      title: 'Administrator Panel',
      panelTitle: 'EMIRIO',
      currentPath: '/admin',
      child: AdminPageFrame(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const AdminSectionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Welcome back, Administrator',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      color: AdminPalette.text,
                    ),
                  ),
                  SizedBox(height: 10),
                  Text(
                    'This is the mobile admin entry point styled from your React admin panel. Use the menu to navigate to clients, workers, catalog, dashboard, orders, and reclamations.',
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.5,
                      fontWeight: FontWeight.w600,
                      color: AdminPalette.muted,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            GridView.count(
              crossAxisCount: MediaQuery.of(context).size.width > 760 ? 2 : 1,
              crossAxisSpacing: 14,
              mainAxisSpacing: 14,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              childAspectRatio: 2.4,
              children: const [
                AdminStatCard(
                  label: 'Total Clients',
                  value: '1,284',
                  icon: Icons.groups_rounded,
                  tone: AdminPalette.primary,
                ),
                AdminStatCard(
                  label: 'Active Workers',
                  value: '32',
                  icon: Icons.badge_rounded,
                  tone: Color(0xFF10B981),
                ),
                AdminStatCard(
                  label: 'Pending Orders',
                  value: '58',
                  icon: Icons.receipt_long_rounded,
                  tone: Color(0xFFF59E0B),
                ),
                AdminStatCard(
                  label: 'Open Reclamations',
                  value: '9',
                  icon: Icons.support_agent_rounded,
                  tone: Color(0xFFEF4444),
                ),
              ],
            ),
            const SizedBox(height: 18),
            const AdminSectionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AdminSectionTitle(
                    title: 'Quick access',
                    subtitle: 'The same admin structure as your frontend, optimized for mobile.',
                  ),
                  SizedBox(height: 16),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      AdminBadge(
                        text: 'Clients',
                        bg: Color(0xFFEDEEFF),
                        fg: AdminPalette.primary,
                      ),
                      AdminBadge(
                        text: 'Workers',
                        bg: Color(0xFFE9FFF2),
                        fg: Color(0xFF0F7A3A),
                      ),
                      AdminBadge(
                        text: 'Catalog',
                        bg: Color(0xFFFFF4E5),
                        fg: Color(0xFFB45309),
                      ),
                      AdminBadge(
                        text: 'Orders',
                        bg: Color(0xFFEEF2FF),
                        fg: Color(0xFF4338CA),
                      ),
                      AdminBadge(
                        text: 'Reclamations',
                        bg: Color(0xFFFFECEC),
                        fg: Color(0xFFB42318),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}