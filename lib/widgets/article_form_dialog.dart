import 'dart:io';
import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/models/article_model.dart';
import '../../core/models/category_model.dart';

class ArticleFormDialog extends StatefulWidget {
  final ArticleModel? initialArticle;
  final List<CategoryModel> categories;
  final List<CategoryModel> mainCategories;
  final Function(Map<String, dynamic>, List<File>?) onSubmit;

  const ArticleFormDialog({
    super.key,
    this.initialArticle,
    required this.categories,
    required this.mainCategories,
    required this.onSubmit,
  });

  @override
  State<ArticleFormDialog> createState() => _ArticleFormDialogState();
}

class _ArticleFormDialogState extends State<ArticleFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _detailsController = TextEditingController();
  final _priceController = TextEditingController();
  final _salePriceController = TextEditingController();
  final _saleStartController = TextEditingController();
  final _saleEndController = TextEditingController();
  final _brandController = TextEditingController();
  final _materialController = TextEditingController();
  final _skuController = TextEditingController();

  bool _isLoading = false;
  bool _actif = true;
  bool _recommended = false;

  // Category hierarchy
  CategoryModel? _selectedMainCat;
  CategoryModel? _selectedSubCat;
  CategoryModel? _selectedProductType;
  List<CategoryModel> _subCategories = [];
  List<CategoryModel> _productTypes = [];
  bool _isShoes = false;

  DateTime? _saleStartDate;
  DateTime? _saleEndDate;

  @override
  void initState() {
    super.initState();
    if (widget.initialArticle != null) {
      _nameController.text = widget.initialArticle!.nom;
      _descriptionController.text = widget.initialArticle!.description;
      _detailsController.text = widget.initialArticle!.details;
      _priceController.text = widget.initialArticle!.prix.toString();
      _salePriceController.text = widget.initialArticle!.salePrice?.toString() ?? '';
      _brandController.text = widget.initialArticle!.marque;
      _materialController.text = widget.initialArticle!.matiere;
      _skuController.text = widget.initialArticle!.sku;
      _actif = widget.initialArticle!.actif;
      _recommended = widget.initialArticle!.recommended;
      _saleStartDate = widget.initialArticle!.saleStartAt;
      _saleEndDate = widget.initialArticle!.saleEndAt;
      if (_saleStartDate != null) {
        _saleStartController.text = _saleStartDate!.toLocal().toString().split(' ')[0];
      }
      if (_saleEndDate != null) {
        _saleEndController.text = _saleEndDate!.toLocal().toString().split(' ')[0];
      }
      _loadCategoryHierarchy(widget.initialArticle!.categorieId);
    }
  }

  void _loadCategoryHierarchy(int categoryId) {
    final category = widget.categories.firstWhere((c) => c.id == categoryId);
    if (category.parentId != null) {
      final parent = widget.categories.firstWhere((c) => c.id == category.parentId);
      if (parent.parentId != null) {
        final grandParent = widget.categories.firstWhere((c) => c.id == parent.parentId);
        _selectedMainCat = grandParent;
        _selectedSubCat = parent;
        _selectedProductType = category;
        _isShoes = grandParent.nom.toUpperCase() == 'CHAUSSURES';
        _loadSubCategories(grandParent.id);
        _loadProductTypes(parent.id);
      } else {
        _selectedMainCat = parent;
        _selectedSubCat = category;
        _isShoes = parent.nom.toUpperCase() == 'CHAUSSURES';
        _loadSubCategories(parent.id);
      }
    } else {
      _selectedMainCat = category;
      _loadSubCategories(category.id);
    }
    setState(() {});
  }

  void _loadSubCategories(int parentId) {
    setState(() {
      _subCategories = widget.categories.where((c) => c.parentId == parentId).toList();
    });
  }

  void _loadProductTypes(int parentId) {
    setState(() {
      _productTypes = widget.categories.where((c) => c.parentId == parentId).toList();
    });
  }

  Future<void> _selectDate(bool isStart) async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (date != null) {
      setState(() {
        if (isStart) {
          _saleStartDate = date;
          _saleStartController.text = date.toLocal().toString().split(' ')[0];
        } else {
          _saleEndDate = date;
          _saleEndController.text = date.toLocal().toString().split(' ')[0];
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.initialArticle != null;
    final mainCategories = widget.mainCategories;

    return Dialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        height: MediaQuery.of(context).size.height * 0.9,
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    isEditing ? 'Edit Article' : 'Add Article',
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: SingleChildScrollView(
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Basic Info
                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(labelText: 'Product Name *'),
                        validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                      ),
                      const SizedBox(height: 16),

                      // Category Hierarchy
                      const Text('Category *', style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<CategoryModel>(
                        value: _selectedMainCat,
                        decoration: const InputDecoration(labelText: 'Main Category'),
                        items: mainCategories.map((c) {
                          return DropdownMenuItem(value: c, child: Text(c.nom));
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedMainCat = value;
                            _selectedSubCat = null;
                            _selectedProductType = null;
                            _subCategories = [];
                            _productTypes = [];
                            _isShoes = value?.nom.toUpperCase() == 'CHAUSSURES';
                            if (value != null) _loadSubCategories(value.id);
                          });
                        },
                      ),
                      const SizedBox(height: 8),
                      if (_subCategories.isNotEmpty)
                        DropdownButtonFormField<CategoryModel>(
                          value: _selectedSubCat,
                          decoration: const InputDecoration(labelText: 'Sub Category'),
                          items: _subCategories.map((c) {
                            return DropdownMenuItem(value: c, child: Text(c.nom));
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              _selectedSubCat = value;
                              _selectedProductType = null;
                              if (value != null) _loadProductTypes(value.id);
                            });
                          },
                        ),
                      const SizedBox(height: 8),
                      if (_productTypes.isNotEmpty)
                        DropdownButtonFormField<CategoryModel>(
                          value: _selectedProductType,
                          decoration: const InputDecoration(labelText: 'Product Type'),
                          items: _productTypes.map((c) {
                            return DropdownMenuItem(value: c, child: Text(c.nom));
                          }).toList(),
                          onChanged: (value) {
                            setState(() => _selectedProductType = value);
                          },
                        ),

                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _descriptionController,
                        decoration: const InputDecoration(labelText: 'Short Description'),
                        maxLines: 2,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _detailsController,
                        decoration: const InputDecoration(labelText: 'More Informations'),
                        maxLines: 3,
                      ),
                      const SizedBox(height: 16),

                      // Price Section
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _priceController,
                              decoration: const InputDecoration(labelText: 'Price *'),
                              keyboardType: TextInputType.number,
                              validator: (v) {
                                if (v == null || v.isEmpty) return 'Required';
                                if (double.tryParse(v) == null) return 'Invalid number';
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextFormField(
                              controller: _salePriceController,
                              decoration: const InputDecoration(labelText: 'Sale Price'),
                              keyboardType: TextInputType.number,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Sale Dates
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _saleStartController,
                              decoration: const InputDecoration(labelText: 'Sale Start'),
                              readOnly: true,
                              onTap: () => _selectDate(true),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextFormField(
                              controller: _saleEndController,
                              decoration: const InputDecoration(labelText: 'Sale End'),
                              readOnly: true,
                              onTap: () => _selectDate(false),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Additional Info
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _brandController,
                              decoration: const InputDecoration(labelText: 'Brand'),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextFormField(
                              controller: _materialController,
                              decoration: const InputDecoration(labelText: 'Material'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _skuController,
                        decoration: const InputDecoration(labelText: 'SKU'),
                      ),
                      const SizedBox(height: 16),

                      // Checkboxes - FIX OVERFLOW
                      Wrap(
                        spacing: 24,
                        runSpacing: 8,
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Checkbox(
                                value: _actif,
                                onChanged: (v) => setState(() => _actif = v ?? true),
                              ),
                              const Text('Active Product'),
                            ],
                          ),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Checkbox(
                                value: _recommended,
                                onChanged: (v) => setState(() => _recommended = v ?? false),
                              ),
                              const Text('Best Choice'),
                            ],
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 16),
                ElevatedButton(
                  onPressed: _isLoading ? null : _submit,
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.accent),
                  child: _isLoading
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                      : Text(isEditing ? 'Update' : 'Create'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedMainCat == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a category')),
      );
      return;
    }

    final int categoryId;
    if (_selectedProductType != null) {
      categoryId = _selectedProductType!.id;
    } else if (_selectedSubCat != null) {
      categoryId = _selectedSubCat!.id;
    } else {
      categoryId = _selectedMainCat!.id;
    }

    setState(() => _isLoading = true);

    final data = {
      'nom': _nameController.text.trim(),
      'description': _descriptionController.text.trim(),
      'details': _detailsController.text.trim(),
      'prix': double.parse(_priceController.text),
      'salePrice': _salePriceController.text.isNotEmpty ? double.parse(_salePriceController.text) : null,
      'saleStartAt': _saleStartDate,
      'saleEndAt': _saleEndDate,
      'actif': _actif,
      'recommended': _recommended,
      'categorieId': categoryId,
      'marque': _brandController.text.trim(),
      'matiere': _materialController.text.trim(),
      'sku': _skuController.text.trim(),
    };

    await widget.onSubmit(data, null); // No images for article
    if (mounted) setState(() => _isLoading = false);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _detailsController.dispose();
    _priceController.dispose();
    _salePriceController.dispose();
    _saleStartController.dispose();
    _saleEndController.dispose();
    _brandController.dispose();
    _materialController.dispose();
    _skuController.dispose();
    super.dispose();
  }
}