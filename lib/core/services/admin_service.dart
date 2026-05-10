import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import '../api/api_client.dart';
import '../models/admin_models.dart';
import '../constants/app_colors.dart';

class AdminService {
  // ============== CUSTOMER SERVICES ==============
  static Future<List<AdminCustomer>> fetchCustomers() async {
    final response = await ApiClient.get('/api/admin/users');
    if (response.statusCode != 200) throw Exception('Failed to load customers');

    final List<dynamic> data = jsonDecode(response.body);
    final customers = data.where((u) =>
    u['role'] == 'CLIENT' || u['role'] == 'USER' || u['role'] == 'Client'
    ).toList();

    return customers.map((json) => AdminCustomer.fromJson(json)).toList();
  }

  static Future<AdminCustomer> fetchCustomer(int id) async {
    final response = await ApiClient.get('/api/admin/users/$id');
    if (response.statusCode != 200) throw Exception('Failed to load customer');
    return AdminCustomer.fromJson(jsonDecode(response.body));
  }

  static Future<List<CustomerHistoryEntry>> fetchCustomerHistory(int id) async {
    final response = await ApiClient.get('/api/admin/users/$id/history');
    if (response.statusCode != 200) throw Exception('Failed to load history');
    final List<dynamic> data = jsonDecode(response.body);
    return data.map((json) => CustomerHistoryEntry.fromJson(json)).toList();
  }

  static Future<AdminCustomer> updateCustomerStatus(int id, String statutCompte) async {
    final response = await ApiClient.put(
      '/api/admin/users/$id/status',
      {'statutCompte': statutCompte},
    );
    if (response.statusCode != 200) throw Exception('Failed to update status');
    return AdminCustomer.fromJson(jsonDecode(response.body));
  }

  static Future<AdminCustomer> updateCustomerRole(int id, String role) async {
    final response = await ApiClient.put(
      '/api/admin/users/$id/role',
      {'role': role},
    );
    if (response.statusCode != 200) throw Exception('Failed to update role');
    return AdminCustomer.fromJson(jsonDecode(response.body));
  }

