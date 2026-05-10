import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/models/article_model.dart';
import '../../core/models/category_model.dart';
import '../../core/models/color_model.dart';
import '../../core/models/size_model.dart';
import '../../core/models/variation_model.dart';
import '../../core/models/history_entry_model.dart';
import '../../core/services/admin_catalog_service.dart';
import '../../widgets/article_card.dart';
import '../../widgets/article_form_dialog.dart';
import '../../widgets/variation_group_card.dart';
import '../../widgets/category_dialog.dart';
import '../../widgets/color_dialog.dart';
import '../../widgets/size_dialog.dart';
import '../../widgets/pagination_widget.dart';
import '../../widgets/variation_form_dialog.dart';
import '../../widgets/stock_update_dialog.dart';
import '../../../providers/auth_provider.dart';

class AdminCatalogPage extends StatefulWidget {
  const AdminCatalogPage({super.key});

  @override
  State<AdminCatalogPage> createState() => _AdminCatalogPageState();
}

class _AdminCatalogPageState extends State<AdminCatalogPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Data
  List<ArticleModel> _articles = [];
  List<CategoryModel> _allCategories = [];
  List<ColorModel> _colors = [];
  List<SizeModel> _sizes = [];
  ArticleModel? _selectedArticle;
  List<VariationModel> _variations = [];

  // UI State
  bool _isLoading = true;
  String _error = '';
  String _searchQuery = '';
  int? _selectedCategoryFilter;

  // Pagination
  int _articlePage = 1;
  int _articleRows = 5;
  int _variationPage = 1;
  int _variationRows = 3;
  int _categoryPage = 1;
  int _categoryRows = 3;
  int _colorPage = 1;
  int _colorRows = 3;
  int _sizePage = 1;
  int _sizeRows = 3;

  // Global history filters
  String _historyAction = '';
  String _historyTargetType = '';
  String _historySearchTerm = '';
  DateTime? _historyDateFrom;
  DateTime? _historyDateTo;
  List<HistoryEntryModel> _globalHistory = [];
  bool _globalHistoryLoading = false;

  // Role flags (will be set in didChangeDependencies)
  late bool _isAdminGeneral;
  late bool _isCatalogManager;
  late bool _isEcommerceManager;

  bool get _canEditCatalog => _isAdminGeneral || _isCatalogManager || _isEcommerceManager;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _loadData();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final auth = Provider.of<AuthProvider>(context);
    _isAdminGeneral = auth.isSuperAdmin;
    _isCatalogManager = auth.isCatalogManager;
    _isEcommerceManager = auth.isEcommerceManager;
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final articles = await AdminCatalogService.fetchArticles();
      final categories = await AdminCatalogService.fetchAllCategories();
      final colors = await AdminCatalogService.fetchColors();
      final sizes = await AdminCatalogService.fetchSizes();
      setState(() {
        _articles = articles;
        _allCategories = categories;
        _colors = colors;
        _sizes = sizes;
        _isLoading = false;
      });
      if (articles.isNotEmpty && _selectedArticle == null) {
        await _selectArticle(articles.first);
      }
      await _loadGlobalHistory();
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _loadGlobalHistory() async {
    setState(() => _globalHistoryLoading = true);
    try {
      final entries = await AdminCatalogService.fetchGlobalHistory(
        action: _historyAction.isEmpty ? null : _historyAction,
        targetType: _historyTargetType.isEmpty ? null : _historyTargetType,
        searchTerm: _historySearchTerm.isEmpty ? null : _historySearchTerm,
        dateFrom: _historyDateFrom,
        dateTo: _historyDateTo,
        limit: 500,
      );
      setState(() => _globalHistory = entries);
    } catch (e) {
      // ignore
    } finally {
      setState(() => _globalHistoryLoading = false);
    }
  }

  Future<void> _selectArticle(ArticleModel article) async {
    setState(() => _isLoading = true);
    try {
      final variations = await AdminCatalogService.fetchVariations(article.id);
      setState(() {
        _selectedArticle = article;
        _variations = variations;
        _variationPage = 1;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  List<ArticleModel> get _filteredArticles {
    var filtered = _articles;
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      filtered = filtered.where((a) =>
      a.nom.toLowerCase().contains(q) ||
          a.description.toLowerCase().contains(q) ||
          a.categorieNom.toLowerCase().contains(q) ||
          a.marque.toLowerCase().contains(q) ||
          a.sku.toLowerCase().contains(q)).toList();
    }
    if (_selectedCategoryFilter != null) {
      final categoryIds = _getDescendantCategoryIds(_selectedCategoryFilter!);
      filtered = filtered.where((a) => categoryIds.contains(a.categorieId)).toList();
    }
    return filtered;
  }

  Set<int> _getDescendantCategoryIds(int parentId) {
    final ids = <int>{parentId};
    final children = _allCategories.where((c) => c.parentId == parentId);
    for (final child in children) {
      ids.addAll(_getDescendantCategoryIds(child.id));
    }
    return ids;
  }

  List<CategoryModel> get _mainCategories => _allCategories.where((c) => c.parentId == null).toList();

  String getCategoryFullPath(int categoryId) {
    final cat = _allCategories.firstWhere(
          (c) => c.id == categoryId,
      orElse: () => CategoryModel(id: 0, nom: '-', level: 0, displayOrder: 0, actif: true),
    );
    if (cat.id == 0) return '-';
    if (cat.parentId != null) {
      final parent = _allCategories.firstWhere((c) => c.id == cat.parentId, orElse: () => CategoryModel(id: 0, nom: '', level: 0, displayOrder: 0, actif: true));
      if (parent.parentId != null) {
        final grandParent = _allCategories.firstWhere((c) => c.id == parent.parentId, orElse: () => CategoryModel(id: 0, nom: '', level: 0, displayOrder: 0, actif: true));
        return '${grandParent.nom} > ${parent.nom} > ${cat.nom}';
      } else if (parent.id != 0) {
        return '${parent.nom} > ${cat.nom}';
      }
    }
    return cat.nom;
  }

  bool _isAccessoryCategory() {
    if (_selectedArticle == null) return false;
    final normalized = _selectedArticle!.categorieNom.trim().toLowerCase();
    return normalized == 'sac a main' || normalized == 'sac à main' || normalized == 'pochette de soirée';
  }

  List<Map<String, dynamic>> get _groupedVariations {
    final Map<int, Map<String, dynamic>> groups = {};
    for (final v in _variations) {
      final key = v.couleurId;
      if (!groups.containsKey(key)) {
        groups[key] = {
          'couleurId': v.couleurId,
          'couleurNom': v.couleurNom,
          'couleurCodeHex': v.couleurCodeHex,
          'prix': v.prix,
          'items': <VariationModel>[],
          'totalStock': 0,
          'imageUrls': List<String>.from(v.imageUrls),
          'model3dUrl': v.model3dUrl,
        };
      }
      final group = groups[key]!;
      (group['items'] as List<VariationModel>).add(v);
      group['totalStock'] = (group['totalStock'] as int) + v.quantiteStock;
      if (group['imageUrls'].isEmpty && v.imageUrls.isNotEmpty) {
        group['imageUrls'] = List.from(v.imageUrls);
      }
      if (group['model3dUrl'] == null && v.model3dUrl != null) {
        group['model3dUrl'] = v.model3dUrl;
      }
    }
    return groups.values.toList();
  }

  List<Map<String, dynamic>> get _pagedGroupedVariations {
    final groups = _groupedVariations;
    final start = (_variationPage - 1) * _variationRows;
    final end = start + _variationRows;
    if (start >= groups.length) return [];
    return groups.sublist(start, end > groups.length ? groups.length : end);
  }

  void _openCreateArticleDialog() {
    print("➕ Opening Add Article dialog");
    showDialog(
      context: context,
      builder: (_) => ArticleFormDialog(
        categories: _allCategories,
        mainCategories: _mainCategories,
        onSubmit: (data, images) async {
          print("📦 Article data received: $data");
          try {
            // Always create a new article (this is the "Add" dialog)
            await AdminCatalogService.createArticle(
              nom: data['nom']!,
              description: data['description']!,
              details: data['details']!,
              prix: data['prix']!,
              salePrice: data['salePrice'],
              saleStartAt: data['saleStartAt'],
              saleEndAt: data['saleEndAt'],
              actif: data['actif']!,
              recommended: data['recommended']!,
              categorieId: data['categorieId']!,
              marque: data['marque']!,
              matiere: data['matiere']!,
              sku: data['sku']!,
              images: images,
            );
            print("✅ Article created successfully");
            await _loadData();
            if (mounted) Navigator.pop(context);
          } catch (e) {
            print("❌ Error saving article: $e");
            if (mounted) ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Error: $e')),
            );
          }
        },
      ),
    );
  }

  void _openEditArticleDialog(ArticleModel article) {
    showDialog(
      context: context,
      builder: (_) => ArticleFormDialog(
        initialArticle: article,
        categories: _allCategories,
        mainCategories: _mainCategories,
        onSubmit: (data, images) async {
          try {
            await AdminCatalogService.updateArticle(
              article.id,
              nom: data['nom']!,
              description: data['description']!,
              details: data['details']!,
              prix: data['prix']!,
              salePrice: data['salePrice'],
              saleStartAt: data['saleStartAt'],
              saleEndAt: data['saleEndAt'],
              actif: data['actif']!,
              recommended: data['recommended']!,
              categorieId: data['categorieId']!,
              marque: data['marque']!,
              matiere: data['matiere']!,
              sku: data['sku']!,
              images: images,
            );
            await _loadData();
            if (mounted) Navigator.pop(context);
          } catch (e) {
            if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
          }
        },
      ),
    );
  }

  void _openCreateVariationDialog() {
    if (_selectedArticle == null) return;
    if (_colors.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Create at least one color first')));
      return;
    }
    if (!_isAccessoryCategory() && _sizes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Create at least one size first')));
      return;
    }
    showDialog(
      context: context,
      builder: (_) => VariationFormDialog(
        articleId: _selectedArticle!.id,
        isAccessory: _isAccessoryCategory(),
        colors: _colors,
        sizes: _sizes,
        onSubmit: () async {
          await _selectArticle(_selectedArticle!);
          if (mounted) Navigator.pop(context);
        },
      ),
    );
  }

  void _openEditVariationDialog(VariationModel variation) {
    showDialog(
      context: context,
      builder: (_) => VariationFormDialog(
        articleId: _selectedArticle!.id,
        initialVariation: variation,
        isAccessory: _isAccessoryCategory(),
        colors: _colors,
        sizes: _sizes,
        onSubmit: () async {
          await _selectArticle(_selectedArticle!);
          if (mounted) Navigator.pop(context);
        },
      ),
    );
  }

  void _openEditVariationGroupDialog(Map<String, dynamic> group) {
    showDialog(
      context: context,
      builder: (_) => VariationGroupEditDialog(
        articleId: _selectedArticle!.id,
        group: group,
        isAccessory: _isAccessoryCategory(),
        colors: _colors,
        sizes: _sizes,
        onSubmit: () async {
          await _selectArticle(_selectedArticle!);
          if (mounted) Navigator.pop(context);
        },
      ),
    );
  }

  void _openStockDialog(VariationModel variation, {required bool increment}) {
    showDialog(
      context: context,
      builder: (_) => StockUpdateDialog(
        variation: variation,
        increment: increment,
        onConfirm: (quantity) async {
          try {
            await AdminCatalogService.updateStock(variation.id, quantity, increment: increment);
            await _selectArticle(_selectedArticle!);
          } catch (e) {
            if (mounted) ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Failed to update stock: $e')),
            );
          }
        },
      ),
    );
  }

  Future<void> _deleteArticle(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete article'),
        content: const Text('Are you sure? This action cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      await AdminCatalogService.deleteArticle(id);
      await _loadData();
      if (_selectedArticle?.id == id) setState(() => _selectedArticle = null);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Delete failed: $e')));
    }
  }

  Future<void> _deleteVariation(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete variation'),
        content: const Text('Are you sure?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      await AdminCatalogService.deleteVariation(id);
      await _selectArticle(_selectedArticle!);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Delete failed: $e')));
    }
  }

  Future<void> _deleteVariationGroup(Map<String, dynamic> group) async {
    final items = group['items'] as List<VariationModel>;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete color group'),
        content: Text('Delete ${group['couleurNom']} and its ${items.length} variation(s)?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirm != true) return;
    setState(() => _isLoading = true);
    try {
      for (final v in items) {
        await AdminCatalogService.deleteVariation(v.id);
      }
      await _selectArticle(_selectedArticle!);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Delete failed: $e')));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _openCreateCategoryDialog() {
    showDialog(
      context: context,
      builder: (_) => CategoryDialog(
        categories: _allCategories,
        onSubmit: (data) async {
          try {
            await AdminCatalogService.createCategory(
              nom: data['nom']!,
              description: data['description'],
              parentId: data['parentId'],
              displayOrder: data['displayOrder'] ?? 0,
              iconUrl: data['iconUrl'],
              actif: data['actif'] ?? true,
            );
            await _loadData();
            if (mounted) Navigator.pop(context);
          } catch (e) {
            if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
          }
        },
      ),
    );
  }

  void _openEditCategoryDialog(CategoryModel category) {
    showDialog(
      context: context,
      builder: (_) => CategoryDialog(
        initialCategory: category,
        categories: _allCategories,
        onSubmit: (data) async {
          try {
            await AdminCatalogService.updateCategory(
              category.id,
              nom: data['nom']!,
              description: data['description'],
              parentId: data['parentId'],
              displayOrder: data['displayOrder'] ?? 0,
              iconUrl: data['iconUrl'],
              actif: data['actif'] ?? true,
            );
            await _loadData();
            if (mounted) Navigator.pop(context);
          } catch (e) {
            if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
          }
        },
      ),
    );
  }

  Future<void> _deleteCategory(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete category'),
        content: const Text('Are you sure?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      await AdminCatalogService.deleteCategory(id);
      await _loadData();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Delete failed: $e')));
    }
  }

  void _openCreateColorDialog() {
    showDialog(
      context: context,
      builder: (_) => ColorDialog(
        onSubmit: (nom, codeHex) async {
          try {
            await AdminCatalogService.createColor(nom, codeHex);
            await _loadData();
            if (mounted) Navigator.pop(context);
          } catch (e) {
            if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
          }
        },
      ),
    );
  }

  void _openEditColorDialog(ColorModel color) {
    showDialog(
      context: context,
      builder: (_) => ColorDialog(
        initialColor: color,
        onSubmit: (nom, codeHex) async {
          try {
            await AdminCatalogService.updateColor(color.id, nom, codeHex);
            await _loadData();
            if (mounted) Navigator.pop(context);
          } catch (e) {
            if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
          }
        },
      ),
    );
  }

  Future<void> _deleteColor(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete color'),
        content: const Text('Are you sure?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      await AdminCatalogService.deleteColor(id);
      await _loadData();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Delete failed: $e')));
    }
  }

  void _openCreateSizeDialog() {
    showDialog(
      context: context,
      builder: (_) => SizeDialog(
        onSubmit: (pointure) async {
          try {
            await AdminCatalogService.createSize(pointure);
            await _loadData();
            if (mounted) Navigator.pop(context);
          } catch (e) {
            if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
          }
        },
      ),
    );
  }

  void _openEditSizeDialog(SizeModel size) {
    showDialog(
      context: context,
      builder: (_) => SizeDialog(
        initialSize: size,
        onSubmit: (pointure) async {
          try {
            await AdminCatalogService.updateSize(size.id, pointure);
            await _loadData();
            if (mounted) Navigator.pop(context);
          } catch (e) {
            if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
          }
        },
      ),
    );
  }

  Future<void> _deleteSize(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete size'),
        content: const Text('Are you sure?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      await AdminCatalogService.deleteSize(id);
      await _loadData();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Delete failed: $e')));
    }
  }

  // ---------- Build Methods ----------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Catalog Management'),
        backgroundColor: AppColors.surface,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.accent,
          unselectedLabelColor: AppColors.textSecondary,
          tabs: const [
            Tab(text: 'Articles'),
            Tab(text: 'Categories'),
            Tab(text: 'Colors'),
            Tab(text: 'Sizes'),
            Tab(text: 'History'),
          ],
        ),
        actions: [
          if (_canEditCatalog)
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: _openCreateArticleDialog,
              tooltip: 'Add article',
            ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _loadData(),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.accent))
          : _error.isNotEmpty
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: AppColors.error),
            const SizedBox(height: 16),
            Text(_error, style: const TextStyle(color: AppColors.error)),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: _loadData, child: const Text('Retry')),
          ],
        ),
      )
          : TabBarView(
        controller: _tabController,
        children: [
          _buildArticlesTab(),
          _buildCategoriesTab(),
          _buildColorsTab(),
          _buildSizesTab(),
          _buildHistoryTab(),
        ],
      ),
    );
  }

  Widget _buildArticlesTab() {
    final filtered = _filteredArticles;
    final start = (_articlePage - 1) * _articleRows;
    final pagedArticles = filtered.sublist(
      start,
      start + _articleRows > filtered.length ? filtered.length : start + _articleRows,
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Search & Filter
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Search articles...',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      filled: true,
                      fillColor: AppColors.surface,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    onChanged: (value) {
                      setState(() => _searchQuery = value);
                      _articlePage = 1;
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.border),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<int?>(
                      hint: const Text('All categories'),
                      value: _selectedCategoryFilter,
                      items: [
                        const DropdownMenuItem<int?>(value: null, child: Text('All categories')),
                        ..._mainCategories.map<DropdownMenuItem<int?>>((c) => DropdownMenuItem<int?>(
                          value: c.id,
                          child: Text(c.nom),
                        )),
                      ],
                      onChanged: (value) {
                        setState(() => _selectedCategoryFilter = value);
                        _articlePage = 1;
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Articles list
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: pagedArticles.length,
            itemBuilder: (_, i) {
              final article = pagedArticles[i];
              return ArticleCard(
                article: article,
                isSelected: _selectedArticle?.id == article.id,
                onTap: () => _selectArticle(article),
                onEdit: _canEditCatalog ? () => _openEditArticleDialog(article) : null,
                onDelete: _isAdminGeneral ? () => _deleteArticle(article.id) : null,
                categoryPath: getCategoryFullPath(article.categorieId),
              );
            },
          ),
          if (filtered.length > _articleRows)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: PaginationWidget(
                total: filtered.length,
                page: _articlePage,
                rowsPerPage: _articleRows,
                onPageChanged: (page) => setState(() => _articlePage = page),
                onRowsPerPageChanged: (rows) {
                  setState(() {
                    _articleRows = rows;
                    _articlePage = 1;
                  });
                },
              ),
            ),
          // Variations section
          if (_selectedArticle != null) ...[
            const Divider(height: 32, thickness: 1),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Text('Variations', style: Theme.of(context).textTheme.titleLarge),
                  const Spacer(),
                  if (_canEditCatalog)
                    ElevatedButton.icon(
                      icon: const Icon(Icons.add),
                      label: const Text('Add variation'),
                      onPressed: _openCreateVariationDialog,
                    ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            if (_variations.isEmpty)
              const Padding(
                padding: EdgeInsets.all(16),
                child: Center(child: Text('No variations for this article')),
              )
            else ...[
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _pagedGroupedVariations.length,
                itemBuilder: (_, i) {
                  final group = _pagedGroupedVariations[i];
                  return VariationGroupCard(
                    group: group,
                    isAccessory: _isAccessoryCategory(),
                    canEdit: _canEditCatalog,
                    onEditGroup: () => _openEditVariationGroupDialog(group),
                    onEditVariation: (v) => _openEditVariationDialog(v),
                    onDeleteGroup: _isAdminGeneral ? () => _deleteVariationGroup(group) : null,
                    onDeleteVariation: _isAdminGeneral ? (v) => _deleteVariation(v.id) : null,
                    onRestock: (v) => _openStockDialog(v, increment: true),
                    onSell: (v) => _openStockDialog(v, increment: false),
                  );
                },
              ),
              if (_groupedVariations.length > _variationRows)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: PaginationWidget(
                    total: _groupedVariations.length,
                    page: _variationPage,
                    rowsPerPage: _variationRows,
                    onPageChanged: (page) => setState(() => _variationPage = page),
                    onRowsPerPageChanged: (rows) {
                      setState(() {
                        _variationRows = rows;
                        _variationPage = 1;
                      });
                    },
                  ),
                ),
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildCategoriesTab() {
    final start = (_categoryPage - 1) * _categoryRows;
    final paged = _allCategories.sublist(
      start,
      start + _categoryRows > _allCategories.length ? _allCategories.length : start + _categoryRows,
    );
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_isAdminGeneral)
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.add),
                label: const Text('Add Category'),
                onPressed: _openCreateCategoryDialog,
              ),
            ),
          const SizedBox(height: 12),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: paged.length,
            itemBuilder: (_, i) {
              final cat = paged[i];
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: AppColors.accent.withOpacity(0.1),
                    child: Icon(Icons.folder, color: AppColors.accent),
                  ),
                  title: Text(cat.nom),
                  subtitle: Text(getCategoryFullPath(cat.id)),
                  trailing: _isAdminGeneral
                      ? Row(mainAxisSize: MainAxisSize.min, children: [
                    IconButton(
                      icon: const Icon(Icons.edit, size: 20),
                      onPressed: () => _openEditCategoryDialog(cat),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, size: 20, color: AppColors.error),
                      onPressed: () => _deleteCategory(cat.id),
                    ),
                  ])
                      : null,
                ),
              );
            },
          ),
          if (_allCategories.length > _categoryRows)
            PaginationWidget(
              total: _allCategories.length,
              page: _categoryPage,
              rowsPerPage: _categoryRows,
              onPageChanged: (page) => setState(() => _categoryPage = page),
              onRowsPerPageChanged: (rows) {
                setState(() {
                  _categoryRows = rows;
                  _categoryPage = 1;
                });
              },
            ),
        ],
      ),
    );
  }

  Widget _buildColorsTab() {
    final start = (_colorPage - 1) * _colorRows;
    final paged = _colors.sublist(
      start,
      start + _colorRows > _colors.length ? _colors.length : start + _colorRows,
    );
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_isAdminGeneral)
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.add),
                label: const Text('Add Color'),
                onPressed: _openCreateColorDialog,
              ),
            ),
          const SizedBox(height: 12),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: paged.length,
            itemBuilder: (_, i) {
              final color = paged[i];
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Color(int.parse(color.codeHex.substring(1), radix: 16) + 0xFF000000),
                  ),
                  title: Text(color.nom),
                  subtitle: Text(color.codeHex),
                  trailing: _isAdminGeneral
                      ? Row(mainAxisSize: MainAxisSize.min, children: [
                    IconButton(
                      icon: const Icon(Icons.edit, size: 20),
                      onPressed: () => _openEditColorDialog(color),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, size: 20, color: AppColors.error),
                      onPressed: () => _deleteColor(color.id),
                    ),
                  ])
                      : null,
                ),
              );
            },
          ),
          if (_colors.length > _colorRows)
            PaginationWidget(
              total: _colors.length,
              page: _colorPage,
              rowsPerPage: _colorRows,
              onPageChanged: (page) => setState(() => _colorPage = page),
              onRowsPerPageChanged: (rows) {
                setState(() {
                  _colorRows = rows;
                  _colorPage = 1;
                });
              },
            ),
        ],
      ),
    );
  }

  Widget _buildSizesTab() {
    final start = (_sizePage - 1) * _sizeRows;
    final paged = _sizes.sublist(
      start,
      start + _sizeRows > _sizes.length ? _sizes.length : start + _sizeRows,
    );
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_isAdminGeneral)
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.add),
                label: const Text('Add Size'),
                onPressed: _openCreateSizeDialog,
              ),
            ),
          const SizedBox(height: 12),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: paged.length,
            itemBuilder: (_, i) {
              final size = paged[i];
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: AppColors.accent.withOpacity(0.1),
                    child: Text(size.pointure, style: const TextStyle(fontWeight: FontWeight.bold)),
                  ),
                  title: Text('Size ${size.pointure}'),
                  trailing: _isAdminGeneral
                      ? Row(mainAxisSize: MainAxisSize.min, children: [
                    IconButton(
                      icon: const Icon(Icons.edit, size: 20),
                      onPressed: () => _openEditSizeDialog(size),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, size: 20, color: AppColors.error),
                      onPressed: () => _deleteSize(size.id),
                    ),
                  ])
                      : null,
                ),
              );
            },
          ),
          if (_sizes.length > _sizeRows)
            PaginationWidget(
              total: _sizes.length,
              page: _sizePage,
              rowsPerPage: _sizeRows,
              onPageChanged: (page) => setState(() => _sizePage = page),
              onRowsPerPageChanged: (rows) {
                setState(() {
                  _sizeRows = rows;
                  _sizePage = 1;
                });
              },
            ),
        ],
      ),
    );
  }

  Widget _buildHistoryTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Global Catalog History', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text('Track all create, update, and delete actions across the entire catalog',
              style: TextStyle(color: AppColors.textSecondary)),
          const SizedBox(height: 16),
          // Filters
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              SizedBox(
                width: 150,
                child: DropdownButtonFormField<String>(
                  value: _historyAction.isEmpty ? null : _historyAction,
                  hint: const Text('All Actions'),
                  items: const [
                    DropdownMenuItem(value: 'CREATE', child: Text('Created')),
                    DropdownMenuItem(value: 'UPDATE', child: Text('Edited')),
                    DropdownMenuItem(value: 'DELETE', child: Text('Deleted')),
                  ],
                  onChanged: (val) {
                    setState(() => _historyAction = val ?? '');
                    _loadGlobalHistory();
                  },
                ),
              ),
              SizedBox(
                width: 150,
                child: DropdownButtonFormField<String>(
                  value: _historyTargetType.isEmpty ? null : _historyTargetType,
                  hint: const Text('All Types'),
                  items: const [
                    DropdownMenuItem(value: 'ARTICLE', child: Text('Articles')),
                    DropdownMenuItem(value: 'VARIATION', child: Text('Variations')),
                  ],
                  onChanged: (val) {
                    setState(() => _historyTargetType = val ?? '');
                    _loadGlobalHistory();
                  },
                ),
              ),
              SizedBox(
                width: 200,
                child: TextField(
                  decoration: const InputDecoration(
                    hintText: 'Search...',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  onChanged: (val) {
                    _historySearchTerm = val;
                    _loadGlobalHistory();
                  },
                ),
              ),
              SizedBox(
                width: 150,
                child: TextFormField(
                  decoration: const InputDecoration(
                    labelText: 'Date From',
                    border: OutlineInputBorder(),
                  ),
                  readOnly: true,
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now(),
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now(),
                    );
                    if (date != null) {
                      setState(() => _historyDateFrom = date);
                      _loadGlobalHistory();
                    }
                  },
                  controller: TextEditingController(
                    text: _historyDateFrom != null
                        ? '${_historyDateFrom!.day}/${_historyDateFrom!.month}/${_historyDateFrom!.year}'
                        : '',
                  ),
                ),
              ),
              SizedBox(
                width: 150,
                child: TextFormField(
                  decoration: const InputDecoration(
                    labelText: 'Date To',
                    border: OutlineInputBorder(),
                  ),
                  readOnly: true,
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now(),
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now(),
                    );
                    if (date != null) {
                      setState(() => _historyDateTo = date);
                      _loadGlobalHistory();
                    }
                  },
                  controller: TextEditingController(
                    text: _historyDateTo != null
                        ? '${_historyDateTo!.day}/${_historyDateTo!.month}/${_historyDateTo!.year}'
                        : '',
                  ),
                ),
              ),
              TextButton.icon(
                onPressed: () {
                  setState(() {
                    _historyAction = '';
                    _historyTargetType = '';
                    _historySearchTerm = '';
                    _historyDateFrom = null;
                    _historyDateTo = null;
                  });
                  _loadGlobalHistory();
                },
                icon: const Icon(Icons.clear),
                label: const Text('Reset filters'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Stats
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Wrap(
              spacing: 24,
              children: [
                _buildStatChip('Total', _globalHistory.length),
                _buildStatChip('Created', _globalHistory.where((e) => e.action == 'CREATE').length, color: AppColors.success),
                _buildStatChip('Edited', _globalHistory.where((e) => e.action == 'UPDATE').length, color: AppColors.warning),
                _buildStatChip('Deleted', _globalHistory.where((e) => e.action == 'DELETE').length, color: AppColors.error),
                _buildStatChip('Articles', _globalHistory.where((e) => e.targetType == 'ARTICLE').length),
                _buildStatChip('Variations', _globalHistory.where((e) => e.targetType == 'VARIATION').length),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // History list
          if (_globalHistoryLoading)
            const Center(child: CircularProgressIndicator())
          else if (_globalHistory.isEmpty)
            const Center(child: Text('No history records'))
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _globalHistory.length,
              itemBuilder: (_, i) {
                final entry = _globalHistory[i];
                return _buildHistoryCard(entry);
              },
            ),
        ],
      ),
    );
  }

  Widget _buildStatChip(String label, int value, {Color? color}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: (color ?? AppColors.accent).withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text('$label: $value', style: TextStyle(color: color ?? AppColors.textPrimary)),
    );
  }

  Widget _buildHistoryCard(HistoryEntryModel entry) {
    Color actionColor;
    switch (entry.action) {
      case 'CREATE':
        actionColor = AppColors.success;
        break;
      case 'DELETE':
        actionColor = AppColors.error;
        break;
      default:
        actionColor = AppColors.warning;
    }
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: actionColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(entry.action, style: TextStyle(color: actionColor, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(entry.targetType, style: const TextStyle(fontSize: 10)),
                ),
                const Spacer(),
                Text(
                  '${entry.actionAt.day}/${entry.actionAt.month}/${entry.actionAt.year} ${entry.actionAt.hour}:${entry.actionAt.minute.toString().padLeft(2, '0')}',
                  style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              entry.targetType == 'ARTICLE' ? (entry.articleName ?? '-') : (entry.variationLabel ?? '-'),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            if (entry.summary.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(entry.summary, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
              ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.person, size: 12, color: AppColors.textSecondary),
                const SizedBox(width: 4),
                Text(entry.actorName, style: const TextStyle(fontSize: 11)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}