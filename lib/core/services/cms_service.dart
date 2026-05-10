import 'dart:convert';
import '../api/api_client.dart';
import '../constants/api_routes.dart';
import '../models/cms_article_model.dart';

class CmsService {
  static List<dynamic> _extractList(dynamic decoded) {
    if (decoded is List) return decoded;
    if (decoded is Map<String, dynamic>) {
      if (decoded['content'] is List) return decoded['content'];
      if (decoded['data'] is List) return decoded['data'];
      if (decoded['items'] is List) return decoded['items'];
    }
    return [];
  }

  static Future<List<CmsArticle>> fetchArticles() async {
    final res = await ApiClient.get(ApiRoutes.articles, auth: false);
    if (res.statusCode == 200) {
      final list = _extractList(jsonDecode(res.body));
      return list.map((e) => CmsArticle.fromJson(e)).toList();
    }
    return [];
  }

  static Future<CmsArticle?> fetchArticleById(int id) async {
    final res = await ApiClient.get('${ApiRoutes.articles}/$id', auth: false);
    if (res.statusCode == 200) {
      return CmsArticle.fromJson(jsonDecode(res.body));
    }
    return null;
  }
}