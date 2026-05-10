import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../api/api_client.dart';
import '../models/article_model.dart';
import '../models/variation_model.dart';
import '../models/category_model.dart';
import '../models/color_model.dart';
import '../models/size_model.dart';
import '../models/history_entry_model.dart';

class AdminCatalogService {
  // ========== ARTICLES ==========
  static Future<List<ArticleModel>> fetchArticles() async {
    final response = await ApiClient.get('/api/admin/articles');
    if (response.statusCode != 200) throw Exception('Failed to load articles');
    final List<dynamic> data = jsonDecode(response.body);
    return data.map((json) => ArticleModel.fromJson(json)).toList();
  }

  static Future<ArticleModel> createArticle({
    required String nom,
    required String description,
    required String details,
    required double prix,
    double? salePrice,
    DateTime? saleStartAt,
    DateTime? saleEndAt,
    required bool actif,
    required bool recommended,
    required int categorieId,
    required String marque,
    required String matiere,
    required String sku,
    List<File>? images,
  }) async {
    final payload = <String, dynamic>{
      'nom': nom,
      'description': description.isEmpty ? null : description,
      'details': details.isEmpty ? null : details,
      'prix': prix,
      'actif': actif,
      'categorieId': categorieId,
      'marque': marque.isEmpty ? null : marque,
      'matiere': matiere.isEmpty ? null : matiere,
      'sku': sku.isEmpty ? null : sku,
      'recommended': recommended,
    };

    if (salePrice != null) payload['salePrice'] = salePrice;
    if (saleStartAt != null) payload['saleStartAt'] = saleStartAt.toIso8601String();
    if (saleEndAt != null) payload['saleEndAt'] = saleEndAt.toIso8601String();

    payload.removeWhere((key, value) => value == null);

    final response = await ApiClient.postArticleMultipart(
      '/api/admin/articles',
      jsonEncode(payload),
      images,
    );
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('Failed to create article: ${response.body}');
    }
    return ArticleModel.fromJson(jsonDecode(response.body));
  }

  static Future<ArticleModel> updateArticle(int id, {
    required String nom,
    required String description,
    required String details,
    required double prix,
    double? salePrice,
    DateTime? saleStartAt,
    DateTime? saleEndAt,
    required bool actif,
    required bool recommended,
    required int categorieId,
    required String marque,
    required String matiere,
    required String sku,
    List<File>? images,
  }) async {
    final payload = <String, dynamic>{
      'nom': nom,
      'description': description.isEmpty ? null : description,
      'details': details.isEmpty ? null : details,
      'prix': prix,
      'actif': actif,
      'categorieId': categorieId,
      'marque': marque.isEmpty ? null : marque,
      'matiere': matiere.isEmpty ? null : matiere,
      'sku': sku.isEmpty ? null : sku,
      'recommended': recommended,
    };

    if (salePrice != null) payload['salePrice'] = salePrice;
    if (saleStartAt != null) payload['saleStartAt'] = saleStartAt.toIso8601String();
    if (saleEndAt != null) payload['saleEndAt'] = saleEndAt.toIso8601String();

    payload.removeWhere((key, value) => value == null);

    final response = await ApiClient.putArticleMultipart(
      '/api/admin/articles/$id',
      jsonEncode(payload),
      images,
    );
    if (response.statusCode != 200) throw Exception('Failed to update article: ${response.body}');
    return ArticleModel.fromJson(jsonDecode(response.body));
  }

  static Future<void> deleteArticle(int id) async {
    final response = await ApiClient.delete('/api/admin/articles/$id');
    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception('Failed to delete article');
    }
  }

  // ========== VARIATIONS ==========
  static Future<List<VariationModel>> fetchVariations(int articleId) async {
    final response = await ApiClient.get('/api/admin/articles/$articleId/variations');
    if (response.statusCode != 200) throw Exception('Failed to load variations');
    final List<dynamic> data = jsonDecode(response.body);
    print('📦 Variations fetched: $data'); // Debug
    return data.map((json) => VariationModel.fromJson(json)).toList();
  }
  static Future<VariationModel> createVariation(int articleId, {
    required int couleurId,
    required double prix,
    required int quantiteStock,
    int? tailleId,
    List<File>? images,
    File? model3d,
    List<String> existingImageUrls = const [],
  }) async {
    final payload = <String, dynamic>{
      'prix': prix,
      'couleurId': couleurId,
    };

    if (tailleId != null) {
      payload['sizes'] = [
        {'tailleId': tailleId, 'quantiteStock': quantiteStock}
      ];
    } else {
      payload['quantiteStock'] = quantiteStock;
    }

    if (existingImageUrls.isNotEmpty) {
      payload['existingImageUrls'] = existingImageUrls;
    }

    final response = await ApiClient.postVariationMultipart(
      '/api/admin/articles/$articleId/variations',
      jsonEncode(payload),
      images,
      model3d,
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('Failed to create variation: ${response.body}');
    }

    final List<dynamic> data = jsonDecode(response.body);
    if (data.isEmpty) throw Exception('No variation created');
    return VariationModel.fromJson(data.first);
  }

  static Future<VariationModel> updateVariation(int variationId, {
    required int couleurId,
    required double prix,
    required int quantiteStock,
    int? tailleId,
    List<File>? images,
    File? model3d,
    List<String> existingImageUrls = const [],
  }) async {
    final payload = <String, dynamic>{
      'prix': prix,
      'couleurId': couleurId,
      'quantiteStock': quantiteStock,
    };

    if (tailleId != null) payload['tailleId'] = tailleId;
    if (existingImageUrls.isNotEmpty) payload['existingImageUrls'] = existingImageUrls;

    final response = await ApiClient.putVariationMultipart(
      '/api/admin/variations/$variationId',
      jsonEncode(payload),
      images,
      model3d,
    );

    if (response.statusCode != 200) throw Exception('Failed to update variation: ${response.body}');
    return VariationModel.fromJson(jsonDecode(response.body));
  }

  static Future<void> deleteVariation(int variationId) async {
    final response = await ApiClient.delete('/api/admin/variations/$variationId');
    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception('Failed to delete variation');
    }
  }

  static Future<void> updateStock(int variationId, int quantity, {required bool increment}) async {
    final response = await ApiClient.patch(
      '/api/admin/variations/$variationId/stock',
      body: {'quantity': quantity, 'increment': increment},
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to update stock: ${response.body}');
    }
  }

  // ========== CATEGORIES ==========
  static Future<List<CategoryModel>> fetchAllCategories() async {
    final response = await ApiClient.get('/api/admin/categories');
    if (response.statusCode != 200) throw Exception('Failed to load categories');
    final List<dynamic> data = jsonDecode(response.body);
    return data.map((json) => CategoryModel.fromJson(json)).toList();
  }

  static Future<List<CategoryModel>> fetchMainCategories() async {
    final response = await ApiClient.get('/api/categories/main');
    if (response.statusCode != 200) throw Exception('Failed to load main categories');
    final List<dynamic> data = jsonDecode(response.body);
    return data.map((json) => CategoryModel.fromJson(json)).toList();
  }

  static Future<CategoryModel> createCategory({
    required String nom,
    String? description,
    int? parentId,
    int displayOrder = 0,
    String? iconUrl,
    bool actif = true,
  }) async {
    final response = await ApiClient.post('/api/admin/categories', {
      'nom': nom,
      'description': description,
      'parentId': parentId,
      'displayOrder': displayOrder,
      'iconUrl': iconUrl,
      'actif': actif,
    });
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('Failed to create category: ${response.body}');
    }
    return CategoryModel.fromJson(jsonDecode(response.body));
  }

  static Future<CategoryModel> updateCategory(int id, {
    required String nom,
    String? description,
    int? parentId,
    int displayOrder = 0,
    String? iconUrl,
    bool actif = true,
  }) async {
    final response = await ApiClient.put('/api/admin/categories/$id', {
      'nom': nom,
      'description': description,
      'parentId': parentId,
      'displayOrder': displayOrder,
      'iconUrl': iconUrl,
      'actif': actif,
    });
    if (response.statusCode != 200) throw Exception('Failed to update category: ${response.body}');
    return CategoryModel.fromJson(jsonDecode(response.body));
  }

  static Future<void> deleteCategory(int id) async {
    final response = await ApiClient.delete('/api/admin/categories/$id');
    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception('Failed to delete category');
    }
  }

  // ========== COLORS ==========
  static Future<List<ColorModel>> fetchColors() async {
    final response = await ApiClient.get('/api/admin/colors');
    if (response.statusCode != 200) throw Exception('Failed to load colors');
    final List<dynamic> data = jsonDecode(response.body);
    return data.map((json) => ColorModel.fromJson(json)).toList();
  }

  static Future<ColorModel> createColor(String nom, String codeHex) async {
    final response = await ApiClient.post('/api/admin/colors', {'nom': nom, 'codeHex': codeHex});
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('Failed to create color: ${response.body}');
    }
    return ColorModel.fromJson(jsonDecode(response.body));
  }

  static Future<ColorModel> updateColor(int id, String nom, String codeHex) async {
    final response = await ApiClient.put('/api/admin/colors/$id', {'nom': nom, 'codeHex': codeHex});
    if (response.statusCode != 200) throw Exception('Failed to update color: ${response.body}');
    return ColorModel.fromJson(jsonDecode(response.body));
  }

  static Future<void> deleteColor(int id) async {
    final response = await ApiClient.delete('/api/admin/colors/$id');
    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception('Failed to delete color');
    }
  }

  // ========== SIZES ==========
  static Future<List<SizeModel>> fetchSizes() async {
    final response = await ApiClient.get('/api/admin/sizes');
    if (response.statusCode != 200) throw Exception('Failed to load sizes');
    final List<dynamic> data = jsonDecode(response.body);
    return data.map((json) => SizeModel.fromJson(json)).toList();
  }

  static Future<SizeModel> createSize(String pointure) async {
    final response = await ApiClient.post('/api/admin/sizes', {'pointure': pointure});
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('Failed to create size: ${response.body}');
    }
    return SizeModel.fromJson(jsonDecode(response.body));
  }

  static Future<SizeModel> updateSize(int id, String pointure) async {
    final response = await ApiClient.put('/api/admin/sizes/$id', {'pointure': pointure});
    if (response.statusCode != 200) throw Exception('Failed to update size: ${response.body}');
    return SizeModel.fromJson(jsonDecode(response.body));
  }

  static Future<void> deleteSize(int id) async {
    final response = await ApiClient.delete('/api/admin/sizes/$id');
    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception('Failed to delete size');
    }
  }

  // ========== HISTORY ==========
  static Future<List<HistoryEntryModel>> fetchGlobalHistory({
    String? action,
    String? targetType,
    String? searchTerm,
    DateTime? dateFrom,
    DateTime? dateTo,
    int limit = 500,
  }) async {
    String url = '/api/admin/catalog/history/all?limit=$limit';
    if (action != null && action.isNotEmpty) url += '&action=$action';
    if (targetType != null && targetType.isNotEmpty) url += '&targetType=$targetType';

    final response = await ApiClient.get(url);
    if (response.statusCode != 200) throw Exception('Failed to load global history: ${response.body}');

    final List<dynamic> data = jsonDecode(response.body);
    List<HistoryEntryModel> entries = data.map((json) => HistoryEntryModel.fromJson(json)).toList();

    if (searchTerm != null && searchTerm.isNotEmpty) {
      final searchLower = searchTerm.toLowerCase();
      entries = entries.where((e) =>
      (e.articleName?.toLowerCase().contains(searchLower) ?? false) ||
          (e.variationLabel?.toLowerCase().contains(searchLower) ?? false) ||
          e.summary.toLowerCase().contains(searchLower) ||
          e.actorName.toLowerCase().contains(searchLower)
      ).toList();
    }
    if (dateFrom != null) {
      entries = entries.where((e) => e.actionAt.isAfter(dateFrom)).toList();
    }
    if (dateTo != null) {
      final endOfDay = DateTime(dateTo.year, dateTo.month, dateTo.day, 23, 59, 59, 999);
      entries = entries.where((e) => e.actionAt.isBefore(endOfDay)).toList();
    }
    return entries;
  }

}