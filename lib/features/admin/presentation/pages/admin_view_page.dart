import 'package:flutter/material.dart';
import '../widgets/admin_shell.dart';

class AdminViewPage extends StatelessWidget {
  const AdminViewPage({super.key});

  @override
  Widget build(BuildContext context) {
    return AdminShell(
      title: 'Admin View',
      panelTitle: 'Administrator Panel',
      currentPath: '/admin/view',
      child: const AdminPageFrame(
        child: AdminSectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AdminSectionTitle(
                title: 'Admin container view',
                subtitle: 'This route can host the dynamic section switching logic from your React AdminView.',
              ),
              SizedBox(height: 16),
              Text(
                'Use this page as the mobile equivalent of your AdminView section host. The design now matches the admin card system, radius, spacing, shadows, and motion style.',
                style: TextStyle(
                  color: AdminPalette.muted,
                  height: 1.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}