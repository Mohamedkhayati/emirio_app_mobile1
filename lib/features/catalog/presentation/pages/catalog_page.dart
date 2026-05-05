import 'package:flutter/material.dart';
import '../../../../core/widgets/feature_body.dart';

class CatalogPage extends StatelessWidget {
  const CatalogPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: FeatureBody(
        title: 'Catalog',
        subtitle: 'Product grid, filters, search, categories, sizes, colors, stock, and sorting.',
        icon: Icons.grid_view_rounded,
      ),
    );
  }
}