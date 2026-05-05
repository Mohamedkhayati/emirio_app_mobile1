import 'package:flutter/material.dart';
import '../../../../core/widgets/feature_body.dart';

class OrderHistoryPage extends StatelessWidget {
  const OrderHistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: FeatureBody(
        title: 'Order History',
        subtitle: 'User order timeline, statuses, order details, totals, and re-order support.',
        icon: Icons.history_rounded,
      ),
    );
  }
}