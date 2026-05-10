import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/constants/app_colors.dart';
import '../../core/models/admin_models.dart';
import '../../core/services/admin_service.dart';
import '../../core/api/api_client.dart';

class VendeurCatalogPage extends StatefulWidget {
  const VendeurCatalogPage({super.key});

  @override
  State<VendeurCatalogPage> createState() => _VendeurCatalogPageState();
}

class _VendeurCatalogPageState extends State<VendeurCatalogPage> {
  List<VendeurArticle> _articles = [];
  VendeurArticle? _selectedArticle;
  bool _isLoading = true;
  String _error = '';
  String _searchQuery = '';
  int _articlePage = 1;
  int _articleRows = 5;
  int _variationPage = 1;
  int _variationRows = 3;

  // Only ONE declaration of _imagePicker
  final ImagePicker _imagePicker = ImagePicker();

  // Form states
  final _articleFormKey = GlobalKey<FormState>();
  final _variationFormKey = GlobalKey<FormState>();

  // Article form
  final _nomController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _detailsController = TextEditingController();
  final _prixController = TextEditingController();
  final _salePriceController = TextEditingController();
  final _saleStartController = TextEditingController();
  final _saleEndController = TextEditingController();
  final _marqueController = TextEditingController();
  final _matiereController = TextEditingController();
  final _skuController = TextEditingController();
  bool _actif = true;
  bool _recommended = false;
  int? _editingArticleId;

  // Category hierarchy
  List<CategoryModel> _mainCategories = [];
  List<CategoryModel> _subCategories = [];
  List<CategoryModel> _productTypes = [];
  List<CategoryModel> _allCategories = [];
  int? _selectedMainCat;
  int? _selectedSubCat;
  int? _selectedProductType;
  int? _selectedCategorieId;

  // Variation form
  List<ColorModel> _colors = [];
  List<SizeModel> _sizes = [];
  int? _selectedColorId;
  double _variationPrice = 0;
  int _variationStock = 0;
  List<VendeurSizeStock> _sizeStocks = [];
  List<File> _variationImages = [];
  File? _variationModel3d;
  List<String> _existingImageUrls = [];
  int? _editingVariationId;
  Map<String, dynamic>? _editingVariationGroup;

  // Stock dialog
  int? _stockVariationId;
  String _stockLabel = '';
  int _currentStock = 0;
  int _stockQuantity = 1;
  bool _isIncrement = true;

