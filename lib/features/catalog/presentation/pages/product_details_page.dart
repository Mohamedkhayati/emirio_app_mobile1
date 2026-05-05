import 'package:flutter/material.dart';
import '../../../../core/widgets/feature_body.dart';

class ProductDetailsPage extends StatelessWidget {
  final String productId;

  const ProductDetailsPage({
    super.key,
    required this.productId,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FeatureBody(
        title: 'Product Details',
        subtitle: 'Product id: $productId. Gallery, price, variation selector, stock, description, reviews, 3D/media, and add-to-cart actions.',
        icon: Icons.shopping_bag_rounded,
      ),
    );
  }
}