  static Future<void> deleteCustomer(int id) async {
    final response = await ApiClient.delete('/api/admin/users/$id');
    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception('Failed to delete customer');
    }
  }

  static Future<AdminCustomer> createCustomer(CreateCustomerRequest request) async {
    final response = await ApiClient.post('/api/admin/users', request.toJson());
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('Failed to create customer');
    }
    return AdminCustomer.fromJson(jsonDecode(response.body));
  }

  static String getRoleDisplayName(String role) {
    switch (role) {
      case 'CLIENT':
      case 'USER':
        return 'Client';
      case 'VENDEUR':
        return 'Gestionnaire de catalogue';
      case 'CONTROLEUR':
        return 'Responsable e-commerce';
      case 'ADMIN_GENERAL':
        return 'Administrateur';
      default:
        return role;
    }
  }

  static Color getStatusColor(String status) {
    switch (status) {
      case 'ACTIVE':
        return AppColors.success;
      case 'BLOCKED':
        return AppColors.error;
      case 'DISABLED':
        return AppColors.textSecondary;
      default:
        return AppColors.warning;
    }
  }

  // ============== DASHBOARD SERVICES ==============
  static Future<AdminDashboardStats> fetchDashboardStats() async {
    final response = await ApiClient.get('/api/admin/stats/dashboard');
    if (response.statusCode != 200) throw Exception('Failed to load dashboard stats');
    return AdminDashboardStats.fromJson(jsonDecode(response.body));
  }

  static Future<Map<String, dynamic>> fetchVisits() async {
    final response = await ApiClient.get('/api/admin/stats/visits');
    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> fetchOrdersStats() async {
    final response = await ApiClient.get('/api/admin/stats/orders');
    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> fetchDailySales({int days = 30}) async {
    final response = await ApiClient.get('/api/admin/stats/sales-daily?days=$days');
    return jsonDecode(response.body);
  }

  static Future<List<TopItem>> fetchTopArticles({int limit = 5}) async {
    final response = await ApiClient.get('/api/admin/stats/top-articles?limit=$limit');
    final List<dynamic> data = jsonDecode(response.body);
    return data.map((json) => TopItem.fromJson(json)).toList();
  }

  static Future<List<TopItem>> fetchTopCategories({int limit = 5}) async {
    final response = await ApiClient.get('/api/admin/stats/top-categories?limit=$limit');
    final List<dynamic> data = jsonDecode(response.body);
    return data.map((json) => TopItem.fromJson(json)).toList();
  }

  static Future<List<RadarCategory>> fetchRadarCategories() async {
    try {
      final response = await ApiClient.get('/api/admin/stats/category-radar');
      final List<dynamic> data = jsonDecode(response.body);
      if (data.isNotEmpty) {
        return data.map((json) => RadarCategory.fromJson(json)).toList();
      }
    } catch (e) {
      print('Using fallback radar data');
    }
    return [
      RadarCategory(name: 'Homme', value: 4500),
      RadarCategory(name: 'Femme', value: 5200),
      RadarCategory(name: 'Unisex', value: 2100),
      RadarCategory(name: 'Accessoire', value: 870),
      RadarCategory(name: 'Kids', value: 1300),
    ];
  }

  // ============== ORDER SERVICES ==============
  static Future<List<AdminOrder>> fetchOrders() async {
    final response = await ApiClient.get('/api/admin/orders');
    if (response.statusCode != 200) throw Exception('Failed to load orders');
    final List<dynamic> data = jsonDecode(response.body);
    return data.map((json) => AdminOrder.fromJson(json)).toList();
  }

  static Future<void> confirmOrder(int id) async {
    final response = await ApiClient.patch(
      '/api/admin/orders/$id/status',
      body: {'statutCommande': 'CONFIRMEE'},
    );
    if (response.statusCode != 200) throw Exception('Failed to confirm order');
  }

  static Future<void> cancelOrder(int id) async {
    final response = await ApiClient.patch(
      '/api/admin/orders/$id/status',
      body: {'statutCommande': 'ANNULEE'},
    );
    if (response.statusCode != 200) throw Exception('Failed to cancel order');
  }

  static Future<void> markDelivered(int id) async {
    final response = await ApiClient.patch('/api/admin/orders/$id/delivered');
    if (response.statusCode != 200) throw Exception('Failed to mark as delivered');
  }

  static Future<void> reviewPayment(int id, bool accepted, {String? note}) async {
    final response = await ApiClient.patch(
      '/api/admin/orders/$id/payment-review',
      body: {
        'accepted': accepted,
        'note': note ?? (accepted ? 'Payment accepted by admin' : 'Payment rejected by admin'),
      },
    );
    if (response.statusCode != 200) throw Exception('Failed to review payment');
  }

  static Future<List<OrderHistoryEntry>> fetchOrderHistory(int id) async {
    final response = await ApiClient.get('/api/admin/orders/$id/actions');
    if (response.statusCode != 200) throw Exception('Failed to load order history');
    final List<dynamic> data = jsonDecode(response.body);
    return data.map((json) => OrderHistoryEntry.fromJson(json)).toList();
  }

  static Future<List<PaymentTransaction>> fetchOrderPayments(int id) async {
    final response = await ApiClient.get('/api/admin/orders/$id/payments');
    if (response.statusCode != 200) throw Exception('Failed to load payments');
    final List<dynamic> data = jsonDecode(response.body);
    return data.map((json) => PaymentTransaction.fromJson(json)).toList();
  }

  static Color getOrderStatusColor(String status) {
    switch (status.toUpperCase()) {
      case 'CONFIRMEE':
        return AppColors.success;
      case 'ANNULEE':
        return AppColors.error;
      case 'LIVREE':
        return Colors.green;
      default:
        return AppColors.warning;
    }
  }

  static String getOrderStatusLabel(String status) {
    switch (status.toUpperCase()) {
      case 'CONFIRMEE':
        return 'Confirmed';
      case 'ANNULEE':
        return 'Cancelled';
      case 'LIVREE':
        return 'Delivered';
      default:
        return 'Pending';
    }
  }

  static Color getPaymentStatusColor(String status) {
    switch (status.toUpperCase()) {
      case 'ACCEPTE':
        return AppColors.success;
      case 'REFUSE':
        return AppColors.error;
      default:
        return AppColors.warning;
    }
  }

  // ============== CATEGORY SERVICES ==============
  static Future<List<CategoryModel>> fetchMainCategories() async {
    final response = await ApiClient.get('/api/categories/main');
    if (response.statusCode != 200) throw Exception('Failed to load main categories');
    final List<dynamic> data = jsonDecode(response.body);
    return data.map((json) => CategoryModel.fromJson(json)).toList();
  }

  static Future<List<CategoryModel>> fetchAllCategories() async {
    final response = await ApiClient.get('/api/admin/categories');
    if (response.statusCode != 200) throw Exception('Failed to load categories');
    final List<dynamic> data = jsonDecode(response.body);
    return data.map((json) => CategoryModel.fromJson(json)).toList();
  }

  static Future<List<CategoryModel>> fetchChildCategories(int parentId) async {
    final response = await ApiClient.get('/api/categories/parent/$parentId/children');
    if (response.statusCode != 200) throw Exception('Failed to load child categories');
    final List<dynamic> data = jsonDecode(response.body);
    return data.map((json) => CategoryModel.fromJson(json)).toList();
  }

  static Future<List<ColorModel>> fetchColors() async {
    final response = await ApiClient.get('/api/admin/colors');
    if (response.statusCode != 200) throw Exception('Failed to load colors');
    final List<dynamic> data = jsonDecode(response.body);
    return data.map((json) => ColorModel.fromJson(json)).toList();
  }

  static Future<List<SizeModel>> fetchSizes() async {
    final response = await ApiClient.get('/api/admin/sizes');
    if (response.statusCode != 200) throw Exception('Failed to load sizes');
    final List<dynamic> data = jsonDecode(response.body);
    return data.map((json) => SizeModel.fromJson(json)).toList();
  }

  // ============== VENDEUR SERVICES ==============
  static Future<List<VendeurArticle>> fetchVendeurArticles() async {
    final response = await ApiClient.get('/api/vendeur/articles');
    if (response.statusCode != 200) throw Exception('Failed to load articles');
    final List<dynamic> data = jsonDecode(response.body);
    return data.map((json) => VendeurArticle.fromJson(json)).toList();
  }

  static Future<VendeurArticle> fetchVendeurArticleDetail(int id) async {
    final response = await ApiClient.get('/api/vendeur/articles/$id');
    if (response.statusCode != 200) throw Exception('Failed to load article detail');
    return VendeurArticle.fromJson(jsonDecode(response.body));
  }

  static Future<VendeurArticle> createVendeurArticle(Map<String, dynamic> data, List<File>? images) async {
    final fields = <String, String>{};
    fields['data'] = jsonEncode(data);
    final response = await ApiClient.postMultipart('/api/vendeur/articles', fields, images);
    if (response.statusCode != 200 && response.statusCode != 201) throw Exception('Failed to create article');
    return VendeurArticle.fromJson(jsonDecode(response.body));
  }

  static Future<VendeurArticle> updateVendeurArticle(int id, Map<String, dynamic> data, List<File>? images) async {
    final fields = <String, String>{};
    fields['data'] = jsonEncode(data);
    final response = await ApiClient.putMultipart('/api/vendeur/articles/$id', fields, images);
    if (response.statusCode != 200) throw Exception('Failed to update article');
    return VendeurArticle.fromJson(jsonDecode(response.body));
  }

  static Future<void> deleteVendeurArticle(int id) async {
    final response = await ApiClient.delete('/api/vendeur/articles/$id');
    if (response.statusCode != 200 && response.statusCode != 204) throw Exception('Failed to delete article');
  }

  static Future<VendeurVariation> createVendeurVariation(int articleId, Map<String, dynamic> data, List<File>? images, File? model3d) async {
    final fields = <String, String>{};
    fields['data'] = jsonEncode(data);
    final allFiles = <File>[];
    if (images != null) allFiles.addAll(images);
    if (model3d != null) allFiles.add(model3d);
    final response = await ApiClient.postMultipart('/api/vendeur/articles/$articleId/variations', fields, allFiles);
    if (response.statusCode != 200 && response.statusCode != 201) throw Exception('Failed to create variation');
    return VendeurVariation.fromJson(jsonDecode(response.body));
  }

  static Future<VendeurVariation> updateVendeurVariation(int variationId, Map<String, dynamic> data, List<File>? images, File? model3d) async {
    final fields = <String, String>{};
    fields['data'] = jsonEncode(data);
    final allFiles = <File>[];
    if (images != null) allFiles.addAll(images);
    if (model3d != null) allFiles.add(model3d);
    final response = await ApiClient.putMultipart('/api/vendeur/articles/variations/$variationId', fields, allFiles);
    if (response.statusCode != 200) throw Exception('Failed to update variation');
    return VendeurVariation.fromJson(jsonDecode(response.body));
  }

  static Future<void> deleteVendeurVariation(int variationId) async {
    final response = await ApiClient.delete('/api/vendeur/articles/variations/$variationId');
    if (response.statusCode != 200 && response.statusCode != 204) throw Exception('Failed to delete variation');
  }
  // Add this method to AdminService class

  static Future<VendeurDashboardStats> fetchVendeurDashboard() async {
    final response = await ApiClient.get('/api/vendeur/dashboard/stats');
    if (response.statusCode != 200) throw Exception('Failed to load vendeur dashboard');
    return VendeurDashboardStats.fromJson(jsonDecode(response.body));
  }
  // Add these methods to AdminService class

  static Future<List<VendeurOrder>> fetchVendeurOrders() async {
    final response = await ApiClient.get('/api/vendeur/orders');
    if (response.statusCode != 200) throw Exception('Failed to load orders');
    final List<dynamic> data = jsonDecode(response.body);
    return data.map((json) => VendeurOrder.fromJson(json)).toList();
  }

  static Future<List<VendeurOrderHistoryEntry>> fetchVendeurOrderHistory(int orderId) async {
    final response = await ApiClient.get('/api/vendeur/orders/$orderId/actions');
    if (response.statusCode != 200) throw Exception('Failed to load order history');
    final List<dynamic> data = jsonDecode(response.body);
    return data.map((json) => VendeurOrderHistoryEntry.fromJson(json)).toList();
  }

  static String getVendeurOrderStatusLabel(String status) {
    switch (status.toUpperCase()) {
      case 'CONFIRMEE':
        return 'Confirmed';
      case 'ANNULEE':
        return 'Cancelled';
      case 'LIVREE':
        return 'Delivered';
      default:
        return 'Pending';
    }
  }

  static Color getVendeurOrderStatusColor(String status) {
    switch (status.toUpperCase()) {
      case 'CONFIRMEE':
        return AppColors.success;
      case 'ANNULEE':
        return AppColors.error;
      case 'LIVREE':
        return Colors.green;
      default:
        return AppColors.warning;
    }
  }
  // Add these methods to AdminService class

  static Future<List<AdminWorker>> fetchWorkers() async {
    final response = await ApiClient.get('/api/admin/users');
    if (response.statusCode != 200) throw Exception('Failed to load workers');

    final List<dynamic> data = jsonDecode(response.body);
    // Filter workers (not clients)
    final workers = data.where((u) =>
    u['role'] == 'VENDEUR' ||
        u['role'] == 'CONTROLEUR' ||
        u['role'] == 'ADMIN_GENERAL' ||
        u['role'] == 'Gestionnaire de catalogue' ||
        u['role'] == 'Responsable e-commerce' ||
        u['role'] == 'Administrateur'
    ).toList();

    return workers.map((json) => AdminWorker.fromJson(json)).toList();
  }

  static Future<AdminWorker> fetchWorker(int id) async {
    final response = await ApiClient.get('/api/admin/users/$id');
    if (response.statusCode != 200) throw Exception('Failed to load worker');
    return AdminWorker.fromJson(jsonDecode(response.body));
  }

  static Future<List<WorkerHistoryEntry>> fetchWorkerHistory(int id) async {
    final response = await ApiClient.get('/api/admin/users/$id/history');
    if (response.statusCode != 200) throw Exception('Failed to load history');
    final List<dynamic> data = jsonDecode(response.body);
    return data.map((json) => WorkerHistoryEntry.fromJson(json)).toList();
  }

  static Future<AdminWorker> updateWorkerStatus(int id, String statutCompte) async {
    final response = await ApiClient.put(
      '/api/admin/users/$id/status',
      {'statutCompte': statutCompte},
    );
    if (response.statusCode != 200) throw Exception('Failed to update status');
    return AdminWorker.fromJson(jsonDecode(response.body));
  }

  static Future<AdminWorker> updateWorkerRole(int id, String role) async {
    final response = await ApiClient.put(
      '/api/admin/users/$id/role',
      {'role': role},
    );
    if (response.statusCode != 200) throw Exception('Failed to update role');
    return AdminWorker.fromJson(jsonDecode(response.body));
  }

  static Future<void> deleteWorker(int id) async {
    final response = await ApiClient.delete('/api/admin/users/$id');
    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception('Failed to delete worker');
    }
  }

  static Future<AdminWorker> createWorker(CreateWorkerRequest request) async {
    final response = await ApiClient.post('/api/admin/users', request.toJson());
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('Failed to create worker');
    }
    return AdminWorker.fromJson(jsonDecode(response.body));
  }

  static String getWorkerRoleDisplayName(String role) {
    switch (role) {
      case 'VENDEUR':
        return 'Gestionnaire de catalogue';
      case 'CONTROLEUR':
        return 'Responsable e-commerce';
      case 'ADMIN_GENERAL':
        return 'Administrateur';
      default:
        return role;
    }
  }

  static Color getWorkerStatusColor(String status) {
    switch (status) {
      case 'ACTIVE':
        return AppColors.success;
      case 'BLOCKED':
        return AppColors.error;
      case 'DISABLED':
        return AppColors.textSecondary;
      default:
        return AppColors.warning;
    }
  }
}