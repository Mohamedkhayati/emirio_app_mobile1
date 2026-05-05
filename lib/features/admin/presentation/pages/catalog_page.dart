import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class CatalogPage extends StatefulWidget {
  final String baseUrl;
  final String? authToken;
  final bool isAdminGeneral;
  final bool isCatalogManager;
  final bool isEcommerceManager;

  const CatalogPage({
    super.key,
    required this.baseUrl,
    this.authToken,
    this.isAdminGeneral = false,
    this.isCatalogManager = false,
    this.isEcommerceManager = false,
  });

  @override
  State<CatalogPage> createState() => _CatalogPageState();
}

class _CatalogPageState extends State<CatalogPage> {
  final ScrollController _scrollController = ScrollController();

  List<Article> articles = [];
  List<CategoryItem> allCategories = [];
  List<CategoryItem> mainCategories = [];
  List<ColorItem> colors = [];
  List<SizeItem> sizes = [];
  List<VariationItem> variations = [];
  List<HistoryRow> historyRows = [];
  List<HistoryRow> globalHistory = [];

  Article? selectedArticle;

  String catalogQ = '';
  String selectedCategoryFilter = '';
  String catalogError = '';
  bool busyCatalog = false;
  bool historyLoading = false;
  bool globalHistoryLoading = false;

  String historyMode = 'article';
  String selectedVariationHistoryId = '';

  int articlePage = 1;
  int articleRows = 5;
  int variationPage = 1;
  int variationRows = 3;
  int categoryPage = 1;
  int categoryRows = 3;
  int colorPage = 1;
  int colorRows = 3;
  int sizePage = 1;
  int sizeRows = 3;

  HistoryFilterData historyFilter = HistoryFilterData();

  bool get hasAccess =>
      widget.isAdminGeneral ||
          widget.isCatalogManager ||
          widget.isEcommerceManager;

  @override
  void initState() {
    super.initState();
    _refreshCatalog(pickFirst: true);
    _loadGlobalHistory();
  }

  Map<String, String> get _headers {
    final headers = <String, String>{
      'Accept': 'application/json',
    };
    if (widget.authToken != null && widget.authToken!.trim().isNotEmpty) {
      headers['Authorization'] = 'Bearer ${widget.authToken}';
    }
    return headers;
  }

  Uri _uri(String path, [Map<String, String>? query]) {
    final base = Uri.parse(widget.baseUrl);
    return base.replace(
      path: '${base.path}${path.startsWith('/') ? path : '/$path'}',
      queryParameters: query,
    );
  }

  Future<dynamic> _getJson(String path, {Map<String, String>? query}) async {
    final res = await http.get(_uri(path, query), headers: _headers);
    return _decodeResponse(res);
  }

  Future<dynamic> _postJson(String path, Map<String, dynamic> body) async {
    final res = await http.post(
      _uri(path),
      headers: {
        ..._headers,
        'Content-Type': 'application/json',
      },
      body: jsonEncode(body),
    );
    return _decodeResponse(res);
  }

  Future<dynamic> _putJson(String path, Map<String, dynamic> body) async {
    final res = await http.put(
      _uri(path),
      headers: {
        ..._headers,
        'Content-Type': 'application/json',
      },
      body: jsonEncode(body),
    );
    return _decodeResponse(res);
  }

  Future<void> _deleteRequest(String path) async {
    final res = await http.delete(_uri(path), headers: _headers);
    _decodeResponse(res);
  }

  Future<dynamic> _multipartRequest({
    required String method,
    required String path,
    required Map<String, dynamic> data,
    List<PlatformFile> imageFiles = const [],
    PlatformFile? model3dFile,
  }) async {
    final req = http.MultipartRequest(method, _uri(path));
    req.headers.addAll(_headers);
    req.fields['data'] = jsonEncode(data);

    for (final file in imageFiles) {
      req.files.add(await _toMultipartFile('images', file));
    }

    if (model3dFile != null) {
      req.files.add(await _toMultipartFile('model3d', model3dFile));
    }

    final streamed = await req.send();
    final res = await http.Response.fromStream(streamed);
    return _decodeResponse(res);
  }

  Future<http.MultipartFile> _toMultipartFile(
      String field,
      PlatformFile file,
      ) async {
    if (file.bytes != null) {
      return http.MultipartFile.fromBytes(
        field,
        file.bytes!,
        filename: file.name,
      );
    }
    if (file.path != null) {
      return await http.MultipartFile.fromPath(
        field,
        file.path!,
        filename: file.name,
      );
    }
    throw Exception('Invalid file: ${file.name}');
  }

  dynamic _decodeResponse(http.Response res) {
    final body = res.body.trim();
    if (res.statusCode < 200 || res.statusCode >= 300) {
      try {
        final decoded = body.isEmpty ? {} : jsonDecode(body);
        throw Exception(
          decoded is Map && decoded['message'] != null
              ? decoded['message'].toString()
              : 'Request failed (${res.statusCode})',
        );
      } catch (_) {
        throw Exception(body.isEmpty ? 'Request failed (${res.statusCode})' : body);
      }
    }
    if (body.isEmpty) return null;
    try {
      return jsonDecode(body);
    } catch (_) {
      return body;
    }
  }

  List<Article> get filteredArticles {
    final search = catalogQ.trim().toLowerCase();
    final allowedCategoryIds = selectedCategoryFilter.isEmpty
        ? null
        : _getDescendantIds(int.tryParse(selectedCategoryFilter));

    return articles.where((a) {
      final text = '${a.nom} ${a.description} ${a.categorieNom} ${a.marque} ${a.sku}'
          .toLowerCase();
      final matchesText = search.isEmpty || text.contains(search);
      final matchesCategory = allowedCategoryIds == null ||
          allowedCategoryIds.contains(a.categorieId?.toString());
      return matchesText && matchesCategory;
    }).toList();
  }

  List<VariationGroup> get groupedVariationRows {
    final map = <String, VariationGroup>{};

    for (final v in variations) {
      final key = (v.couleurId?.toString().isNotEmpty == true)
          ? v.couleurId.toString()
          : '${v.couleurNom}_${v.id}';

      if (!map.containsKey(key)) {
        map[key] = VariationGroup(
          key: key,
          couleurId: v.couleurId,
          couleurNom: v.couleurNom.isNotEmpty ? v.couleurNom : '-',
          couleurCodeHex: v.couleurCodeHex,
          prix: v.prix,
          quantiteStock: 0,
          imageUrls: List<String>.from(v.imageUrls),
          model3dUrl: v.model3dUrl,
          model3dName: v.model3dName,
          model3dType: v.model3dType,
          items: [],
        );
      }

      final group = map[key]!;
      group.items.add(v);
      group.quantiteStock += v.quantiteStock;
      if (group.imageUrls.isEmpty && v.imageUrls.isNotEmpty) {
        group.imageUrls = List<String>.from(v.imageUrls);
      }
      if (group.model3dUrl.isEmpty && v.model3dUrl.isNotEmpty) {
        group.model3dUrl = v.model3dUrl;
        group.model3dName = v.model3dName;
        group.model3dType = v.model3dType;
      }
    }

    return map.values.toList();
  }

  bool get isAccessoryCategory {
    final raw = selectedArticle?.categorieNom ?? '';
    final normalized = raw.trim().toLowerCase();
    return normalized == 'sac a main' ||
        normalized == 'sac à main' ||
        normalized == 'pochette de soirée';
  }

