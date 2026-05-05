import 'package:flutter/material.dart';
import '../../../../core/widgets/feature_body.dart';

class ContactPage extends StatelessWidget {
  const ContactPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: FeatureBody(
        title: 'Contact',
        subtitle: 'Contact form, email, phone, support channels, and company information.',
        icon: Icons.contact_support_rounded,
      ),
    );
  }
}