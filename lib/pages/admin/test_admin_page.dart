import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

class TestAdminPage extends StatelessWidget {
  const TestAdminPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Test Admin Page',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
        ),
        const SizedBox(height: 16),
        const Text(
          'If you can see this page, the admin layout is working correctly.',
          style: TextStyle(color: AppColors.textSecondary),
        ),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Column(
            children: [
              Text('✅ Admin panel loaded successfully!'),
              SizedBox(height: 8),
              Text('Now we can debug which page is causing the overflow.'),
            ],
          ),
        ),
      ],
    );
  }
}