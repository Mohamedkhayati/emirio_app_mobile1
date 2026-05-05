import 'package:flutter/material.dart';
import '../widgets/admin_shell.dart';

class WorkersPage extends StatelessWidget {
  const WorkersPage({super.key});

  @override
  Widget build(BuildContext context) {
    return AdminShell(
      title: 'Workers',
      panelTitle: 'Administrator Panel',
      currentPath: '/admin/workers',
      child: AdminPageFrame(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AdminSectionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AdminSectionTitle(
                    title: 'Workers management',
                    subtitle: 'Roles, account state, and action controls like in your React workers page.',
                    trailing: AdminActionButton(
                      text: 'Create worker',
                      onPressed: () {},
                      primary: true,
                      icon: Icons.add_rounded,
                    ),
                  ),
                  const SizedBox(height: 14),
                  const AdminSearchField(hint: 'Search worker by name, email, role...'),
                ],
              ),
            ),
            const SizedBox(height: 18),
            const Column(
              children: [
                _WorkerCard(
                  initials: 'GK',
                  name: 'Gestionnaire Karim',
                  email: 'karim@emirio.tn',
                  role: 'Gestionnaire de catalogue',
                  status: 'ACTIVE',
                ),
                SizedBox(height: 12),
                _WorkerCard(
                  initials: 'RM',
                  name: 'Responsable Mariem',
                  email: 'mariem@emirio.tn',
                  role: 'Responsable e-commerce',
                  status: 'ACTIVE',
                ),
                SizedBox(height: 12),
                _WorkerCard(
                  initials: 'AD',
                  name: 'Admin General',
                  email: 'admin@emirio.tn',
                  role: 'Administrateur',
                  status: 'ACTIVE',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _WorkerCard extends StatelessWidget {
  final String initials;
  final String name;
  final String email;
  final String role;
  final String status;

  const _WorkerCard({
    required this.initials,
    required this.name,
    required this.email,
    required this.role,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    return AdminListTileCard(
      leading: CircleAvatar(
        radius: 24,
        backgroundColor: const Color(0xFFEDEEFF),
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
        bg: AdminPalette.okBg,
        fg: AdminPalette.ok,
      ),
      footer: Row(
        children: [
          Expanded(
            child: AdminActionButton(
              text: 'Change role',
              onPressed: () {},
              icon: Icons.manage_accounts_rounded,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: AdminActionButton(
              text: 'Disable',
              onPressed: () {},
              primary: true,
              icon: Icons.block_rounded,
            ),
          ),
        ],
      ),
    );
  }
}