  // UI state
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  @override
  void dispose() {
    _nomController.dispose();
    _descriptionController.dispose();
    _detailsController.dispose();
    _prixController.dispose();
    _salePriceController.dispose();
    _saleStartController.dispose();
    _saleEndController.dispose();
    _marqueController.dispose();
    _matiereController.dispose();
    _skuController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    setState(() => _isLoading = true);
    try {
      print('🚀 Loading initial data...');

      final results = await Future.wait([
        AdminService.fetchVendeurArticles(),
        AdminService.fetchMainCategories(),
        AdminService.fetchColors(),
        AdminService.fetchSizes(),
        AdminService.fetchAllCategories(),
      ]);

      // Debug each result type
      print('Articles: ${results[0].runtimeType}');
      print('MainCategories: ${results[1].runtimeType}');
      print('Colors: ${results[2].runtimeType}');
      print('Sizes: ${results[3].runtimeType}');
      print('AllCategories: ${results[4].runtimeType}');

      // Debug first category if exists
      if (results[1].isNotEmpty) {
        final firstCat = results[1].first as CategoryModel;
        print('First category: ${firstCat.nom}');
        print('Category ID: ${firstCat.id} (type: ${firstCat.id.runtimeType})');
      }

      // Debug first color if exists - FIXED: cast to ColorModel, not Map
      if (results[2].isNotEmpty) {
        final firstColor = results[2].first as ColorModel;
        print('First color: ${firstColor.nom} (${firstColor.codeHex})');
        print('Color ID: ${firstColor.id} (type: ${firstColor.id.runtimeType})');
      }

      setState(() {
        _articles = results[0] as List<VendeurArticle>;
        _mainCategories = results[1] as List<CategoryModel>;
        _colors = results[2] as List<ColorModel>;
        _sizes = results[3] as List<SizeModel>;
        _allCategories = results[4] as List<CategoryModel>;
        _isLoading = false;
      });

      if (_articles.isNotEmpty) {
        await _selectArticle(_articles.first);
      }
    } catch (e, stacktrace) {
      print('❌ Error loading data: $e');
      print('Stacktrace: $stacktrace');
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _selectArticle(VendeurArticle article) async {
    setState(() => _isLoading = true);
    try {
      final detail = await AdminService.fetchVendeurArticleDetail(article.id);
      setState(() {
        _selectedArticle = detail;
        _isLoading = false;
        _variationPage = 1;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _refresh() async {
    try {
      final articles = await AdminService.fetchVendeurArticles();
      setState(() {
        _articles = articles;
        if (_selectedArticle != null) {
          final stillExists = articles.any((a) => a.id == _selectedArticle!.id);
          if (stillExists) {
            _selectArticle(_selectedArticle!);
          } else {
            setState(() => _selectedArticle = null);
          }
        }
      });
    } catch (e) {
      setState(() => _error = e.toString());
    }
  }

  List<VendeurArticle> get _filteredArticles {
    if (_searchQuery.isEmpty) return _articles;
    final q = _searchQuery.toLowerCase();
    return _articles.where((a) =>
    a.nom.toLowerCase().contains(q) ||
        a.description.toLowerCase().contains(q) ||
        a.categorieNom.toLowerCase().contains(q) ||
        a.marque.toLowerCase().contains(q) ||
        a.sku.toLowerCase().contains(q)
    ).toList();
  }

  List<VendeurArticle> get _pagedArticles {
    final start = (_articlePage - 1) * _articleRows;
    final end = start + _articleRows;
    final filtered = _filteredArticles;
    if (start >= filtered.length) return [];
    return filtered.sublist(start, end > filtered.length ? filtered.length : end);
  }

  int get _totalArticlePages => (_filteredArticles.length / _articleRows).ceil();

  List<VendeurVariation> get _pagedVariations {
    if (_selectedArticle == null) return [];
    final start = (_variationPage - 1) * _variationRows;
    final end = start + _variationRows;
    final vars = _selectedArticle!.variations;
    if (start >= vars.length) return [];
    return vars.sublist(start, end > vars.length ? vars.length : end);
  }

  int get _totalVariationPages => _selectedArticle == null ? 0 : (_selectedArticle!.variations.length / _variationRows).ceil();

  bool _isAccessoryCategory() {
    if (_selectedArticle == null) return false;
    final normalized = _selectedArticle!.categorieNom.trim().toLowerCase();
    return normalized == 'accessoire' || normalized == 'accessoires' ||
        normalized == 'accessory' || normalized == 'sac a main' ||
        normalized == 'sac à main' || normalized == 'pochette de soirée';
  }

  Future<void> _loadSubCategories(int parentId) async {
    try {
      final children = await AdminService.fetchChildCategories(parentId);
      if (mounted) {
        setState(() => _subCategories = children);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _subCategories = []);
      }
    }
  }

  Future<void> _loadProductTypes(int parentId) async {
    try {
      final children = await AdminService.fetchChildCategories(parentId);
      if (mounted) {
        setState(() => _productTypes = children);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _productTypes = []);
      }
    }
  }

  void _resetCategorySelections() {
    setState(() {
      _selectedMainCat = null;
      _selectedSubCat = null;
      _selectedProductType = null;
      _selectedCategorieId = null;
      _subCategories = [];
      _productTypes = [];
    });
  }

  void _showArticleDialog({VendeurArticle? article}) {
    _editingArticleId = article?.id;

    if (article != null) {
      _nomController.text = article.nom;
      _descriptionController.text = article.description;
      _detailsController.text = article.details;
      _prixController.text = article.prix.toString();
      _salePriceController.text = article.salePrice?.toString() ?? '';
      _marqueController.text = article.marque;
      _matiereController.text = article.matiere;
      _skuController.text = article.sku;
      _actif = article.actif;
      _recommended = article.recommended;
      _selectedCategorieId = article.categorieId;

      final category = _allCategories.firstWhere((c) => c.id == article.categorieId);
      _resetCategorySelections();

      if (category.parentId != null) {
        final parent = _allCategories.firstWhere((c) => c.id == category.parentId);
        if (parent.parentId != null) {
          final grandParent = _allCategories.firstWhere((c) => c.id == parent.parentId);
          _selectedMainCat = grandParent.id;
          _selectedSubCat = parent.id;
          _selectedProductType = category.id;
          _selectedCategorieId = category.id;
          _loadSubCategories(grandParent.id);
          _loadProductTypes(parent.id);
        } else {
          _selectedMainCat = parent.id;
          _selectedSubCat = category.id;
          _selectedCategorieId = category.id;
          _loadSubCategories(parent.id);
        }
      } else {
        _selectedMainCat = category.id;
        _selectedCategorieId = category.id;
      }
    } else {
      _nomController.clear();
      _descriptionController.clear();
      _detailsController.clear();
      _prixController.clear();
      _salePriceController.clear();
      _saleStartController.clear();
      _saleEndController.clear();
      _marqueController.clear();
      _matiereController.clear();
      _skuController.clear();
      _actif = true;
      _recommended = false;
      _selectedCategorieId = null;
      _resetCategorySelections();
    }

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          return AlertDialog(
            backgroundColor: AppColors.surface,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Text(article == null ? 'Add Article' : 'Edit Article', style: const TextStyle(color: AppColors.textPrimary)),
            content: SizedBox(
              width: 500,
              height: 550,
              child: SingleChildScrollView(
                child: Form(
                  key: _articleFormKey,
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _nomController,
                        style: const TextStyle(color: AppColors.textPrimary),
                        decoration: const InputDecoration(labelText: 'Product Name *', labelStyle: TextStyle(color: AppColors.textSecondary)),
                        validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<int?>(
                        value: _selectedMainCat,
                        dropdownColor: AppColors.surface,
                        decoration: const InputDecoration(labelText: 'Main Category', labelStyle: TextStyle(color: AppColors.textSecondary)),
                        items: [
                          const DropdownMenuItem<int?>(value: null, child: Text('Select main category', style: TextStyle(color: AppColors.textSecondary))),
                          ..._mainCategories.map<DropdownMenuItem<int?>>((c) => DropdownMenuItem<int?>(
                            value: c.id,
                            child: Text(c.nom, style: const TextStyle(color: AppColors.textPrimary)),
                          )),
                        ],
                        onChanged: (value) async {
                          setModalState(() {
                            _selectedMainCat = value;
                            _selectedSubCat = null;
                            _selectedProductType = null;
                            _selectedCategorieId = null;
                          });
                          if (value != null) await _loadSubCategories(value);
                          else setModalState(() => _subCategories = []);
                        },
                      ),
                      if (_subCategories.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        DropdownButtonFormField<int?>(
                          value: _selectedSubCat,
                          dropdownColor: AppColors.surface,
                          decoration: const InputDecoration(labelText: 'Sub Category', labelStyle: TextStyle(color: AppColors.textSecondary)),
                          items: [
                            const DropdownMenuItem<int?>(value: null, child: Text('Select sub category', style: TextStyle(color: AppColors.textSecondary))),
                            ..._subCategories.map<DropdownMenuItem<int?>>((c) => DropdownMenuItem<int?>(
                              value: c.id,
                              child: Text(c.nom, style: const TextStyle(color: AppColors.textPrimary)),
                            )),
                          ],
                          onChanged: (value) async {
                            setModalState(() {
                              _selectedSubCat = value;
                              _selectedProductType = null;
                              _selectedCategorieId = value;
                            });
                            if (value != null) await _loadProductTypes(value);
                            else setModalState(() => _productTypes = []);
                          },
                        ),
                      ],
                      if (_productTypes.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        DropdownButtonFormField<int?>(
                          value: _selectedProductType,
                          dropdownColor: AppColors.surface,
                          decoration: const InputDecoration(labelText: 'Product Type', labelStyle: TextStyle(color: AppColors.textSecondary)),
                          items: [
                            const DropdownMenuItem<int?>(value: null, child: Text('Select product type', style: TextStyle(color: AppColors.textSecondary))),
                            ..._productTypes.map<DropdownMenuItem<int?>>((c) => DropdownMenuItem<int?>(
                              value: c.id,
                              child: Text(c.nom, style: const TextStyle(color: AppColors.textPrimary)),
                            )),
                          ],
                          onChanged: (value) {
                            setModalState(() {
                              _selectedProductType = value;
                              _selectedCategorieId = value;
                            });
                          },
                        ),
                      ],
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _prixController,
                        style: const TextStyle(color: AppColors.textPrimary),
                        decoration: const InputDecoration(labelText: 'Price *', labelStyle: TextStyle(color: AppColors.textSecondary)),
                        keyboardType: TextInputType.number,
                        validator: (v) {
                          if (v == null || v.isEmpty) return 'Required';
                          if (double.tryParse(v) == null) return 'Invalid number';
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _salePriceController,
                        style: const TextStyle(color: AppColors.textPrimary),
                        decoration: const InputDecoration(labelText: 'Sale Price', labelStyle: TextStyle(color: AppColors.textSecondary)),
                        keyboardType: TextInputType.number,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _marqueController,
                        style: const TextStyle(color: AppColors.textPrimary),
                        decoration: const InputDecoration(labelText: 'Brand', labelStyle: TextStyle(color: AppColors.textSecondary)),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _matiereController,
                        style: const TextStyle(color: AppColors.textPrimary),
                        decoration: const InputDecoration(labelText: 'Material', labelStyle: TextStyle(color: AppColors.textSecondary)),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _skuController,
                        style: const TextStyle(color: AppColors.textPrimary),
                        decoration: const InputDecoration(labelText: 'SKU', labelStyle: TextStyle(color: AppColors.textSecondary)),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: CheckboxListTile(
                              title: const Text('Active', style: TextStyle(color: AppColors.textPrimary)),
                              value: _actif,
                              onChanged: (v) => setModalState(() => _actif = v ?? true),
                              contentPadding: EdgeInsets.zero,
                            ),
                          ),
                          Expanded(
                            child: CheckboxListTile(
                              title: const Text('Recommended', style: TextStyle(color: AppColors.textPrimary)),
                              value: _recommended,
                              onChanged: (v) => setModalState(() => _recommended = v ?? false),
                              contentPadding: EdgeInsets.zero,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _descriptionController,
                        style: const TextStyle(color: AppColors.textPrimary),
                        decoration: const InputDecoration(labelText: 'Short Description', labelStyle: TextStyle(color: AppColors.textSecondary)),
                        maxLines: 3,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _detailsController,
                        style: const TextStyle(color: AppColors.textPrimary),
                        decoration: const InputDecoration(labelText: 'More Informations', labelStyle: TextStyle(color: AppColors.textSecondary)),
                        maxLines: 4,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
              ),
              ElevatedButton(
                onPressed: _isSaving ? null : () => _saveArticle(context),
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.accent),
                child: _isSaving ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Save'),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _saveArticle(BuildContext context) async {
    if (!_articleFormKey.currentState!.validate()) return;

    final categorieId = _selectedCategorieId;

    if (categorieId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a complete category path')),
      );
      return;
    }

    setState(() => _isSaving = true);

    final data = {
      'nom': _nomController.text.trim(),
      'description': _descriptionController.text.trim(),
      'details': _detailsController.text.trim(),
      'prix': double.parse(_prixController.text),
      'salePrice': _salePriceController.text.isNotEmpty ? double.parse(_salePriceController.text) : null,
      'saleStartAt': _saleStartController.text.isNotEmpty ? _saleStartController.text : null,
      'saleEndAt': _saleEndController.text.isNotEmpty ? _saleEndController.text : null,
      'actif': _actif,
      'recommended': _recommended,
      'categorieId': categorieId,
      'marque': _marqueController.text.trim(),
      'matiere': _matiereController.text.trim(),
      'sku': _skuController.text.trim(),
    };

    try {
      if (_editingArticleId != null) {
        await AdminService.updateVendeurArticle(_editingArticleId!, data, null);
      } else {
        await AdminService.createVendeurArticle(data, null);
      }
      if (mounted) {
        Navigator.pop(context);
        await _refresh();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Article saved successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  // ========== VARIATION IMAGE PICKER ==========
  Future<void> _pickVariationImages() async {
    final List<XFile>? pickedImages = await _imagePicker.pickMultiImage();
    if (pickedImages != null && pickedImages.isNotEmpty) {
      setState(() {
        _variationImages.addAll(pickedImages.map((x) => File(x.path)));
      });
    }
  }

  void _showVariationDialog({VendeurVariation? variation}) {
    _editingVariationId = variation?.id;
    _variationPrice = variation?.prix ?? _selectedArticle?.prix ?? 0;
    _variationStock = variation?.quantiteStock ?? 0;
    _selectedColorId = variation?.couleurId;
    _existingImageUrls = List.from(variation?.imageUrls ?? []);
    _variationImages = [];
    _variationModel3d = null;

    if (!_isAccessoryCategory()) {
      _sizeStocks = _sizes.map((s) {
        VendeurVariation? existing;
        try {
          existing = _selectedArticle?.variations.firstWhere(
                (v) => v.couleurId == _selectedColorId && v.tailleId == s.id,
          );
        } catch (e) {
          existing = null;
        }
        return VendeurSizeStock(
          tailleId: s.id,
          label: s.pointure,
          checked: existing != null || variation?.tailleId == s.id,
          quantiteStock: existing?.quantiteStock ?? (variation?.tailleId == s.id ? variation!.quantiteStock : 0),
          disabled: existing != null && variation?.tailleId != s.id,
        );
      }).toList();
    }

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          return AlertDialog(
            backgroundColor: AppColors.surface,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Text(variation == null ? 'Add Variation' : 'Edit Variation', style: const TextStyle(color: AppColors.textPrimary)),
            content: SizedBox(
              width: 500,
              height: 500,
              child: SingleChildScrollView(
                child: Form(
                  key: _variationFormKey,
                  child: Column(
                    children: [
                      DropdownButtonFormField<int?>(
                        value: _selectedColorId,
                        dropdownColor: AppColors.surface,
                        decoration: const InputDecoration(labelText: 'Color *', labelStyle: TextStyle(color: AppColors.textSecondary)),
                        items: _colors.map<DropdownMenuItem<int?>>((c) => DropdownMenuItem<int?>(
                          value: c.id,
                          child: Row(
                            children: [
                              Container(width: 20, height: 20, decoration: BoxDecoration(color: _getColorFromHex(c.codeHex), shape: BoxShape.circle)),
                              const SizedBox(width: 8),
                              Text(c.nom, style: const TextStyle(color: AppColors.textPrimary)),
                            ],
                          ),
                        )).toList(),
                        onChanged: (value) {
                          setModalState(() => _selectedColorId = value);
                          if (!_isAccessoryCategory() && value != null) {
                            _sizeStocks = _sizes.map((s) {
                              VendeurVariation? existing;
                              try {
                                existing = _selectedArticle?.variations.firstWhere(
                                      (v) => v.couleurId == value && v.tailleId == s.id,
                                );
                              } catch (e) {
                                existing = null;
                              }
                              return VendeurSizeStock(
                                tailleId: s.id,
                                label: s.pointure,
                                checked: existing != null,
                                quantiteStock: existing?.quantiteStock ?? 0,
                                disabled: existing != null,
                              );
                            }).toList();
                          }
                        },
                        validator: (v) => v == null ? 'Required' : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        initialValue: _variationPrice.toString(),
                        style: const TextStyle(color: AppColors.textPrimary),
                        decoration: const InputDecoration(labelText: 'Price *', labelStyle: TextStyle(color: AppColors.textSecondary)),
                        keyboardType: TextInputType.number,
                        onChanged: (v) => _variationPrice = double.tryParse(v) ?? 0,
                      ),
                      const SizedBox(height: 12),
                      if (_isAccessoryCategory())
                        TextFormField(
                          initialValue: _variationStock.toString(),
                          style: const TextStyle(color: AppColors.textPrimary),
                          decoration: const InputDecoration(labelText: 'Stock *', labelStyle: TextStyle(color: AppColors.textSecondary)),
                          keyboardType: TextInputType.number,
                          onChanged: (v) => _variationStock = int.tryParse(v) ?? 0,
                        )
                      else
                        ..._sizeStocks.map((sizeStock) {
                          return CheckboxListTile(
                            title: Text(sizeStock.label, style: const TextStyle(color: AppColors.textPrimary)),
                            subtitle: sizeStock.disabled ? const Text('Already exists', style: TextStyle(color: AppColors.error, fontSize: 12)) : null,
                            value: sizeStock.checked && !sizeStock.disabled,
                            onChanged: sizeStock.disabled ? null : (val) {
                              setModalState(() => sizeStock.checked = val ?? false);
                            },
                            secondary: sizeStock.checked && !sizeStock.disabled
                                ? SizedBox(
                              width: 100,
                              child: TextFormField(
                                initialValue: sizeStock.quantiteStock.toString(),
                                style: const TextStyle(color: AppColors.textPrimary),
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(labelText: 'Stock', border: OutlineInputBorder()),
                                onChanged: (v) => sizeStock.quantiteStock = int.tryParse(v) ?? 0,
                              ),
                            )
                                : null,
                          );
                        }).toList(),
                      const SizedBox(height: 12),
                      const Text('Variation Images', style: TextStyle(color: AppColors.textPrimary)),
                      if (_existingImageUrls.isNotEmpty)
                        Wrap(
                          children: _existingImageUrls.map((url) => Stack(
                            children: [
                              Container(
                                width: 80, height: 80, margin: const EdgeInsets.all(4),
                                decoration: BoxDecoration(border: Border.all(color: AppColors.border), borderRadius: BorderRadius.circular(8)),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.network(_getFullImageUrl(url), fit: BoxFit.cover, errorBuilder: (_, __, ___) => Container(color: AppColors.border)),
                                ),
                              ),
                              Positioned(
                                top: 0, right: 0,
                                child: InkWell(
                                  onTap: () => setModalState(() => _existingImageUrls.remove(url)),
                                  child: Container(
                                    decoration: const BoxDecoration(color: AppColors.error, shape: BoxShape.circle),
                                    child: const Icon(Icons.close, size: 16, color: Colors.white),
                                  ),
                                ),
                              ),
                            ],
                          )).toList(),
                        ),
                      InkWell(
                        onTap: _pickVariationImages,
                        child: Container(
                          width: 80, height: 80, margin: const EdgeInsets.all(4),
                          decoration: BoxDecoration(border: Border.all(color: AppColors.border), borderRadius: BorderRadius.circular(8)),
                          child: const Icon(Icons.add_photo_alternate, size: 40),
                        ),
                      ),
                      ..._variationImages.map((file) => Stack(
                        children: [
                          Container(
                            width: 80, height: 80, margin: const EdgeInsets.all(4),
                            decoration: BoxDecoration(border: Border.all(color: AppColors.border), borderRadius: BorderRadius.circular(8)),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.file(file, fit: BoxFit.cover),
                            ),
                          ),
                          Positioned(
                            top: 0, right: 0,
                            child: InkWell(
                              onTap: () => setModalState(() => _variationImages.remove(file)),
                              child: Container(
                                decoration: const BoxDecoration(color: AppColors.error, shape: BoxShape.circle),
                                child: const Icon(Icons.close, size: 16, color: Colors.white),
                              ),
                            ),
                          ),
                        ],
                      )).toList(),
                    ],
                  ),
                ),
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary))),
              ElevatedButton(
                onPressed: _isSaving ? null : () => _saveVariation(context, setModalState),
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.accent),
                child: _isSaving ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Save'),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _saveVariation(BuildContext context, StateSetter setModalState) async {
    if (_selectedColorId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select a color')));
      return;
    }

    setState(() => _isSaving = true);

    if (_isAccessoryCategory()) {
      final data = {
        'couleurId': _selectedColorId,
        'prix': _variationPrice,
        'quantiteStock': _variationStock,
        'existingImageUrls': _existingImageUrls,
      };
      try {
        if (_editingVariationId != null) {
          await AdminService.updateVendeurVariation(_editingVariationId!, data, _variationImages.isEmpty ? null : _variationImages, _variationModel3d);
        } else {
          await AdminService.createVendeurVariation(_selectedArticle!.id, data, _variationImages.isEmpty ? null : _variationImages, _variationModel3d);
        }
        if (mounted) {
          Navigator.pop(context);
          await _selectArticle(_selectedArticle!);
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Variation saved')));
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error));
        }
      }
    } else {
      final activeSizes = _sizeStocks.where((s) => s.checked).toList();
      if (activeSizes.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select at least one size')));
        setState(() => _isSaving = false);
        return;
      }
      final data = {
        'couleurId': _selectedColorId,
        'prix': _variationPrice,
        'sizes': activeSizes.map((s) => {'tailleId': s.tailleId, 'quantiteStock': s.quantiteStock}).toList(),
        'existingImageUrls': _existingImageUrls,
      };
      try {
        if (_editingVariationId != null) {
          await AdminService.updateVendeurVariation(_editingVariationId!, data, _variationImages.isEmpty ? null : _variationImages, _variationModel3d);
        } else {
          await AdminService.createVendeurVariation(_selectedArticle!.id, data, _variationImages.isEmpty ? null : _variationImages, _variationModel3d);
        }
        if (mounted) {
          Navigator.pop(context);
          await _selectArticle(_selectedArticle!);
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Variation saved')));
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error));
        }
      }
    }
    if (mounted) setState(() => _isSaving = false);
  }

  void _showStockDialog(VendeurVariation variation, bool increment) {
    _stockVariationId = variation.id;
    _stockLabel = '${variation.couleurNom}${variation.taillePointure != null ? ' / ${variation.taillePointure}' : ''}';
    _currentStock = variation.quantiteStock;
    _stockQuantity = 1;
    _isIncrement = increment;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text(increment ? 'Restock' : 'Sell / Use', style: const TextStyle(color: AppColors.textPrimary)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Variation: $_stockLabel', style: const TextStyle(color: AppColors.textPrimary)),
            const SizedBox(height: 8),
            Text('Current stock: $_currentStock', style: const TextStyle(color: AppColors.textSecondary)),
            const SizedBox(height: 16),
            TextFormField(
              initialValue: '1',
              keyboardType: TextInputType.number,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: const InputDecoration(labelText: 'Quantity', border: OutlineInputBorder()),
              onChanged: (v) => _stockQuantity = int.tryParse(v) ?? 1,
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(8)),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('New stock:', style: TextStyle(color: AppColors.textSecondary)),
                  Text(
                    '${increment ? _currentStock + _stockQuantity : _currentStock - _stockQuantity}',
                    style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.accent),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary))),
          ElevatedButton(
            onPressed: () async {
              final newStock = increment ? _currentStock + _stockQuantity : _currentStock - _stockQuantity;
              if (newStock < 0) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Stock cannot be negative')));
                return;
              }
              final data = {
                'couleurId': variation.couleurId,
                'prix': variation.prix,
                'quantiteStock': newStock,
                if (variation.tailleId != null) 'tailleId': variation.tailleId,
              };
              try {
                await AdminService.updateVendeurVariation(variation.id, data, null, null);
                if (mounted) {
                  Navigator.pop(context);
                  await _selectArticle(_selectedArticle!);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Stock updated')));
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error));
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: increment ? AppColors.success : AppColors.error),
            child: Text(increment ? 'Confirm Restock' : 'Confirm Sale'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteVariation(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Variation'),
        content: const Text('Are you sure you want to delete this variation?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete', style: TextStyle(color: AppColors.error))),
        ],
      ),
    );
    if (confirm != true) return;

    setState(() => _isSaving = true);
    try {
      await AdminService.deleteVendeurVariation(id);
      if (mounted) {
        await _selectArticle(_selectedArticle!);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Variation deleted')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  String _getFullImageUrl(String url) {
    if (url.isEmpty) return '';
    if (url.startsWith('http')) return url;
    return '${ApiClient.baseUrl}$url';
  }

  Color _getColorFromHex(String hex) {
    if (hex.isEmpty) return AppColors.surface;
    String cleanHex = hex;
    if (cleanHex.startsWith('#')) {
      cleanHex = cleanHex.substring(1);
    }
    if (cleanHex.length != 6) return AppColors.surface;
    try {
      final colorValue = int.parse(cleanHex, radix: 16) + 0xFF000000;
      return Color(colorValue);
    } catch (e) {
      return AppColors.surface;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('My Catalog'),
        backgroundColor: AppColors.surface,
        elevation: 0,
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _refresh),
          IconButton(icon: const Icon(Icons.add), onPressed: () => _showArticleDialog()),
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
            ElevatedButton(onPressed: _refresh, child: const Text('Retry')),
          ],
        ),
      )
          : Row(
        children: [
          // Left panel - Articles list
          Container(
            width: 350,
            decoration: BoxDecoration(
              color: AppColors.card,
              border: Border(right: BorderSide(color: AppColors.border)),
            ),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: TextField(
                    style: const TextStyle(color: AppColors.textPrimary),
                    decoration: InputDecoration(
                      hintText: 'Search my articles...',
                      hintStyle: const TextStyle(color: AppColors.textSecondary),
                      prefixIcon: const Icon(Icons.search, color: AppColors.textSecondary),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      filled: true,
                      fillColor: AppColors.surface,
                    ),
                    onChanged: (v) => setState(() {
                      _searchQuery = v;
                      _articlePage = 1;
                    }),
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: _pagedArticles.length,
                    itemBuilder: (_, i) {
                      final article = _pagedArticles[i];
                      final isSelected = _selectedArticle?.id == article.id;
                      final saleActive = article.salePrice != null && article.salePrice! < article.prix;
                      return InkWell(
                        onTap: () => _selectArticle(article),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isSelected ? AppColors.accent.withOpacity(0.1) : Colors.transparent,
                            border: Border(bottom: BorderSide(color: AppColors.border)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(article.nom, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                              const SizedBox(height: 4),
                              Text(article.categorieNom, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      saleActive
                                          ? '${article.salePrice!.toStringAsFixed(2)} DT'
                                          : '${article.prix.toStringAsFixed(2)} DT',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: saleActive ? AppColors.error : AppColors.textPrimary,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: article.actif ? AppColors.success.withOpacity(0.2) : AppColors.error.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      article.actif ? 'ACTIVE' : 'INACTIVE',
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: article.actif ? AppColors.success : AppColors.error,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                if (_totalArticlePages > 1)
                  Padding(
                    padding: const EdgeInsets.all(8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.chevron_left, color: AppColors.textPrimary),
                          onPressed: _articlePage > 1 ? () => setState(() => _articlePage--) : null,
                        ),
                        Text('$_articlePage / $_totalArticlePages', style: const TextStyle(color: AppColors.textPrimary)),
                        IconButton(
                          icon: const Icon(Icons.chevron_right, color: AppColors.textPrimary),
                          onPressed: _articlePage < _totalArticlePages ? () => setState(() => _articlePage++) : null,
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          // Right panel - Variations
          Expanded(
            child: _selectedArticle == null
                ? const Center(child: Text('Select an article from the list', style: TextStyle(color: AppColors.textSecondary)))
                : Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.card,
                    border: Border(bottom: BorderSide(color: AppColors.border)),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(_selectedArticle!.nom, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 16,
                              children: [
                                Text('Price: ${_selectedArticle!.prix.toStringAsFixed(2)} DT', style: const TextStyle(color: AppColors.textPrimary)),
                                if (_selectedArticle!.salePrice != null)
                                  Text('Sale: ${_selectedArticle!.salePrice!.toStringAsFixed(2)} DT', style: const TextStyle(color: AppColors.error)),
                                Text('Brand: ${_selectedArticle!.marque.isEmpty ? '-' : _selectedArticle!.marque}', style: const TextStyle(color: AppColors.textSecondary)),
                                Text('Stock: ${_selectedArticle!.variations.fold<int>(0, (s, v) => s + v.quantiteStock)}', style: const TextStyle(color: AppColors.textSecondary)),
                              ],
                            ),
                          ],
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed: () => _showVariationDialog(),
                        icon: const Icon(Icons.add),
                        label: const Text('Add Variation'),
                        style: ElevatedButton.styleFrom(backgroundColor: AppColors.accent),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: _selectedArticle!.variations.isEmpty
                      ? const Center(child: Text('No variations yet', style: TextStyle(color: AppColors.textSecondary)))
                      : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _pagedVariations.length,
                    itemBuilder: (_, i) {
                      final v = _pagedVariations[i];
                      final previewUrl = v.imageUrls.isNotEmpty ? _getFullImageUrl(v.imageUrls.first) : '';
                      return Card(
                        color: AppColors.card,
                        margin: const EdgeInsets.only(bottom: 12),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              Container(
                                width: 50,
                                height: 50,
                                decoration: BoxDecoration(
                                  color: _getColorFromHex(v.couleurCodeHex),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: previewUrl.isNotEmpty
                                    ? ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.network(
                                    previewUrl,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => Container(
                                      color: AppColors.border,
                                      child: const Icon(Icons.broken_image, size: 24, color: AppColors.textSecondary),
                                    ),
                                  ),
                                )
                                    : null,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(v.couleurNom, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                                    if (v.taillePointure != null)
                                      Text('Size: ${v.taillePointure}', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                                    Text('Price: ${v.prix.toStringAsFixed(2)} DT', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                                  ],
                                ),
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: v.quantiteStock > 0 ? AppColors.success.withOpacity(0.2) : AppColors.error.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      'Stock: ${v.quantiteStock}',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: v.quantiteStock > 0 ? AppColors.success : AppColors.error,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.add, size: 20),
                                        onPressed: () => _showStockDialog(v, true),
                                        color: AppColors.success,
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.remove, size: 20),
                                        onPressed: () => _showStockDialog(v, false),
                                        color: AppColors.error,
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.delete, size: 20),
                                        onPressed: () => _deleteVariation(v.id),
                                        color: AppColors.error,
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                if (_totalVariationPages > 1)
                  Padding(
                    padding: const EdgeInsets.all(8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.chevron_left, color: AppColors.textPrimary),
                          onPressed: _variationPage > 1 ? () => setState(() => _variationPage--) : null,
                        ),
                        Text('$_variationPage / $_totalVariationPages', style: const TextStyle(color: AppColors.textPrimary)),
                        IconButton(
                          icon: const Icon(Icons.chevron_right, color: AppColors.textPrimary),
                          onPressed: _variationPage < _totalVariationPages ? () => setState(() => _variationPage++) : null,
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showArticleDialog(),
        backgroundColor: AppColors.accent,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}