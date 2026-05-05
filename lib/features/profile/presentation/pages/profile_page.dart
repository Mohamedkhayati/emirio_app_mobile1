import 'package:flutter/material.dart';
import '../../../../core/widgets/feature_body.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: FeatureBody(
        title: 'Profile',
        subtitle: 'User info, avatar, address, password change, account preferences, and account management.',
        icon: Icons.person_rounded,
      ),
    );
  }
}