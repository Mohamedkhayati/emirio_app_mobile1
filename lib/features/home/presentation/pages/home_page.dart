import 'package:flutter/material.dart';
import '../../../../core/widgets/feature_body.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: FeatureBody(
        title: 'Home',
        subtitle: 'Hero banners, featured categories, new arrivals, promotions, and recommendation blocks.',
        icon: Icons.home_rounded,
      ),
    );
  }
}