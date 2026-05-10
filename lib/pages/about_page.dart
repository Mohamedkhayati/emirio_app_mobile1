import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';
import '../widgets/navbar.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});
  @override
  Widget build(BuildContext context) {
    return MainScaffold(
      currentIndex: 0,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('About Emirio', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppColors.textDark)),
          const SizedBox(height: 16),
          Container(height: 4, width: 60, color: AppColors.accent),
          const SizedBox(height: 20),
          const Text('Emirio is your premium destination for shoes and accessories. We bring you the finest collections from around the world, curated for quality and style.',
              style: TextStyle(color: AppColors.textGrey, fontSize: 16, height: 1.7)),
          const SizedBox(height: 30),
          _featureCard(Icons.verified_outlined, 'Quality Guarantee', 'Every product is carefully verified for quality and authenticity.'),
          _featureCard(Icons.local_shipping_outlined, 'Fast Delivery', 'Get your order delivered to your door within 3-5 business days.'),
          _featureCard(Icons.support_agent_outlined, '24/7 Support', 'Our customer support team is always here to help you.'),
          _featureCard(Icons.loop_outlined, 'Easy Returns', '30-day hassle-free return policy on all orders.'),
        ]),
      ),
    );
  }

  Widget _featureCard(IconData icon, String title, String desc) => Container(
    margin: const EdgeInsets.only(bottom: 16),
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 8)]), // Fixed here
    child: Row(children: [
      Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: AppColors.accent.withOpacity(0.1), shape: BoxShape.circle),
          child: Icon(icon, color: AppColors.accent, size: 28)),
      const SizedBox(width: 16),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
        const SizedBox(height: 4),
        Text(desc, style: const TextStyle(color: AppColors.textGrey, fontSize: 13)),
      ])),
    ]),
  );
}