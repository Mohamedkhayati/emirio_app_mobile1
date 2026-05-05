import 'package:flutter/material.dart';
import '../widgets/admin_shell.dart';

class AdminClientsPage extends StatelessWidget {
  const AdminClientsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return AdminShell(
      title: 'Clients',
      panelTitle: 'Administrator Panel',
      currentPath: '/admin/clients',
      child: AdminPageFrame(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const AdminSectionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AdminSectionTitle(
                    title: 'Client management',
                    subtitle: 'Styled like your admin clients table with search, status badges, and profile actions.',
                  ),
                  SizedBox(height: 14),
                  AdminSearchField(hint: 'Search by name, email, role...'),
                ],
              ),
            ),
            const SizedBox(height: 18),
            const Column(
              children: [
                _ClientCard(
                  initials: 'MK',
                  name: 'Mohamed Khayati',
                  email: 'mohamed@example.com',
                  status: 'ACTIVE',
                  role: 'Client',
                ),
                SizedBox(height: 12),
                _ClientCard(
                  initials: 'SA',
                  name: 'Sarra Amri',
                  email: 'sarra@example.com',
                  status: 'BLOCKED',
                  role: 'Client',
                ),
                SizedBox(height: 12),
                _ClientCard(
                  initials: 'AL',
                  name: 'Ali Louati',
                  email: 'ali@example.com',
                  status: 'ACTIVE',
                  role: 'Client',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ClientCard extends StatelessWidget {
  final String initials;
  final String name;
  final String email;
  final String status;
  final String role;

  const _ClientCard({
    required this.initials,
    required this.name,
    required this.email,
    required this.status,
    required this.role,
  });

  @override
  Widget build(BuildContext context) {
    final blocked = status == 'BLOCKED';

    return AdminListTileCard(
      leading: CircleAvatar(
        radius: 24,
        backgroundColor: AdminPalette.primary.withValues(alpha: 0.10),
        child: Text(
          initials,
          style: const TextStyle(
            fontWeight: FontWeight.w900,
            color: AdminPalette.primary,
          ),
        ),
      ),
      title: name,
      subtitle: '$email • $role',
      trailing: AdminBadge(
        text: status,
        bg: blocked ? AdminPalette.dangerBg : AdminPalette.okBg,
        fg: blocked ? AdminPalette.danger : AdminPalette.ok,
      ),
      footer: Row(
        children: [
          Expanded(
            child: AdminActionButton(
              text: 'View profile',
              onPressed: () {},
              icon: Icons.visibility_rounded,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: AdminActionButton(
              text: blocked ? 'Activate' : 'Block',
              onPressed: () {},
              primary: true,
              icon: blocked ? Icons.check_circle_rounded : Icons.block_rounded,
            ),
          ),
        ],
      ),
    );
  }
}