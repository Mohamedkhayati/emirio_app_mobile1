// lib/features/admin/presentation/pages/admin_catalog_wrapper.dart

import 'package:flutter/material.dart';
import '../../../../core/constants/api_constants.dart';
import 'catalog_page.dart' as admin_catalog;

class AdminCatalogWrapper extends StatelessWidget {
  const AdminCatalogWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    // Get auth token from wherever you store it
    // For example, from shared preferences or a provider
    String? authToken;

    // TODO: Replace with your actual auth token retrieval method
    // Example: final authToken = await AuthService.getToken();
    // Or using Provider: final authToken = Provider.of<AuthProvider>(context).token;

    return admin_catalog.CatalogPage(
      baseUrl: ApiConstants.baseUrl,
      authToken: authToken,
      isAdminGeneral: true,
      isCatalogManager: true,
      isEcommerceManager: true,
    );
  }
}