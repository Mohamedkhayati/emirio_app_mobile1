import 'package:flutter/material.dart';
import '../../../../core/constants/api_constants.dart';
import 'vendeur_catalog_page.dart';

class VendeurCatalogWrapper extends StatelessWidget {
  const VendeurCatalogWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return VendeurCatalogPage(
      baseUrl: ApiConstants.baseUrl,
    );
  }
}