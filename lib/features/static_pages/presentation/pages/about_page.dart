import 'package:flutter/material.dart';
import '../../../../core/widgets/feature_body.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: FeatureBody(
        title: 'About',
        subtitle: 'Brand story, values, store identity, and Emirio presentation content.',
        icon: Icons.info_rounded,
      ),
    );
  }
}