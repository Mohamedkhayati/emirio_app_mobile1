import 'package:flutter/material.dart';
import '../../../../core/widgets/feature_body.dart';

class CartCheckoutPage extends StatelessWidget {
  const CartCheckoutPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: FeatureBody(
        title: 'Cart & Checkout',
        subtitle: 'Cart lines, quantity updates, totals, address, payment flow, order confirmation, and backend checkout integration.',
        icon: Icons.shopping_cart_checkout_rounded,
      ),
    );
  }
}