import 'package:flutter/material.dart';
import '../widgets/admin_shell.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    final twoCols = MediaQuery.of(context).size.width > 760;

    return AdminShell(
      title: 'Dashboard',
      panelTitle: 'Administrator Panel',
      currentPath: '/admin/dashboard',
      child: AdminPageFrame(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const AdminSectionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AdminSectionTitle(
                    title: 'Platform overview',
                    subtitle: 'Clean cards, KPI blocks, charts area, and admin monitoring layout.',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            GridView.count(
              crossAxisCount: twoCols ? 2 : 1,
              crossAxisSpacing: 14,
              mainAxisSpacing: 14,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              childAspectRatio: 2.35,
              children: const [
                AdminStatCard(
                  label: 'Revenue',
                  value: '12,430 TND',
                  icon: Icons.payments_rounded,
                  tone: AdminPalette.primary,
                ),
                AdminStatCard(
                  label: 'Orders',
                  value: '248',
                  icon: Icons.shopping_bag_rounded,
                  tone: Color(0xFF10B981),
                ),
                AdminStatCard(
                  label: 'Products',
                  value: '386',
                  icon: Icons.inventory_2_rounded,
                  tone: Color(0xFFF59E0B),
                ),
                AdminStatCard(
                  label: 'Conversion',
                  value: '4.8%',
                  icon: Icons.trending_up_rounded,
                  tone: Color(0xFFEC4899),
                ),
              ],
            ),
            const SizedBox(height: 18),
            GridView.count(
              crossAxisCount: twoCols ? 2 : 1,
              crossAxisSpacing: 14,
              mainAxisSpacing: 14,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              childAspectRatio: twoCols ? 1.35 : 1.05,
              children: [
                _ChartPlaceholderCard(
                  title: 'Sales performance',
                  subtitle: 'Area reserved for stats and chart widgets.',
                  bars: const [90, 60, 120, 75, 140, 110, 95],
                ),
                _ChartPlaceholderCard(
                  title: 'Orders pipeline',
                  subtitle: 'Pending, sent, closed, and cancelled distribution.',
                  bars: const [110, 82, 60, 36],
                ),
              ],
            ),
            const SizedBox(height: 18),
            const AdminSectionCard(
              child: Column(
                children: [
                  _MiniRow(
                    title: 'Top category',
                    value: 'Shoes',
                    color: AdminPalette.primary,
                  ),
                  Divider(height: 20, color: AdminPalette.stroke),
                  _MiniRow(
                    title: 'Top payment method',
                    value: 'Cash on Delivery',
                    color: Color(0xFF10B981),
                  ),
                  Divider(height: 20, color: AdminPalette.stroke),
                  _MiniRow(
                    title: 'Most active zone',
                    value: 'Tunis',
                    color: Color(0xFFF59E0B),
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

class _ChartPlaceholderCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final List<double> bars;

  const _ChartPlaceholderCard({
    required this.title,
    required this.subtitle,
    required this.bars,
  });

  @override
  Widget build(BuildContext context) {
    return AdminSectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AdminSectionTitle(
            title: title,
            subtitle: subtitle,
          ),
          const SizedBox(height: 18),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: bars
                  .map(
                    (v) => Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Container(
                      height: v,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [AdminPalette.primary, AdminPalette.primary2],
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                        ),
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
              )
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniRow extends StatelessWidget {
  final String title;
  final String value;
  final Color color;

  const _MiniRow({
    required this.title,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        CircleAvatar(
          radius: 16,
          backgroundColor: color.withValues(alpha: 0.12),
          child: Icon(Icons.circle, size: 12, color: color),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              color: AdminPalette.muted,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            color: AdminPalette.text,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}