  Future<void> _refreshCatalog({bool pickFirst = false}) async {
    if (!hasAccess) return;

    setState(() {
      busyCatalog = true;
      catalogError = '';
    });

    try {
      final results = await Future.wait([
        _getJson('/api/admin/articles'),
        _getJson('/api/categories/main'),
        _getJson('/api/admin/categories'),
        _getJson('/api/admin/colors'),
        _getJson('/api/admin/sizes'),
      ]);

      final List<Article> articleList = _mapList<Article>(results[0], Article.fromJson);
      final List<CategoryItem> mains = _mapList<CategoryItem>(results[1], CategoryItem.fromJson);
      final List<CategoryItem> cats = _mapList<CategoryItem>(results[2], CategoryItem.fromJson);
      final List<ColorItem> cols = _mapList<ColorItem>(results[3], ColorItem.fromJson);
      final List<SizeItem> siz = _mapList<SizeItem>(results[4], SizeItem.fromJson);

      setState(() {
        articles = articleList;
        mainCategories = mains;
        allCategories = cats;
        colors = cols;
        sizes = siz;
      });

      if (articleList.isEmpty) {
        setState(() {
          selectedArticle = null;
          variations = [];
          historyRows = [];
          selectedVariationHistoryId = '';
        });
        return;
      }

      if (pickFirst) {
        await _loadArticleDetails(articleList.first.id!);
      } else {
        final stillExists = selectedArticle != null &&
            articleList.any((a) => a.id == selectedArticle!.id);
        await _loadArticleDetails(stillExists ? selectedArticle!.id! : articleList.first.id!);
      }
    } catch (e) {
      setState(() {
        catalogError = e.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      if (mounted) {
        setState(() {
          busyCatalog = false;
        });
      }
    }
  }

  List<T> _mapList<T>(
      dynamic value,
      T Function(Map<String, dynamic>) fromJson,
      ) {
    if (value is! List) return <T>[];

    return value.map<T>((item) {
      if (item is Map<String, dynamic>) {
        return fromJson(item);
      }
      if (item is Map) {
        return fromJson(item.map((k, v) => MapEntry('$k', v)));
      }
      return fromJson(<String, dynamic>{});
    }).toList();
  }

  Future<void> _loadArticleDetails(int id) async {
    try {
      final results = await Future.wait([
        _getJson('/api/articles/$id'),
        _getJson('/api/admin/articles/$id/variations'),
      ]);

      final articleData = Article.fromJson(_asMap(results[0]));
      final publicVariations = articleData.variations;
      final List<VariationItem> adminVariations =
      _mapList<VariationItem>(results[1], VariationItem.fromJson);

      final publicMap = {
        for (final v in publicVariations) (v.id?.toString() ?? ''): v,
      };

      final merged = adminVariations.map((v) {
        final pub = publicMap[v.id?.toString()] ?? VariationItem.empty();
        return v.merge(pub);
      }).toList();

      setState(() {
        selectedArticle = articleData;
        variations = merged;
        variationPage = 1;
        catalogError = '';
      });

      await _syncHistory(articleData, merged);
    } catch (e) {
      setState(() {
        catalogError = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  Future<void> _loadArticleHistory(int articleId) async {
    setState(() => historyLoading = true);
    try {
      final data = await _getJson('/api/admin/articles/$articleId/history');
      setState(() {
        historyRows = _mapList<HistoryRow>(data, HistoryRow.fromJson);
      });
    } catch (e) {
      setState(() {
        historyRows = [];
        catalogError = e.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      if (mounted) setState(() => historyLoading = false);
    }
  }

  Future<void> _loadVariationHistory(String variationId) async {
    if (variationId.isEmpty) {
      setState(() => historyRows = []);
      return;
    }
    setState(() => historyLoading = true);
    try {
      final data = await _getJson('/api/admin/variations/$variationId/history');
      setState(() {
        historyRows = _mapList<HistoryRow>(data, HistoryRow.fromJson);
      });
    } catch (e) {
      setState(() {
        historyRows = [];
        catalogError = e.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      if (mounted) setState(() => historyLoading = false);
    }
  }

  Future<void> _syncHistory(Article articleData, List<VariationItem> variationData) async {
    if (historyMode == 'variation') {
      final candidate = selectedVariationHistoryId.isNotEmpty
          ? selectedVariationHistoryId
          : (variationData.isNotEmpty ? variationData.first.id.toString() : '');
      setState(() {
        selectedVariationHistoryId = candidate;
      });
      if (candidate.isNotEmpty) {
        await _loadVariationHistory(candidate);
      } else {
        setState(() => historyRows = []);
      }
    } else {
      await _loadArticleHistory(articleData.id!);
    }
  }

  Future<void> _loadGlobalHistory() async {
    setState(() => globalHistoryLoading = true);
    try {
      final query = <String, String>{'limit': '500'};
      if (historyFilter.action.isNotEmpty) {
        query['action'] = historyFilter.action;
      }
      if (historyFilter.targetType.isNotEmpty) {
        query['targetType'] = historyFilter.targetType;
      }

      final data = await _getJson('/api/admin/catalog/history/all', query: query);
      List<HistoryRow> rows = _mapList<HistoryRow>(data, HistoryRow.fromJson);

      if (historyFilter.searchTerm.trim().isNotEmpty) {
        final s = historyFilter.searchTerm.trim().toLowerCase();
        rows = rows.where((row) {
          return row.articleName.toLowerCase().contains(s) ||
              row.variationLabel.toLowerCase().contains(s) ||
              row.summary.toLowerCase().contains(s) ||
              row.actorName.toLowerCase().contains(s);
        }).toList();
      }

      if (historyFilter.dateFrom != null) {
        rows = rows.where((row) {
          final d = row.actionAt;
          return d == null || !d.isBefore(historyFilter.dateFrom!);
        }).toList();
      }

      if (historyFilter.dateTo != null) {
        final to = DateTime(
          historyFilter.dateTo!.year,
          historyFilter.dateTo!.month,
          historyFilter.dateTo!.day,
          23,
          59,
          59,
          999,
        );
        rows = rows.where((row) {
          final d = row.actionAt;
          return d == null || !d.isAfter(to);
        }).toList();
      }

      setState(() {
        globalHistory = rows;
      });
    } catch (e) {
      setState(() {
        catalogError = e.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      if (mounted) setState(() => globalHistoryLoading = false);
    }
  }

  Future<void> _saveArticle(ArticleFormData form, {int? editingArticleId}) async {
    final prix = double.tryParse(form.prix);
    final salePrice = form.salePrice.trim().isEmpty ? null : double.tryParse(form.salePrice);

    if (form.nom.trim().isEmpty) {
      _showError('Article name is required.');
      return;
    }
    if (form.categorieId == null) {
      _showError('Please select a category.');
      return;
    }
    if (prix == null || prix <= 0) {
      _showError('Price must be greater than 0.');
      return;
    }
    if (salePrice != null && (salePrice < 0 || salePrice >= prix)) {
      _showError('Sale price must be lower than the main price.');
      return;
    }

    setState(() {
      busyCatalog = true;
      catalogError = '';
    });

    try {
      final payload = {
        'nom': form.nom.trim(),
        'description': form.description.trim(),
        'details': form.details.trim(),
        'prix': prix,
        'actif': form.actif,
        'categorieId': form.categorieId,
        'marque': form.marque.trim(),
        'matiere': form.matiere.trim(),
        'sku': form.sku.trim(),
        'salePrice': salePrice,
        'saleStartAt': form.saleStartAt.trim().isEmpty ? null : form.saleStartAt.trim(),
        'saleEndAt': form.saleEndAt.trim().isEmpty ? null : form.saleEndAt.trim(),
        'recommended': form.recommended,
      };

      if (editingArticleId != null) {
        await _multipartRequest(
          method: 'PUT',
          path: '/api/admin/articles/$editingArticleId',
          data: payload,
        );
      } else {
        await _multipartRequest(
          method: 'POST',
          path: '/api/admin/articles',
          data: payload,
        );
      }

      await _refreshCatalog(pickFirst: editingArticleId == null);
    } catch (e) {
      _showError(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => busyCatalog = false);
    }
  }

  Future<void> _deleteArticle(int id) async {
    final ok = await _confirm('Delete this article?');
    if (!ok) return;

    setState(() => busyCatalog = true);
    try {
      await _deleteRequest('/api/admin/articles/$id');
      if (selectedArticle?.id == id) {
        selectedArticle = null;
        variations = [];
        historyRows = [];
        selectedVariationHistoryId = '';
      }
      await _refreshCatalog(pickFirst: true);
    } catch (e) {
      _showError(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => busyCatalog = false);
    }
  }

  Future<void> _saveCategory(CategoryFormData form, {int? editingId}) async {
    if (form.nom.trim().isEmpty) {
      _showError('Category name is required.');
      return;
    }

    setState(() => busyCatalog = true);
    try {
      final payload = {
        'nom': form.nom.trim(),
        'description': form.description.trim(),
        'parentId': form.parentId,
        'level': form.parentId == null ? 'MAIN' : 'SUB',
        'mainCategory': form.mainCategory,
        'displayOrder': form.displayOrder,
        'iconUrl': form.iconUrl.trim(),
        'actif': form.actif,
      };

      if (editingId != null) {
        await _putJson('/api/admin/categories/$editingId', payload);
      } else {
        await _postJson('/api/admin/categories', payload);
      }
      await _refreshCatalog();
    } catch (e) {
      _showError(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => busyCatalog = false);
    }
  }

  Future<void> _deleteCategory(int id) async {
    final ok = await _confirm('Delete this category?');
    if (!ok) return;

    setState(() => busyCatalog = true);
    try {
      await _deleteRequest('/api/admin/categories/$id');
      await _refreshCatalog();
    } catch (e) {
      _showError(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => busyCatalog = false);
    }
  }

  Future<void> _saveColor(ColorFormData form, {int? editingId}) async {
    if (form.nom.trim().isEmpty) {
      _showError('Color name is required.');
      return;
    }

    setState(() => busyCatalog = true);
    try {
      final payload = {
        'nom': form.nom.trim(),
        'codeHex': form.codeHex.trim().isEmpty ? '#000000' : form.codeHex.trim(),
      };
      if (editingId != null) {
        await _putJson('/api/admin/colors/$editingId', payload);
      } else {
        await _postJson('/api/admin/colors', payload);
      }
      await _refreshCatalog();
    } catch (e) {
      _showError(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => busyCatalog = false);
    }
  }

  Future<void> _deleteColor(int id) async {
    final ok = await _confirm('Delete this color?');
    if (!ok) return;

    setState(() => busyCatalog = true);
    try {
      await _deleteRequest('/api/admin/colors/$id');
      await _refreshCatalog();
    } catch (e) {
      _showError(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => busyCatalog = false);
    }
  }

  Future<void> _saveSize(SizeFormData form, {int? editingId}) async {
    if (form.pointure.trim().isEmpty) {
      _showError('Size is required.');
      return;
    }

    setState(() => busyCatalog = true);
    try {
      final payload = {'pointure': form.pointure.trim()};
      if (editingId != null) {
        await _putJson('/api/admin/sizes/$editingId', payload);
      } else {
        await _postJson('/api/admin/sizes', payload);
      }
      await _refreshCatalog();
    } catch (e) {
      _showError(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => busyCatalog = false);
    }
  }

  Future<void> _deleteSize(int id) async {
    final ok = await _confirm('Delete this size?');
    if (!ok) return;

    setState(() => busyCatalog = true);
    try {
      await _deleteRequest('/api/admin/sizes/$id');
      await _refreshCatalog();
    } catch (e) {
      _showError(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => busyCatalog = false);
    }
  }

  Future<void> _saveVariationCreate(VariationFormData form) async {
    if (selectedArticle == null) return;

    final couleurId = int.tryParse(form.couleurId);
    final prix = double.tryParse(form.prix);

    if (couleurId == null) {
      _showError('Please select a color.');
      return;
    }
    if (prix == null || prix <= 0) {
      _showError('Price must be greater than 0.');
      return;
    }

    setState(() => busyCatalog = true);
    try {
      if (isAccessoryCategory) {
        final stock = int.tryParse(form.quantiteStock);
        if (stock == null || stock < 0) {
          _showError('Stock must be a whole number equal to or greater than 0.');
          return;
        }

        final payload = {
          'prix': prix,
          'couleurId': couleurId,
          'quantiteStock': stock,
          'existingImageUrls': form.existingImageUrls,
        };

        await _multipartRequest(
          method: 'POST',
          path: '/api/admin/articles/${selectedArticle!.id}/variations',
          data: payload,
          imageFiles: form.imageFiles,
          model3dFile: form.model3dFile,
        );
      } else {
        final activeRows = form.sizeStocks.where((e) => e.checked).toList();
        if (activeRows.isEmpty) {
          _showError('Please select at least one size.');
          return;
        }

        final sizesPayload = <Map<String, dynamic>>[];
        for (final row in activeRows) {
          final stock = int.tryParse(row.quantiteStock);
          if (stock == null || stock < 0) {
            _showError('Stock for size ${row.label} must be a whole number equal to or greater than 0.');
            return;
          }
          sizesPayload.add({
            'tailleId': row.tailleId,
            'quantiteStock': stock,
          });
        }

        final payload = {
          'prix': prix,
          'couleurId': couleurId,
          'sizes': sizesPayload,
          'existingImageUrls': form.existingImageUrls,
        };

        await _multipartRequest(
          method: 'POST',
          path: '/api/admin/articles/${selectedArticle!.id}/variations',
          data: payload,
          imageFiles: form.imageFiles,
          model3dFile: form.model3dFile,
        );
      }

      await _loadArticleDetails(selectedArticle!.id!);
      await _refreshCatalog();
    } catch (e) {
      _showError(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => busyCatalog = false);
    }
  }

  Future<void> _saveVariationGroup(VariationGroupFormData form) async {
    if (selectedArticle == null) return;

    final couleurId = int.tryParse(form.couleurId);
    if (couleurId == null) {
      _showError('Please select a color.');
      return;
    }

    setState(() => busyCatalog = true);
    try {
      if (isAccessoryCategory) {
        final row = form.rows.isNotEmpty ? form.rows.first : null;
        final stock = int.tryParse(row?.quantiteStock ?? '');
        final prix = double.tryParse(row?.prix ?? form.prix);

        if (stock == null || stock < 0) {
          _showError('Stock must be a whole number equal to or greater than 0.');
          return;
        }
        if (prix == null || prix <= 0) {
          _showError('Price must be greater than 0.');
          return;
        }

        final payload = {
          'prix': prix,
          'couleurId': couleurId,
          'quantiteStock': stock,
          'existingImageUrls': form.existingImageUrls,
        };

        if (row?.variationId != null) {
          await _multipartRequest(
            method: 'PUT',
            path: '/api/admin/variations/${row!.variationId}',
            data: payload,
            imageFiles: form.imageFiles,
            model3dFile: form.model3dFile,
          );
        } else {
          await _multipartRequest(
            method: 'POST',
            path: '/api/admin/articles/${selectedArticle!.id}/variations',
            data: payload,
            imageFiles: form.imageFiles,
            model3dFile: form.model3dFile,
          );
        }
      } else {
        final allRows = form.rows;
        final activeRows = allRows.where((r) => r.checked).toList();
        final existingRows = activeRows.where((r) => r.variationId != null).toList();
        final newRows = activeRows.where((r) => r.variationId == null).toList();
        final removedRows = allRows.where((r) => !r.checked && r.variationId != null).toList();

        if (activeRows.isEmpty) {
          _showError('Please select at least one size.');
          return;
        }

        for (final row in activeRows) {
          final stock = int.tryParse(row.quantiteStock);
          final prix = double.tryParse(row.prix);
          if (stock == null || stock < 0) {
            _showError('Stock for size ${row.label} must be a whole number equal to or greater than 0.');
            return;
          }
          if (prix == null || prix <= 0) {
            _showError('Price must be greater than 0.');
            return;
          }
        }

        for (final row in removedRows) {
          await _deleteRequest('/api/admin/variations/${row.variationId}');
        }

        for (final row in existingRows) {
          await _multipartRequest(
            method: 'PUT',
            path: '/api/admin/variations/${row.variationId}',
            data: {
              'prix': double.parse(row.prix),
              'quantiteStock': int.parse(row.quantiteStock),
              'couleurId': couleurId,
              'tailleId': row.tailleId,
              'existingImageUrls': form.existingImageUrls,
            },
            imageFiles: form.imageFiles,
            model3dFile: form.model3dFile,
          );
        }

        if (newRows.isNotEmpty) {
          await _multipartRequest(
            method: 'POST',
            path: '/api/admin/articles/${selectedArticle!.id}/variations',
            data: {
              'prix': double.parse(newRows.first.prix),
              'couleurId': couleurId,
              'sizes': newRows
                  .map((row) => {
                'tailleId': row.tailleId,
                'quantiteStock': int.parse(row.quantiteStock),
              })
                  .toList(),
            },
            imageFiles: form.imageFiles,
            model3dFile: form.model3dFile,
          );
        }
      }

      await _loadArticleDetails(selectedArticle!.id!);
      await _refreshCatalog();
    } catch (e) {
      _showError(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => busyCatalog = false);
    }
  }

  Future<void> _deleteVariation(int id) async {
    final ok = await _confirm('Delete this variation?');
    if (!ok) return;

    setState(() => busyCatalog = true);
    try {
      await _deleteRequest('/api/admin/variations/$id');
      if (selectedArticle != null) {
        await _loadArticleDetails(selectedArticle!.id!);
      }
      await _refreshCatalog();
    } catch (e) {
      _showError(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => busyCatalog = false);
    }
  }

  Future<void> _submitStockUpdate(StockFormData form) async {
    final variation = variations
        .where((v) => v.id?.toString() == form.variationId)
        .cast<VariationItem?>()
        .firstOrNull;

    if (variation == null) {
      _showError('Variation not found.');
      return;
    }

    final qty = int.tryParse(form.quantity);
    if (qty == null || qty <= 0) {
      _showError('Quantity must be a whole number greater than 0.');
      return;
    }

    final nextStock =
    form.mode == 'increment' ? form.currentStock + qty : form.currentStock - qty;

    if (nextStock < 0) {
      _showError('Resulting stock cannot be negative.');
      return;
    }

    setState(() => busyCatalog = true);
    try {
      await _multipartRequest(
        method: 'PUT',
        path: '/api/admin/variations/${variation.id}',
        data: {
          'prix': variation.prix,
          'quantiteStock': nextStock,
          'couleurId': variation.couleurId,
          'tailleId': variation.tailleId,
        },
      );

      if (selectedArticle != null) {
        await _loadArticleDetails(selectedArticle!.id!);
      }
      await _refreshCatalog();
    } catch (e) {
      _showError(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => busyCatalog = false);
    }
  }

  List<String> _getDescendantIds(int? categoryId) {
    if (categoryId == null) return [];
    final ids = <String>{};
    final stack = <int>[categoryId];

    while (stack.isNotEmpty) {
      final current = stack.removeLast();
      ids.add(current.toString());
      final children = allCategories.where((c) => c.parentId == current);
      for (final child in children) {
        if (child.id != null) stack.add(child.id!);
      }
    }
    return ids.toList();
  }

  List<T> _page<T>(List<T> list, int page, int rows) {
    final start = (page - 1) * rows;
    if (start >= list.length) return [];
    final end = (start + rows).clamp(0, list.length);
    return list.sublist(start, end);
  }

  String getCategoryFullPath(int? categoryId) {
    if (categoryId == null) return '-';
    final category = allCategories.where((c) => c.id == categoryId).firstOrNull;
    if (category == null) return '-';

    if (category.parentId != null) {
      final parent =
          allCategories.where((c) => c.id == category.parentId).firstOrNull;
      if (parent != null && parent.parentId != null) {
        final grandParent =
            allCategories.where((c) => c.id == parent.parentId).firstOrNull;
        if (grandParent != null) {
          return '${grandParent.nom} > ${parent.nom} > ${category.nom}';
        }
      }
      if (parent != null) {
        return '${parent.nom} > ${category.nom}';
      }
    }
    return category.nom;
  }

  String fmtPrice(dynamic value) {
    final n = value is num ? value.toDouble() : double.tryParse('$value');
    if (n == null) return '-';
    return '${n.toStringAsFixed(3)} DT';
  }

  String fmtDate(DateTime? dt) {
    if (dt == null) return '-';
    String two(int v) => v.toString().padLeft(2, '0');
    return '${dt.year}-${two(dt.month)}-${two(dt.day)} ${two(dt.hour)}:${two(dt.minute)}';
  }

  bool isSaleActive(Article article) {
    final now = DateTime.now();
    if (article.salePrice == null || article.salePrice! <= 0) return false;
    if (article.salePrice! >= article.prix) return false;
    if (article.saleStartAt != null && now.isBefore(article.saleStartAt!)) return false;
    if (article.saleEndAt != null && now.isAfter(article.saleEndAt!)) return false;
    return true;
  }

  String salePercent(Article article) {
    if (!isSaleActive(article) || article.salePrice == null) return '0';
    final percent = ((article.prix - article.salePrice!) / article.prix) * 100;
    return percent.round().toString();
  }

  Color parseHexColor(String? hex, {Color fallback = Colors.grey}) {
    if (hex == null || hex.trim().isEmpty) return fallback;
    var value = hex.replaceAll('#', '').trim();
    if (value.length == 6) value = 'FF$value';
    return Color(int.tryParse(value, radix: 16) ?? fallback.value);
  }

  Future<void> _pickImages(ValueChanged<List<PlatformFile>> onPicked) async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      type: FileType.image,
      withData: true,
    );
    if (result != null) {
      onPicked(result.files);
    }
  }

  Future<void> _pickModel(ValueChanged<PlatformFile?> onPicked) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['glb', 'gltf'],
      withData: true,
    );
    if (result != null && result.files.isNotEmpty) {
      onPicked(result.files.first);
    }
  }

  void _showError(String message) {
    setState(() {
      catalogError = message;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<bool> _confirm(String message) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Confirm'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('OK'),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  Future<void> _openArticleDialog({Article? article}) async {
    final form = article == null
        ? ArticleFormData.empty()
        : ArticleFormData.fromArticle(article);

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModal) {
            return Dialog(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 760),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          article == null ? 'Add article' : 'Edit article',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 16),
                        _textField(
                          label: 'Product name',
                          initialValue: form.nom,
                          onChanged: (v) => form.nom = v,
                        ),
                        _dropdownField<int>(
                          label: 'Category',
                          value: form.categorieId,
                          items: allCategories
                              .map(
                                (c) => DropdownMenuItem<int>(
                              value: c.id,
                              child: Text(getCategoryFullPath(c.id)),
                            ),
                          )
                              .toList(),
                          onChanged: (v) => setModal(() => form.categorieId = v),
                        ),
                        _textField(
                          label: 'Short description',
                          initialValue: form.description,
                          maxLines: 2,
                          onChanged: (v) => form.description = v,
                        ),
                        _textField(
                          label: 'More informations',
                          initialValue: form.details,
                          maxLines: 4,
                          onChanged: (v) => form.details = v,
                        ),
                        Row(
                          children: [
                            Expanded(
                              child: _textField(
                                label: 'Price',
                                initialValue: form.prix,
                                keyboardType: TextInputType.number,
                                onChanged: (v) => form.prix = v,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _textField(
                                label: 'Sale price',
                                initialValue: form.salePrice,
                                keyboardType: TextInputType.number,
                                onChanged: (v) => form.salePrice = v,
                              ),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            Expanded(
                              child: _textField(
                                label: 'Sale start (YYYY-MM-DDTHH:mm)',
                                initialValue: form.saleStartAt,
                                onChanged: (v) => form.saleStartAt = v,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _textField(
                                label: 'Sale end (YYYY-MM-DDTHH:mm)',
                                initialValue: form.saleEndAt,
                                onChanged: (v) => form.saleEndAt = v,
                              ),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            Expanded(
                              child: _textField(
                                label: 'Brand',
                                initialValue: form.marque,
                                onChanged: (v) => form.marque = v,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _textField(
                                label: 'Material',
                                initialValue: form.matiere,
                                onChanged: (v) => form.matiere = v,
                              ),
                            ),
                          ],
                        ),
                        _textField(
                          label: 'SKU',
                          initialValue: form.sku,
                          onChanged: (v) => form.sku = v,
                        ),
                        SwitchListTile(
                          value: form.actif,
                          onChanged: (v) => setModal(() => form.actif = v),
                          title: const Text('Active product'),
                          contentPadding: EdgeInsets.zero,
                        ),
                        SwitchListTile(
                          value: form.recommended,
                          onChanged: (v) => setModal(() => form.recommended = v),
                          title: const Text('Best choice'),
                          contentPadding: EdgeInsets.zero,
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('Close'),
                            ),
                            const SizedBox(width: 8),
                            FilledButton(
                              onPressed: () async {
                                await _saveArticle(form, editingArticleId: article?.id);
                                if (mounted) Navigator.pop(context);
                              },
                              child: Text(article == null ? 'Save article' : 'Update article'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _openCategoryDialog({CategoryItem? category}) async {
    final form = category == null
        ? CategoryFormData.empty()
        : CategoryFormData.fromCategory(category);

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModal) {
            return Dialog(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 620),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        Text(
                          category == null ? 'Add category' : 'Edit category',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 16),
                        _textField(
                          label: 'Category name',
                          initialValue: form.nom,
                          onChanged: (v) => form.nom = v,
                        ),
                        _dropdownField<int?>(
                          label: 'Parent category',
                          value: form.parentId,
                          items: [
                            const DropdownMenuItem<int?>(
                              value: null,
                              child: Text('Root category'),
                            ),
                            ...allCategories.map(
                                  (c) => DropdownMenuItem<int?>(
                                value: c.id,
                                child: Text(getCategoryFullPath(c.id)),
                              ),
                            ),
                          ],
                          onChanged: (v) {
                            final main = allCategories.firstWhereOrNull((c) => c.id == v);
                            setModal(() {
                              form.parentId = v;
                              form.mainCategory = main?.nom.toUpperCase() ?? '';
                            });
                          },
                        ),
                        _textField(
                          label: 'Display order',
                          initialValue: form.displayOrder.toString(),
                          keyboardType: TextInputType.number,
                          onChanged: (v) => form.displayOrder = int.tryParse(v) ?? 0,
                        ),
                        _textField(
                          label: 'Icon URL',
                          initialValue: form.iconUrl,
                          onChanged: (v) => form.iconUrl = v,
                        ),
                        _textField(
                          label: 'Description',
                          initialValue: form.description,
                          maxLines: 3,
                          onChanged: (v) => form.description = v,
                        ),
                        SwitchListTile(
                          value: form.actif,
                          onChanged: (v) => setModal(() => form.actif = v),
                          title: const Text('Active'),
                          contentPadding: EdgeInsets.zero,
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('Close'),
                            ),
                            const SizedBox(width: 8),
                            FilledButton(
                              onPressed: () async {
                                await _saveCategory(form, editingId: category?.id);
                                if (mounted) Navigator.pop(context);
                              },
                              child: Text(category == null ? 'Save category' : 'Update category'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _openColorDialog({ColorItem? color}) async {
    final form = color == null ? ColorFormData.empty() : ColorFormData.fromColor(color);

    await showDialog(
      context: context,
      builder: (context) => Dialog(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  color == null ? 'Add color' : 'Edit color',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 16),
                _textField(
                  label: 'Color name',
                  initialValue: form.nom,
                  onChanged: (v) => form.nom = v,
                ),
                _textField(
                  label: 'Hex color',
                  initialValue: form.codeHex,
                  onChanged: (v) => form.codeHex = v,
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Close'),
                    ),
                    const SizedBox(width: 8),
                    FilledButton(
                      onPressed: () async {
                        await _saveColor(form, editingId: color?.id);
                        if (mounted) Navigator.pop(context);
                      },
                      child: Text(color == null ? 'Save color' : 'Update color'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _openSizeDialog({SizeItem? size}) async {
    final form = size == null ? SizeFormData.empty() : SizeFormData.fromSize(size);

    await showDialog(
      context: context,
      builder: (context) => Dialog(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  size == null ? 'Add size' : 'Edit size',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 16),
                _textField(
                  label: 'Size',
                  initialValue: form.pointure,
                  onChanged: (v) => form.pointure = v,
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Close'),
                    ),
                    const SizedBox(width: 8),
                    FilledButton(
                      onPressed: () async {
                        await _saveSize(form, editingId: size?.id);
                        if (mounted) Navigator.pop(context);
                      },
                      child: Text(size == null ? 'Save size' : 'Update size'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _openVariationDialog({VariationGroup? editingGroup}) async {
    if (selectedArticle == null) return;

    if (colors.isEmpty) {
      _showError(isAccessoryCategory
          ? 'Create at least one color before adding a variation.'
          : 'Create at least one color and one size before adding a variation.');
      return;
    }

    if (!isAccessoryCategory && sizes.isEmpty) {
      _showError('Create at least one color and one size before adding a variation.');
      return;
    }

    final VariationFormData? createForm = editingGroup == null
        ? VariationFormData.create(
      articlePrice: selectedArticle!.prix,
      initialColorId: colors.first.id?.toString() ?? '',
      sizes: sizes,
      variations: variations,
      isAccessory: isAccessoryCategory,
    )
        : null;

    final VariationGroupFormData? groupForm = editingGroup != null
        ? VariationGroupFormData.fromGroup(
      group: editingGroup,
      sizes: sizes,
      selectedArticlePrice: selectedArticle!.prix,
      isAccessory: isAccessoryCategory,
    )
        : null;

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModal) {
            final bool isGroup = editingGroup != null;
            return Dialog(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 860),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isGroup ? 'Edit color variations' : 'Add variation',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          isGroup
                              ? 'Color group: ${groupForm!.groupColorName}'
                              : (isAccessoryCategory
                              ? 'Choose one color and enter one stock value.'
                              : 'Choose one color, check sizes, and enter stock for each size.'),
                        ),
                        const SizedBox(height: 16),

                        if (!isGroup)
                          Row(
                            children: [
                              Expanded(
                                child: _dropdownField<String>(
                                  label: 'Color',
                                  value: createForm!.couleurId,
                                  items: colors
                                      .map(
                                        (c) => DropdownMenuItem<String>(
                                      value: c.id.toString(),
                                      child: Text(c.nom),
                                    ),
                                  )
                                      .toList(),
                                  onChanged: (v) {
                                    if (v == null) return;
                                    setModal(() {
                                      createForm.couleurId = v;
                                      createForm.rebuildSizeStocks(sizes, variations);
                                    });
                                  },
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _textField(
                                  label: 'Price',
                                  initialValue: createForm.prix,
                                  keyboardType: TextInputType.number,
                                  onChanged: (v) => createForm.prix = v,
                                ),
                              ),
                            ],
                          )
                        else
                          Row(
                            children: [
                              Expanded(
                                child: _textField(
                                  label: 'Color',
                                  initialValue: groupForm!.groupColorName,
                                  enabled: false,
                                  onChanged: (_) {},
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _textField(
                                  label: 'Price',
                                  initialValue: groupForm.prix,
                                  enabled: false,
                                  onChanged: (_) {},
                                ),
                              ),
                            ],
                          ),

                        const SizedBox(height: 16),

                        if (isAccessoryCategory)
                          _textField(
                            label: 'Stock',
                            initialValue: isGroup
                                ? groupForm!.rows.first.quantiteStock
                                : createForm!.quantiteStock,
                            keyboardType: TextInputType.number,
                            onChanged: (v) {
                              if (isGroup) {
                                groupForm!.rows.first.quantiteStock = v;
                              } else {
                                createForm!.quantiteStock = v;
                              }
                            },
                          )
                        else
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Sizes & stock'),
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 12,
                                runSpacing: 12,
                                children: (isGroup ? groupForm!.rows : createForm!.sizeStocks)
                                    .map((row) {
                                  return SizedBox(
                                    width: 230,
                                    child: Card(
                                      child: Padding(
                                        padding: const EdgeInsets.all(12),
                                        child: Column(
                                          children: [
                                            CheckboxListTile(
                                              value: row.checked,
                                              onChanged: row.disabled
                                                  ? null
                                                  : (v) => setModal(() => row.checked = v ?? false),
                                              title: Text(
                                                'Size ${row.label}${row.disabled ? ' • Already exists' : ''}',
                                              ),
                                              contentPadding: EdgeInsets.zero,
                                              controlAffinity: ListTileControlAffinity.leading,
                                            ),
                                            _textField(
                                              label: 'Stock',
                                              initialValue: row.quantiteStock,
                                              enabled: row.checked,
                                              keyboardType: TextInputType.number,
                                              onChanged: (v) => row.quantiteStock = v,
                                            ),
                                            if (isGroup)
                                              _textField(
                                                label: 'Price',
                                                initialValue: row.prix,
                                                enabled: row.checked,
                                                keyboardType: TextInputType.number,
                                                onChanged: (v) => row.prix = v,
                                              ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                            ],
                          ),

                        const SizedBox(height: 16),
                        const Text('Variation images'),
                        const SizedBox(height: 8),

                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            ...((isGroup ? groupForm!.existingImageUrls : createForm!.existingImageUrls)
                                .asMap()
                                .entries
                                .map(
                                  (entry) => Chip(
                                label: Text('Saved image ${entry.key + 1}'),
                                onDeleted: () {
                                  setModal(() {
                                    if (isGroup) {
                                      groupForm!.existingImageUrls.removeAt(entry.key);
                                    } else {
                                      createForm!.existingImageUrls.removeAt(entry.key);
                                    }
                                  });
                                },
                              ),
                            )),
                            ...((isGroup ? groupForm!.imageFiles : createForm!.imageFiles)
                                .map((f) => Chip(label: Text(f.name)))),
                          ],
                        ),

                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          children: [
                            OutlinedButton(
                              onPressed: () async {
                                await _pickImages((files) {
                                  setModal(() {
                                    if (isGroup) {
                                      groupForm!.imageFiles = files;
                                    } else {
                                      createForm!.imageFiles = files;
                                    }
                                  });
                                });
                              },
                              child: const Text('Pick images'),
                            ),
                            OutlinedButton(
                              onPressed: () async {
                                await _pickModel((file) {
                                  setModal(() {
                                    if (isGroup) {
                                      groupForm!.model3dFile = file;
                                    } else {
                                      createForm!.model3dFile = file;
                                    }
                                  });
                                });
                              },
                              child: const Text('Pick 3D model'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('Close'),
                            ),
                            const SizedBox(width: 8),
                            FilledButton(
                              onPressed: () async {
                                if (isGroup) {
                                  await _saveVariationGroup(groupForm!);
                                } else {
                                  await _saveVariationCreate(createForm!);
                                }
                                if (mounted) Navigator.pop(context);
                              },
                              child: Text(isGroup ? 'Save all sizes' : 'Save variation'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _openStockDialog(VariationItem variation, String mode) async {
    final form = StockFormData(
      variationId: variation.id.toString(),
      label: variationDisplayName(variation),
      currentStock: variation.quantiteStock,
      quantity: '1',
      mode: mode,
    );

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModal) {
            final qty = int.tryParse(form.quantity) ?? 0;
            final nextStock = form.mode == 'increment'
                ? form.currentStock + qty
                : form.currentStock - qty;

            return Dialog(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        form.mode == 'increment'
                            ? 'Restock variation'
                            : 'Use / sell variation',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 12),
                      Text('Variation: ${form.label}'),
                      const SizedBox(height: 8),
                      Text('Current stock: ${form.currentStock}'),
                      const SizedBox(height: 12),
                      _textField(
                        label: form.mode == 'increment' ? 'Add quantity' : 'Remove quantity',
                        initialValue: form.quantity,
                        keyboardType: TextInputType.number,
                        onChanged: (v) => setModal(() => form.quantity = v),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'New stock after update: $nextStock',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: nextStock < 0 ? Colors.red : null,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Close'),
                          ),
                          const SizedBox(width: 8),
                          FilledButton(
                            onPressed: nextStock < 0
                                ? null
                                : () async {
                              await _submitStockUpdate(form);
                              if (mounted) Navigator.pop(context);
                            },
                            child: Text(
                              form.mode == 'increment'
                                  ? 'Confirm restock'
                                  : 'Confirm stock removal',
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  String variationDisplayName(VariationItem v) {
    if (v.taillePointure.isNotEmpty) {
      return '${v.couleurNom} / ${v.taillePointure}';
    }
    return v.couleurNom;
  }

  Widget _textField({
    required String label,
    required String initialValue,
    required ValueChanged<String> onChanged,
    bool enabled = true,
    int maxLines = 1,
    TextInputType? keyboardType,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        initialValue: initialValue,
        onChanged: onChanged,
        enabled: enabled,
        maxLines: maxLines,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }

  Widget _dropdownField<T>({
    required String label,
    required T? value,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T?> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: DropdownButtonFormField<T>(
        value: value,
        items: items,
        onChanged: onChanged,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!hasAccess) {
      return Scaffold(
        appBar: AppBar(title: const Text('Catalog')),
        body: const Center(
          child: Card(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Text("Access denied. You don't have permission to view this page."),
            ),
          ),
        ),
      );
    }

    final pagedArticles = _page(filteredArticles, articlePage, articleRows);
    final pagedVariations = _page(groupedVariationRows, variationPage, variationRows);
    final pagedCategories = _page(allCategories, categoryPage, categoryRows);
    final pagedColors = _page(colors, colorPage, colorRows);
    final pagedSizes = _page(sizes, sizePage, sizeRows);
    final deletedHistory = globalHistory.where((e) => e.action == 'DELETE').toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Catalog'),
        actions: [
          if (busyCatalog)
            const Padding(
              padding: EdgeInsets.only(right: 16),
              child: Center(child: SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))),
            ),
        ],
      ),
      body: SingleChildScrollView(
        controller: _scrollController,
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _headerCard(),
            if (catalogError.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Material(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        Icon(Icons.error_outline, color: Colors.red.shade700),
                        const SizedBox(width: 8),
                        Expanded(child: Text(catalogError)),
                      ],
                    ),
                  ),
                ),
              ),
            const SizedBox(height: 16),
            _articlesSection(pagedArticles),
            const SizedBox(height: 16),
            _variationsSection(pagedVariations),
            const SizedBox(height: 16),
            _globalHistorySection(),
            const SizedBox(height: 16),
            _deletedHistorySection(deletedHistory),
            const SizedBox(height: 16),
            LayoutBuilder(
              builder: (context, constraints) {
                final wide = constraints.maxWidth > 1200;
                return wide
                    ? Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: _categoriesSection(pagedCategories)),
                    const SizedBox(width: 16),
                    Expanded(child: _colorsSection(pagedColors)),
                    const SizedBox(width: 16),
                    Expanded(child: _sizesSection(pagedSizes)),
                  ],
                )
                    : Column(
                  children: [
                    _categoriesSection(pagedCategories),
                    const SizedBox(height: 16),
                    _colorsSection(pagedColors),
                    const SizedBox(height: 16),
                    _sizesSection(pagedSizes),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _headerCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text(
                      'Catalog',
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    subtitle: const Text('Manage products, categories, colors and sizes'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                SizedBox(
                  width: 280,
                  child: TextField(
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      hintText: 'Search articles',
                      prefixIcon: Icon(Icons.search),
                    ),
                    onChanged: (v) => setState(() {
                      catalogQ = v;
                      articlePage = 1;
                    }),
                  ),
                ),
                SizedBox(
                  width: 320,
                  child: DropdownButtonFormField<String>(
                    value: selectedCategoryFilter.isEmpty ? null : selectedCategoryFilter,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      labelText: 'Filter by category',
                    ),
                    items: [
                      const DropdownMenuItem<String>(
                        value: '',
                        child: Text('All categories'),
                      ),
                      ...allCategories.map(
                            (c) => DropdownMenuItem<String>(
                          value: c.id.toString(),
                          child: Text(getCategoryFullPath(c.id)),
                        ),
                      ),
                    ],
                    onChanged: (v) => setState(() {
                      selectedCategoryFilter = v ?? '';
                      articlePage = 1;
                    }),
                  ),
                ),
                OutlinedButton(
                  onPressed: () => _refreshCatalog(),
                  child: const Text('Refresh'),
                ),
                OutlinedButton(
                  onPressed: () {
                    _scrollController.animateTo(
                      1400,
                      duration: const Duration(milliseconds: 400),
                      curve: Curves.easeOut,
                    );
                  },
                  child: const Text('History'),
                ),
                OutlinedButton(
                  onPressed: () => _openSizeDialog(),
                  child: const Text('Add size'),
                ),
                OutlinedButton(
                  onPressed: () => _openCategoryDialog(),
                  child: const Text('Add category'),
                ),
                OutlinedButton(
                  onPressed: () => _openColorDialog(),
                  child: const Text('Add color'),
                ),
                FilledButton(
                  onPressed: () => _openArticleDialog(),
                  child: const Text('Add article'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _articlesSection(List<Article> pagedArticles) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Text(
                  '${filteredArticles.length} articles',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            const SizedBox(height: 12),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columns: const [
                  DataColumn(label: Text('Article')),
                  DataColumn(label: Text('Category')),
                  DataColumn(label: Text('Brand')),
                  DataColumn(label: Text('Price')),
                  DataColumn(label: Text('Status')),
                  DataColumn(label: Text('Actions')),
                ],
                rows: pagedArticles.isEmpty
                    ? [
                  const DataRow(
                    cells: [
                      DataCell(Text('No articles')),
                      DataCell(Text('-')),
                      DataCell(Text('-')),
                      DataCell(Text('-')),
                      DataCell(Text('-')),
                      DataCell(Text('-')),
                    ],
                  ),
                ]
                    : pagedArticles.map((a) {
                  final categoryPath = getCategoryFullPath(a.categorieId);
                  final saleLive = isSaleActive(a);
                  return DataRow(
                    selected: selectedArticle?.id == a.id,
                    cells: [
                      DataCell(
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(a.nom, style: const TextStyle(fontWeight: FontWeight.w600)),
                            Text(
                              '#${a.id ?? '-'}'
                                  '${a.recommended ? ' • Recommended' : ''}'
                                  '${saleLive ? ' • Sale -${salePercent(a)}%' : ''}',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                      DataCell(
                        SizedBox(
                          width: 220,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(a.categorieNom.ifEmpty('-')),
                              if (categoryPath != '-' && categoryPath != a.categorieNom)
                                Text(
                                  categoryPath,
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                            ],
                          ),
                        ),
                      ),
                      DataCell(Text(a.marque.ifEmpty('-'))),
                      DataCell(
                        Text(
                          saleLive
                              ? '${fmtPrice(a.salePrice)} / ${fmtPrice(a.prix)}'
                              : fmtPrice(a.prix),
                        ),
                      ),
                      DataCell(
                        Chip(
                          label: Text(a.actif ? 'ACTIVE' : 'INACTIVE'),
                          backgroundColor: a.actif ? Colors.green.shade50 : Colors.red.shade50,
                        ),
                      ),
                      DataCell(
                        Wrap(
                          spacing: 8,
                          children: [
                            OutlinedButton(
                              onPressed: () => _loadArticleDetails(a.id!),
                              child: const Text('See details'),
                            ),
                            OutlinedButton(
                              onPressed: () => _openArticleDialog(article: a),
                              child: const Text('Edit'),
                            ),
                            OutlinedButton(
                              onPressed: () => _deleteArticle(a.id!),
                              child: const Text('Delete'),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 8),
            _pager(
              total: filteredArticles.length,
              page: articlePage,
              rows: articleRows,
              rowsOptions: const [5, 10, 25, 50],
              onPage: (v) => setState(() => articlePage = v),
              onRows: (v) => setState(() {
                articleRows = v;
                articlePage = 1;
              }),
            ),
          ],
        ),
      ),
    );
  }

  Widget _variationsSection(List<VariationGroup> pagedVariations) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      selectedArticle == null
                          ? 'Variations'
                          : 'Variations — ${selectedArticle!.nom}',
                    ),
                    subtitle: Text(
                      selectedArticle == null
                          ? 'Select an article'
                          : (isAccessoryCategory
                          ? 'Accessory articles use one stock field per color variation.'
                          : 'One article can have many combinations like Black 41, Black 42.'),
                    ),
                  ),
                ),
                if (selectedArticle != null)
                  Wrap(
                    spacing: 8,
                    children: [
                      OutlinedButton(
                        onPressed: () => _openArticleDialog(article: selectedArticle),
                        child: const Text('Edit article'),
                      ),
                      FilledButton(
                        onPressed: () => _openVariationDialog(),
                        child: const Text('Add variation'),
                      ),
                    ],
                  ),
              ],
            ),
            if (selectedArticle == null)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Text('Select an article'),
              )
            else ...[
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  _summaryChip('Price', fmtPrice(selectedArticle!.prix)),
                  _summaryChip('Sale price', fmtPrice(selectedArticle!.salePrice)),
                  _summaryChip('Brand', selectedArticle!.marque.ifEmpty('-')),
                  _summaryChip('Material', selectedArticle!.matiere.ifEmpty('-')),
                  _summaryChip('SKU', selectedArticle!.sku.ifEmpty('-')),
                  _summaryChip('On sale now', isSaleActive(selectedArticle!) ? 'Yes' : 'No'),
                ],
              ),
              const SizedBox(height: 12),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  columns: const [
                    DataColumn(label: Text('Details')),
                    DataColumn(label: Text('Color')),
                    DataColumn(label: Text('Sizes & stock')),
                    DataColumn(label: Text('Price')),
                    DataColumn(label: Text('Stock')),
                    DataColumn(label: Text('3D Model')),
                    DataColumn(label: Text('Actions')),
                  ],
                  rows: pagedVariations.isEmpty
                      ? const [
                    DataRow(
                      cells: [
                        DataCell(Text('No variations')),
                        DataCell(Text('-')),
                        DataCell(Text('-')),
                        DataCell(Text('-')),
                        DataCell(Text('-')),
                        DataCell(Text('-')),
                        DataCell(Text('-')),
                      ],
                    ),
                  ]
                      : pagedVariations.map((group) {
                    return DataRow(
                      cells: [
                        DataCell(
                          SizedBox(
                            width: 180,
                            child: Row(
                              children: [
                                Container(
                                  width: 52,
                                  height: 52,
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade200,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: group.imageUrls.isNotEmpty
                                      ? const Icon(Icons.image_outlined)
                                      : const Text('No image', textAlign: TextAlign.center),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(group.couleurNom, style: const TextStyle(fontWeight: FontWeight.w600)),
                                      Text('${group.items.length} size${group.items.length > 1 ? 's' : ''}'),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        DataCell(
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 8,
                                backgroundColor: parseHexColor(group.couleurCodeHex),
                              ),
                              const SizedBox(width: 8),
                              Text(group.couleurNom),
                            ],
                          ),
                        ),
                        DataCell(
                          SizedBox(
                            width: 280,
                            child: Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: group.items
                                  .map((item) => Chip(
                                label: Text(
                                  '${item.taillePointure.ifEmpty('Stock only')}: ${item.quantiteStock}',
                                ),
                              ))
                                  .toList(),
                            ),
                          ),
                        ),
                        DataCell(Text(fmtPrice(group.prix))),
                        DataCell(
                          Chip(
                            label: Text(group.quantiteStock.toString()),
                            backgroundColor: group.quantiteStock > 0
                                ? Colors.green.shade50
                                : Colors.red.shade50,
                          ),
                        ),
                        DataCell(Text(group.model3dUrl.isNotEmpty ? 'Yes' : 'No')),
                        DataCell(
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              OutlinedButton(
                                onPressed: () => _openVariationDialog(editingGroup: group),
                                child: const Text('Edit color variations'),
                              ),
                              if (group.items.isNotEmpty) ...[
                                OutlinedButton(
                                  onPressed: () => _openStockDialog(group.items.first, 'increment'),
                                  child: const Text('Restock'),
                                ),
                                OutlinedButton(
                                  onPressed: () => _openStockDialog(group.items.first, 'decrement'),
                                  child: const Text('Use qty'),
                                ),
                                OutlinedButton(
                                  onPressed: () => _deleteVariation(group.items.first.id!),
                                  child: const Text('Delete'),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 8),
              _pager(
                total: groupedVariationRows.length,
                page: variationPage,
                rows: variationRows,
                rowsOptions: const [3, 5, 10, 25],
                onPage: (v) => setState(() => variationPage = v),
                onRows: (v) => setState(() {
                  variationRows = v;
                  variationPage = 1;
                }),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _globalHistorySection() {
    final totalCreate = globalHistory.where((h) => h.action == 'CREATE').length;
    final totalUpdate = globalHistory.where((h) => h.action == 'UPDATE').length;
    final totalDelete = globalHistory.where((h) => h.action == 'DELETE').length;
    final totalArticles = globalHistory.where((h) => h.targetType == 'ARTICLE').length;
    final totalVariations = globalHistory.where((h) => h.targetType == 'VARIATION').length;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text('Global Catalog History'),
              subtitle: Text('Track all create, update, and delete actions across the catalog'),
            ),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                SizedBox(
                  width: 180,
                  child: DropdownButtonFormField<String>(
                    value: historyFilter.action.isEmpty ? null : historyFilter.action,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      labelText: 'Action type',
                    ),
                    items: const [
                      DropdownMenuItem(value: '', child: Text('All actions')),
                      DropdownMenuItem(value: 'CREATE', child: Text('Created')),
                      DropdownMenuItem(value: 'UPDATE', child: Text('Edited')),
                      DropdownMenuItem(value: 'DELETE', child: Text('Deleted')),
                    ],
                    onChanged: (v) => setState(() => historyFilter.action = v ?? ''),
                  ),
                ),
                SizedBox(
                  width: 180,
                  child: DropdownButtonFormField<String>(
                    value: historyFilter.targetType.isEmpty ? null : historyFilter.targetType,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      labelText: 'Target type',
                    ),
                    items: const [
                      DropdownMenuItem(value: '', child: Text('All types')),
                      DropdownMenuItem(value: 'ARTICLE', child: Text('Articles only')),
                      DropdownMenuItem(value: 'VARIATION', child: Text('Variations only')),
                    ],
                    onChanged: (v) => setState(() => historyFilter.targetType = v ?? ''),
                  ),
                ),
                SizedBox(
                  width: 280,
                  child: TextField(
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      labelText: 'Search',
                    ),
                    onChanged: (v) => historyFilter.searchTerm = v,
                  ),
                ),
                SizedBox(
                  width: 180,
                  child: TextField(
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      labelText: 'Date from (YYYY-MM-DD)',
                    ),
                    onChanged: (v) => historyFilter.dateFrom = _tryDate(v),
                  ),
                ),
                SizedBox(
                  width: 180,
                  child: TextField(
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      labelText: 'Date to (YYYY-MM-DD)',
                    ),
                    onChanged: (v) => historyFilter.dateTo = _tryDate(v),
                  ),
                ),
                OutlinedButton(
                  onPressed: () {
                    setState(() => historyFilter = HistoryFilterData());
                    _loadGlobalHistory();
                  },
                  child: const Text('Reset all filters'),
                ),
                FilledButton(
                  onPressed: _loadGlobalHistory,
                  child: const Text('Apply filters'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (!globalHistoryLoading && globalHistory.isNotEmpty)
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  _summaryChip('Total records', globalHistory.length.toString()),
                  _summaryChip('Creations', totalCreate.toString()),
                  _summaryChip('Updates', totalUpdate.toString()),
                  _summaryChip('Deletions', totalDelete.toString()),
                  _summaryChip('Articles', totalArticles.toString()),
                  _summaryChip('Variations', totalVariations.toString()),
                ],
              ),
            const SizedBox(height: 16),
            if (globalHistoryLoading)
              const Padding(
                padding: EdgeInsets.all(24),
                child: CircularProgressIndicator(),
              )
            else if (globalHistory.isEmpty)
              const Padding(
                padding: EdgeInsets.all(24),
                child: Text('No history records found'),
              )
            else
              Column(
                children: globalHistory.map((row) => _historyTile(row)).toList(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _deletedHistorySection(List<HistoryRow> deletedHistory) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text('Deleted Items History'),
              subtitle: Text('Track all items that have been removed from the catalog'),
            ),
            if (globalHistoryLoading)
              const Padding(
                padding: EdgeInsets.all(24),
                child: CircularProgressIndicator(),
              )
            else if (deletedHistory.isEmpty)
              const Padding(
                padding: EdgeInsets.all(24),
                child: Text('No deleted items found'),
              )
            else
              Column(
                children: deletedHistory.map((row) => _historyTile(row, deletedOnly: true)).toList(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _categoriesSection(List<CategoryItem> pagedCategories) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(child: Text('Categories', style: Theme.of(context).textTheme.titleMedium)),
                OutlinedButton(
                  onPressed: () => _openCategoryDialog(),
                  child: const Text('Add category'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columns: const [
                  DataColumn(label: Text('Category')),
                  DataColumn(label: Text('Path')),
                  DataColumn(label: Text('Actions')),
                ],
                rows: pagedCategories.isEmpty
                    ? const [
                  DataRow(cells: [
                    DataCell(Text('No categories')),
                    DataCell(Text('-')),
                    DataCell(Text('-')),
                  ]),
                ]
                    : pagedCategories.map((c) {
                  return DataRow(
                    cells: [
                      DataCell(
                        SizedBox(
                          width: 220,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(c.nom, style: const TextStyle(fontWeight: FontWeight.w600)),
                              Text(c.description.ifEmpty('-')),
                            ],
                          ),
                        ),
                      ),
                      DataCell(Text(getCategoryFullPath(c.id))),
                      DataCell(
                        Wrap(
                          spacing: 8,
                          children: [
                            OutlinedButton(
                              onPressed: () => _openCategoryDialog(category: c),
                              child: const Text('Edit'),
                            ),
                            OutlinedButton(
                              onPressed: () => _deleteCategory(c.id!),
                              child: const Text('Delete'),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 8),
            _pager(
              total: allCategories.length,
              page: categoryPage,
              rows: categoryRows,
              rowsOptions: const [3, 5, 10],
              onPage: (v) => setState(() => categoryPage = v),
              onRows: (v) => setState(() {
                categoryRows = v;
                categoryPage = 1;
              }),
            ),
          ],
        ),
      ),
    );
  }

  Widget _colorsSection(List<ColorItem> pagedColors) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(child: Text('Colors', style: Theme.of(context).textTheme.titleMedium)),
                OutlinedButton(
                  onPressed: () => _openColorDialog(),
                  child: const Text('Add color'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columns: const [
                  DataColumn(label: Text('Color')),
                  DataColumn(label: Text('Actions')),
                ],
                rows: pagedColors.isEmpty
                    ? const [
                  DataRow(cells: [
                    DataCell(Text('No colors')),
                    DataCell(Text('-')),
                  ]),
                ]
                    : pagedColors.map((c) {
                  return DataRow(
                    cells: [
                      DataCell(
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 10,
                              backgroundColor: parseHexColor(c.codeHex),
                            ),
                            const SizedBox(width: 8),
                            Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(c.nom, style: const TextStyle(fontWeight: FontWeight.w600)),
                                Text(c.codeHex),
                              ],
                            ),
                          ],
                        ),
                      ),
                      DataCell(
                        Wrap(
                          spacing: 8,
                          children: [
                            OutlinedButton(
                              onPressed: () => _openColorDialog(color: c),
                              child: const Text('Edit'),
                            ),
                            OutlinedButton(
                              onPressed: () => _deleteColor(c.id!),
                              child: const Text('Delete'),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 8),
            _pager(
              total: colors.length,
              page: colorPage,
              rows: colorRows,
              rowsOptions: const [3, 5, 10],
              onPage: (v) => setState(() => colorPage = v),
              onRows: (v) => setState(() {
                colorRows = v;
                colorPage = 1;
              }),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sizesSection(List<SizeItem> pagedSizes) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(child: Text('Sizes', style: Theme.of(context).textTheme.titleMedium)),
                OutlinedButton(
                  onPressed: () => _openSizeDialog(),
                  child: const Text('Add size'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columns: const [
                  DataColumn(label: Text('Size')),
                  DataColumn(label: Text('Actions')),
                ],
                rows: pagedSizes.isEmpty
                    ? const [
                  DataRow(cells: [
                    DataCell(Text('No sizes')),
                    DataCell(Text('-')),
                  ]),
                ]
                    : pagedSizes.map((s) {
                  return DataRow(
                    cells: [
                      DataCell(Text(s.pointure)),
                      DataCell(
                        Wrap(
                          spacing: 8,
                          children: [
                            OutlinedButton(
                              onPressed: () => _openSizeDialog(size: s),
                              child: const Text('Edit'),
                            ),
                            OutlinedButton(
                              onPressed: () => _deleteSize(s.id!),
                              child: const Text('Delete'),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 8),
            _pager(
              total: sizes.length,
              page: sizePage,
              rows: sizeRows,
              rowsOptions: const [3, 5, 10],
              onPage: (v) => setState(() => sizePage = v),
              onRows: (v) => setState(() {
                sizeRows = v;
                sizePage = 1;
              }),
            ),
          ],
        ),
      ),
    );
  }

  Widget _historyTile(HistoryRow row, {bool deletedOnly = false}) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: CircleAvatar(
          child: Text(_initials(row.actorName)),
        ),
        title: Wrap(
          spacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(row.actorName.ifEmpty('SYSTEM')),
            Chip(
              label: Text(deletedOnly ? 'DELETED' : row.actionLabel.ifEmpty(row.action)),
              backgroundColor: row.action == 'CREATE'
                  ? Colors.green.shade50
                  : row.action == 'DELETE'
                  ? Colors.red.shade50
                  : Colors.orange.shade50,
            ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${row.targetType == 'ARTICLE' ? 'Article' : 'Variation'} → '
                  '${row.targetType == 'ARTICLE' ? row.articleName : row.variationLabel}',
            ),
            Text(row.summary.ifEmpty('-')),
            Text('📅 ${fmtDate(row.actionAt)}'),
            if (row.targetType == 'VARIATION' && row.articleName.isNotEmpty)
              Text('📦 Article: ${row.articleName}'),
          ],
        ),
      ),
    );
  }

  Widget _summaryChip(String label, String value) {
    return Chip(
      label: Text('$label: $value'),
      backgroundColor: Colors.grey.shade100,
    );
  }

  Widget _pager({
    required int total,
    required int page,
    required int rows,
    required List<int> rowsOptions,
    required ValueChanged<int> onPage,
    required ValueChanged<int> onRows,
  }) {
    final totalPages = total == 0 ? 1 : (total / rows).ceil();
    final start = total == 0 ? 0 : ((page - 1) * rows) + 1;
    final end = total == 0 ? 0 : (page * rows > total ? total : page * rows);

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        OutlinedButton(
          onPressed: page == 1 ? null : () => onPage(1),
          child: const Text('<<'),
        ),
        OutlinedButton(
          onPressed: page == 1 ? null : () => onPage(page - 1),
          child: const Text('<'),
        ),
        Text('$start to $end of $total'),
        OutlinedButton(
          onPressed: page >= totalPages ? null : () => onPage(page + 1),
          child: const Text('>'),
        ),
        OutlinedButton(
          onPressed: page >= totalPages ? null : () => onPage(totalPages),
          child: const Text('>>'),
        ),
        const Text('Rows'),
        DropdownButton<int>(
          value: rows,
          items: rowsOptions
              .map((e) => DropdownMenuItem<int>(value: e, child: Text('$e')))
              .toList(),
          onChanged: (v) {
            if (v != null) onRows(v);
          },
        ),
      ],
    );
  }

  DateTime? _tryDate(String value) {
    if (value.trim().isEmpty) return null;
    return DateTime.tryParse(value.trim());
  }

  String _initials(String name) {
    if (name.trim().isEmpty) return '?';
    return name
        .split(' ')
        .where((e) => e.trim().isNotEmpty)
        .take(2)
        .map((e) => e[0].toUpperCase())
        .join();
  }

  List<dynamic> _asList(dynamic value) {
    if (value is List) return value;
    return [];
  }

  Map<String, dynamic> _asMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) {
      return value.map((key, val) => MapEntry('$key', val));
    }
    return {};
  }
}

class Article {
  final int? id;
  final String nom;
  final String description;
  final String details;
  final double prix;
  final bool actif;
  final int? categorieId;
  final String categorieNom;
  final String marque;
  final String matiere;
  final String sku;
  final double? salePrice;
  final DateTime? saleStartAt;
  final DateTime? saleEndAt;
  final bool recommended;
  final List<VariationItem> variations;

  Article({
    this.id,
    required this.nom,
    required this.description,
    required this.details,
    required this.prix,
    required this.actif,
    required this.categorieId,
    required this.categorieNom,
    required this.marque,
    required this.matiere,
    required this.sku,
    required this.salePrice,
    required this.saleStartAt,
    required this.saleEndAt,
    required this.recommended,
    required this.variations,
  });

  factory Article.fromJson(Map<String, dynamic> json) {
    return Article(
      id: _toInt(json['id']),
      nom: '${json['nom'] ?? ''}',
      description: '${json['description'] ?? ''}',
      details: '${json['details'] ?? ''}',
      prix: _toDouble(json['prix']) ?? 0,
      actif: _toBool(json['actif']),
      categorieId: _toInt(json['categorieId']),
      categorieNom: '${json['categorieNom'] ?? ''}',
      marque: '${json['marque'] ?? ''}',
      matiere: '${json['matiere'] ?? ''}',
      sku: '${json['sku'] ?? ''}',
      salePrice: _toDouble(json['salePrice']),
      saleStartAt: _toDate(json['saleStartAt']),
      saleEndAt: _toDate(json['saleEndAt']),
      recommended: _toBool(json['recommended']),
      variations: ((json['variations'] as List?) ?? const [])
          .map<VariationItem>((e) {
        if (e is Map<String, dynamic>) {
          return VariationItem.fromJson(e);
        }
        if (e is Map) {
          return VariationItem.fromJson(
            e.map((k, v) => MapEntry('$k', v)),
          );
        }
        return VariationItem.empty();
      })
          .toList(),
    );
  }
}

class CategoryItem {
  final int? id;
  final String nom;
  final String description;
  final int? parentId;
  final String level;
  final String mainCategory;
  final int displayOrder;
  final String iconUrl;
  final bool actif;

  CategoryItem({
    this.id,
    required this.nom,
    required this.description,
    required this.parentId,
    required this.level,
    required this.mainCategory,
    required this.displayOrder,
    required this.iconUrl,
    required this.actif,
  });

  factory CategoryItem.fromJson(Map<String, dynamic> json) {
    return CategoryItem(
      id: _toInt(json['id']),
      nom: '${json['nom'] ?? ''}',
      description: '${json['description'] ?? ''}',
      parentId: _toInt(json['parentId']),
      level: '${json['level'] ?? ''}',
      mainCategory: '${json['mainCategory'] ?? ''}',
      displayOrder: _toInt(json['displayOrder']) ?? 0,
      iconUrl: '${json['iconUrl'] ?? ''}',
      actif: _toBool(json['actif']),
    );
  }
}

class ColorItem {
  final int? id;
  final String nom;
  final String codeHex;

  ColorItem({
    this.id,
    required this.nom,
    required this.codeHex,
  });

  factory ColorItem.fromJson(Map<String, dynamic> json) {
    return ColorItem(
      id: _toInt(json['id']),
      nom: '${json['nom'] ?? ''}',
      codeHex: '${json['codeHex'] ?? json['hexColor'] ?? '#000000'}',
    );
  }
}

class SizeItem {
  final int? id;
  final String pointure;

  SizeItem({
    this.id,
    required this.pointure,
  });

  factory SizeItem.fromJson(Map<String, dynamic> json) {
    return SizeItem(
      id: _toInt(json['id']),
      pointure: '${json['pointure'] ?? json['label'] ?? ''}',
    );
  }
}

class VariationItem {
  final int? id;
  final double prix;
  final int quantiteStock;
  final int? couleurId;
  final String couleurNom;
  final String couleurCodeHex;
  final int? tailleId;
  final String taillePointure;
  final List<String> imageUrls;
  final String model3dUrl;
  final String model3dName;
  final String model3dType;

  VariationItem({
    this.id,
    required this.prix,
    required this.quantiteStock,
    required this.couleurId,
    required this.couleurNom,
    required this.couleurCodeHex,
    required this.tailleId,
    required this.taillePointure,
    required this.imageUrls,
    required this.model3dUrl,
    required this.model3dName,
    required this.model3dType,
  });

  factory VariationItem.empty() {
    return VariationItem(
      id: null,
      prix: 0,
      quantiteStock: 0,
      couleurId: null,
      couleurNom: '',
      couleurCodeHex: '',
      tailleId: null,
      taillePointure: '',
      imageUrls: const [],
      model3dUrl: '',
      model3dName: '',
      model3dType: '',
    );
  }

  factory VariationItem.fromJson(Map<String, dynamic> json) {
    return VariationItem(
      id: _toInt(json['id']),
      prix: _toDouble(json['prix']) ?? 0,
      quantiteStock: _toInt(json['quantiteStock']) ?? 0,
      couleurId: _toInt(json['couleurId']),
      couleurNom: '${json['couleurNom'] ?? ''}',
      couleurCodeHex: '${json['couleurCodeHex'] ?? ''}',
      tailleId: _toInt(json['tailleId']),
      taillePointure: '${json['taillePointure'] ?? ''}',
      imageUrls: _getVariationImageUrls(json),
      model3dUrl: '${json['model3dUrl'] ?? ''}',
      model3dName: '${json['model3dName'] ?? ''}',
      model3dType: '${json['model3dType'] ?? ''}',
    );
  }

  VariationItem merge(VariationItem other) {
    return VariationItem(
      id: id ?? other.id,
      prix: prix != 0 ? prix : other.prix,
      quantiteStock: quantiteStock != 0 ? quantiteStock : other.quantiteStock,
      couleurId: couleurId ?? other.couleurId,
      couleurNom: couleurNom.isNotEmpty ? couleurNom : other.couleurNom,
      couleurCodeHex:
      couleurCodeHex.isNotEmpty ? couleurCodeHex : other.couleurCodeHex,
      tailleId: tailleId ?? other.tailleId,
      taillePointure:
      taillePointure.isNotEmpty ? taillePointure : other.taillePointure,
      imageUrls: imageUrls.isNotEmpty ? imageUrls : other.imageUrls,
      model3dUrl: model3dUrl.isNotEmpty ? model3dUrl : other.model3dUrl,
      model3dName: model3dName.isNotEmpty ? model3dName : other.model3dName,
      model3dType: model3dType.isNotEmpty ? model3dType : other.model3dType,
    );
  }
}

class VariationGroup {
  final String key;
  final int? couleurId;
  final String couleurNom;
  final String couleurCodeHex;
  final double prix;
  int quantiteStock;
  List<String> imageUrls;
  String model3dUrl;
  String model3dName;
  String model3dType;
  final List<VariationItem> items;

  VariationGroup({
    required this.key,
    required this.couleurId,
    required this.couleurNom,
    required this.couleurCodeHex,
    required this.prix,
    required this.quantiteStock,
    required this.imageUrls,
    required this.model3dUrl,
    required this.model3dName,
    required this.model3dType,
    required this.items,
  });
}

class HistoryRow {
  final int? id;
  final String action;
  final String actionLabel;
  final String targetType;
  final String articleName;
  final String variationLabel;
  final String summary;
  final String actorName;
  final String actorEmail;
  final int? actorUserId;
  final DateTime? actionAt;

  HistoryRow({
    this.id,
    required this.action,
    required this.actionLabel,
    required this.targetType,
    required this.articleName,
    required this.variationLabel,
    required this.summary,
    required this.actorName,
    required this.actorEmail,
    required this.actorUserId,
    required this.actionAt,
  });

  factory HistoryRow.fromJson(Map<String, dynamic> json) {
    return HistoryRow(
      id: _toInt(json['id']),
      action: '${json['action'] ?? ''}',
      actionLabel: '${json['actionLabel'] ?? json['action'] ?? ''}',
      targetType: '${json['targetType'] ?? ''}',
      articleName: '${json['articleName'] ?? ''}',
      variationLabel: '${json['variationLabel'] ?? ''}',
      summary: '${json['summary'] ?? ''}',
      actorName: '${json['actorName'] ?? json['actorFullName'] ?? ''}',
      actorEmail: '${json['actorEmail'] ?? ''}',
      actorUserId: _toInt(json['actorUserId']),
      actionAt: _toDate(json['actionAt']),
    );
  }
}

class ArticleFormData {
  String nom;
  String description;
  String details;
  String prix;
  bool actif;
  int? categorieId;
  String marque;
  String matiere;
  String sku;
  String salePrice;
  String saleStartAt;
  String saleEndAt;
  bool recommended;

  ArticleFormData({
    required this.nom,
    required this.description,
    required this.details,
    required this.prix,
    required this.actif,
    required this.categorieId,
    required this.marque,
    required this.matiere,
    required this.sku,
    required this.salePrice,
    required this.saleStartAt,
    required this.saleEndAt,
    required this.recommended,
  });

  factory ArticleFormData.empty() {
    return ArticleFormData(
      nom: '',
      description: '',
      details: '',
      prix: '',
      actif: true,
      categorieId: null,
      marque: '',
      matiere: '',
      sku: '',
      salePrice: '',
      saleStartAt: '',
      saleEndAt: '',
      recommended: false,
    );
  }

  factory ArticleFormData.fromArticle(Article article) {
    return ArticleFormData(
      nom: article.nom,
      description: article.description,
      details: article.details,
      prix: article.prix.toString(),
      actif: article.actif,
      categorieId: article.categorieId,
      marque: article.marque,
      matiere: article.matiere,
      sku: article.sku,
      salePrice: article.salePrice?.toString() ?? '',
      saleStartAt: _toInputDateTime(article.saleStartAt),
      saleEndAt: _toInputDateTime(article.saleEndAt),
      recommended: article.recommended,
    );
  }
}

class CategoryFormData {
  String nom;
  String description;
  int? parentId;
  String mainCategory;
  int displayOrder;
  String iconUrl;
  bool actif;

  CategoryFormData({
    required this.nom,
    required this.description,
    required this.parentId,
    required this.mainCategory,
    required this.displayOrder,
    required this.iconUrl,
    required this.actif,
  });

  factory CategoryFormData.empty() {
    return CategoryFormData(
      nom: '',
      description: '',
      parentId: null,
      mainCategory: '',
      displayOrder: 0,
      iconUrl: '',
      actif: true,
    );
  }

  factory CategoryFormData.fromCategory(CategoryItem item) {
    return CategoryFormData(
      nom: item.nom,
      description: item.description,
      parentId: item.parentId,
      mainCategory: item.mainCategory,
      displayOrder: item.displayOrder,
      iconUrl: item.iconUrl,
      actif: item.actif,
    );
  }
}

class ColorFormData {
  String nom;
  String codeHex;

  ColorFormData({
    required this.nom,
    required this.codeHex,
  });

  factory ColorFormData.empty() {
    return ColorFormData(nom: '', codeHex: '#000000');
  }

  factory ColorFormData.fromColor(ColorItem item) {
    return ColorFormData(
      nom: item.nom,
      codeHex: item.codeHex,
    );
  }
}

class SizeFormData {
  String pointure;

  SizeFormData({
    required this.pointure,
  });

  factory SizeFormData.empty() {
    return SizeFormData(pointure: '');
  }

  factory SizeFormData.fromSize(SizeItem item) {
    return SizeFormData(pointure: item.pointure);
  }
}

class VariationSizeStockRow {
  int? variationId;
  int? tailleId;
  String label;
  bool checked;
  String quantiteStock;
  bool disabled;
  String prix;

  VariationSizeStockRow({
    required this.variationId,
    required this.tailleId,
    required this.label,
    required this.checked,
    required this.quantiteStock,
    required this.disabled,
    required this.prix,
  });
}

class VariationFormData {
  String couleurId;
  String prix;
  String quantiteStock;
  List<VariationSizeStockRow> sizeStocks;
  List<PlatformFile> imageFiles;
  List<String> existingImageUrls;
  PlatformFile? model3dFile;
  String existingModel3dUrl;
  String existingModel3dName;
  String existingModel3dType;

  VariationFormData({
    required this.couleurId,
    required this.prix,
    required this.quantiteStock,
    required this.sizeStocks,
    required this.imageFiles,
    required this.existingImageUrls,
    required this.model3dFile,
    required this.existingModel3dUrl,
    required this.existingModel3dName,
    required this.existingModel3dType,
  });

  factory VariationFormData.create({
    required double articlePrice,
    required String initialColorId,
    required List<SizeItem> sizes,
    required List<VariationItem> variations,
    required bool isAccessory,
  }) {
    return VariationFormData(
      couleurId: initialColorId,
      prix: articlePrice.toString(),
      quantiteStock: '0',
      sizeStocks: isAccessory
          ? []
          : sizes.map((s) {
        final alreadyExists = variations.any(
              (v) =>
          v.couleurId?.toString() == initialColorId &&
              v.tailleId == s.id,
        );
        return VariationSizeStockRow(
          variationId: null,
          tailleId: s.id,
          label: s.pointure,
          checked: false,
          quantiteStock: '0',
          disabled: alreadyExists,
          prix: articlePrice.toString(),
        );
      }).toList(),
      imageFiles: [],
      existingImageUrls: [],
      model3dFile: null,
      existingModel3dUrl: '',
      existingModel3dName: '',
      existingModel3dType: '',
    );
  }

  void rebuildSizeStocks(List<SizeItem> sizes, List<VariationItem> variations) {
    sizeStocks = sizes.map((s) {
      final old = sizeStocks.firstWhereOrNull((e) => e.tailleId == s.id);
      final alreadyExists = variations.any(
            (v) => v.couleurId?.toString() == couleurId && v.tailleId == s.id,
      );
      return VariationSizeStockRow(
        variationId: old?.variationId,
        tailleId: s.id,
        label: s.pointure,
        checked: alreadyExists ? false : (old?.checked ?? false),
        quantiteStock: old?.quantiteStock ?? '0',
        disabled: alreadyExists,
        prix: old?.prix ?? prix,
      );
    }).toList();
  }
}

class VariationGroupFormData {
  String couleurId;
  String groupColorName;
  String prix;
  List<VariationSizeStockRow> rows;
  List<PlatformFile> imageFiles;
  List<String> existingImageUrls;
  PlatformFile? model3dFile;
  String existingModel3dUrl;
  String existingModel3dName;
  String existingModel3dType;

  VariationGroupFormData({
    required this.couleurId,
    required this.groupColorName,
    required this.prix,
    required this.rows,
    required this.imageFiles,
    required this.existingImageUrls,
    required this.model3dFile,
    required this.existingModel3dUrl,
    required this.existingModel3dName,
    required this.existingModel3dType,
  });

  factory VariationGroupFormData.fromGroup({
    required VariationGroup group,
    required List<SizeItem> sizes,
    required double selectedArticlePrice,
    required bool isAccessory,
  }) {
    if (isAccessory) {
      final item = group.items.firstOrNull;
      return VariationGroupFormData(
        couleurId: group.couleurId?.toString() ?? '',
        groupColorName: group.couleurNom,
        prix: group.prix.toString(),
        rows: [
          VariationSizeStockRow(
            variationId: item?.id,
            tailleId: item?.tailleId,
            label: item?.taillePointure ?? 'Stock only',
            checked: true,
            quantiteStock: (item?.quantiteStock ?? 0).toString(),
            disabled: false,
            prix: (item?.prix ?? group.prix).toString(),
          ),
        ],
        imageFiles: [],
        existingImageUrls: List<String>.from(group.imageUrls),
        model3dFile: null,
        existingModel3dUrl: group.model3dUrl,
        existingModel3dName: group.model3dName,
        existingModel3dType: group.model3dType,
      );
    }

    final rows = sizes.map((size) {
      final existing = group.items.firstWhereOrNull((v) => v.tailleId == size.id);
      return VariationSizeStockRow(
        variationId: existing?.id,
        tailleId: size.id,
        label: size.pointure,
        checked: existing != null,
        quantiteStock: existing?.quantiteStock.toString() ?? '0',
        disabled: false,
        prix: existing?.prix.toString() ?? group.prix.toString(),
      );
    }).toList();

    return VariationGroupFormData(
      couleurId: group.couleurId?.toString() ?? '',
      groupColorName: group.couleurNom,
      prix: group.prix.toString(),
      rows: rows,
      imageFiles: [],
      existingImageUrls: List<String>.from(group.imageUrls),
      model3dFile: null,
      existingModel3dUrl: group.model3dUrl,
      existingModel3dName: group.model3dName,
      existingModel3dType: group.model3dType,
    );
  }
}

class StockFormData {
  String variationId;
  String label;
  int currentStock;
  String quantity;
  String mode;

  StockFormData({
    required this.variationId,
    required this.label,
    required this.currentStock,
    required this.quantity,
    required this.mode,
  });
}

class HistoryFilterData {
  String action;
  String targetType;
  String searchTerm;
  DateTime? dateFrom;
  DateTime? dateTo;

  HistoryFilterData({
    this.action = '',
    this.targetType = '',
    this.searchTerm = '',
    this.dateFrom,
    this.dateTo,
  });
}

extension NullableStringX on String {
  String ifEmpty(String fallback) => trim().isEmpty ? fallback : this;
}

extension IterableX<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;

  T? firstWhereOrNull(bool Function(T element) test) {
    for (final item in this) {
      if (test(item)) return item;
    }
    return null;
  }
}

int? _toInt(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is double) return value.toInt();
  return int.tryParse(value.toString());
}

double? _toDouble(dynamic value) {
  if (value == null) return null;
  if (value is double) return value;
  if (value is int) return value.toDouble();
  return double.tryParse(value.toString());
}

bool _toBool(dynamic value) {
  if (value == null) return false;
  if (value is bool) return value;
  final s = value.toString().toLowerCase().trim();
  return s == 'true' || s == '1' || s == 'yes';
}

DateTime? _toDate(dynamic value) {
  if (value == null) return null;
  if (value is DateTime) return value;
  return DateTime.tryParse(value.toString());
}

String _toInputDateTime(DateTime? dt) {
  if (dt == null) return '';
  String two(int n) => n.toString().padLeft(2, '0');
  return '${dt.year}-${two(dt.month)}-${two(dt.day)}T${two(dt.hour)}:${two(dt.minute)}';
}

String _normalizeVariationImageUrl(dynamic item) {
  if (item == null) return '';
  if (item is String) return item.trim();
  if (item is Map) {
    final keys = [
      'url',
      'imageUrl',
      'path',
      'fileUrl',
      'downloadUrl',
      'contentUrl',
      'src',
      'href',
      'publicUrl',
      'filename',
      'fileName',
    ];
    for (final key in keys) {
      final value = item[key];
      if (value != null && value.toString().trim().isNotEmpty) {
        return value.toString().trim();
      }
    }
  }
  return '';
}

List<String> _getVariationImageUrls(Map<String, dynamic> source) {
  final urls = <String>{};
  final variationId = _toInt(source['id']);

  void pushValue(dynamic value) {
    final normalized = _normalizeVariationImageUrl(value);
    if (normalized.isNotEmpty) {
      urls.add(normalized);
    }
  }

  final listCandidates = [
    source['images'],
    source['imageUrls'],
    source['existingImageUrls'],
    source['files'],
  ];

  for (final candidate in listCandidates) {
    if (candidate is List) {
      for (final item in candidate) {
        pushValue(item);
      }
    }
  }

  if (source['imageIds'] is List && variationId != null) {
    for (final id in (source['imageIds'] as List)) {
      if (id != null) {
        urls.add('/api/catalog/variations/$variationId/images/$id');
      }
    }
  }

  final singleCandidates = [
    source['image'],
    source['image1'],
    source['image2'],
    source['image3'],
    source['image4'],
    source['imageUrl'],
    source['imageUrl1'],
    source['imageUrl2'],
    source['imageUrl3'],
    source['imageUrl4'],
    source['existingImage1'],
    source['existingImage2'],
    source['existingImage3'],
    source['existingImage4'],
    source['previewImage'],
    source['thumbnail'],
    source['fileName'],
    source['filename'],
  ];

  for (final value in singleCandidates) {
    pushValue(value);
  }

  if (source['imageId'] != null && variationId != null) {
    urls.add('/api/catalog/variations/$variationId/images/${source['imageId']}');
  }

  return urls.where((e) => e.trim().isNotEmpty).toList();
}