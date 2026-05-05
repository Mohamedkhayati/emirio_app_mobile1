import 'package:flutter/material.dart';
import '../../../../core/widgets/feature_body.dart';

class FavoritesPage extends StatelessWidget {
  const FavoritesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: FeatureBody(
        title: 'Favorites',
        subtitle: 'Wishlist listing, remove from favorites, quick add-to-cart, and product shortcuts.',
        icon: Icons.favorite_rounded,
      ),
    );
  }
}