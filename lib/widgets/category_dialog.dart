import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/models/category_model.dart';

class CategoryDialog extends StatefulWidget {
  final CategoryModel? initialCategory;
  final List<CategoryModel> categories;
  final Function(Map<String, dynamic>) onSubmit;

  const CategoryDialog({
    super.key,
    this.initialCategory,
    required this.categories,
    required this.onSubmit,
  });

  @override
  State<CategoryDialog> createState() => _CategoryDialogState();
}

class _CategoryDialogState extends State<CategoryDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _displayOrderController = TextEditingController();
  final _iconUrlController = TextEditingController();

  CategoryModel? _parentCategory;
  bool _actif = true;

  @override
  void initState() {
    super.initState();
    if (widget.initialCategory != null) {
      _nameController.text = widget.initialCategory!.nom;
      _descriptionController.text = widget.initialCategory!.description ?? '';
      _displayOrderController.text = widget.initialCategory!.displayOrder.toString();
      _iconUrlController.text = widget.initialCategory!.iconUrl ?? '';
      _actif = widget.initialCategory!.actif;
      if (widget.initialCategory!.parentId != null) {
        try {
          _parentCategory = widget.categories.firstWhere(
                (c) => c.id == widget.initialCategory!.parentId,
          );
        } catch (e) {
          _parentCategory = null;
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.initialCategory != null;

    return AlertDialog(
      backgroundColor: AppColors.surface,
      title: Text(isEditing ? 'Edit Category' : 'Add Category', style: const TextStyle(color: AppColors.textPrimary)),
      content: SizedBox(
        width: 400,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _nameController,
                  style: const TextStyle(color: AppColors.textPrimary),
                  decoration: const InputDecoration(
                    labelText: 'Category Name *',
                    labelStyle: TextStyle(color: AppColors.textSecondary),
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<CategoryModel>(
                  value: _parentCategory,
                  dropdownColor: AppColors.surface,
                  decoration: const InputDecoration(
                    labelText: 'Parent Category',
                    labelStyle: TextStyle(color: AppColors.textSecondary),
                    border: OutlineInputBorder(),
                  ),
                  items: [
                    const DropdownMenuItem(value: null, child: Text('None (Root Category)', style: TextStyle(color: AppColors.textPrimary))),
                    ...widget.categories.where((c) => c.id != widget.initialCategory?.id).map((c) {
                      return DropdownMenuItem(value: c, child: Text(c.nom, style: const TextStyle(color: AppColors.textPrimary)));
                    }),
                  ],
                  onChanged: (value) => setState(() => _parentCategory = value),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _displayOrderController,
                  style: const TextStyle(color: AppColors.textPrimary),
                  decoration: const InputDecoration(
                    labelText: 'Display Order',
                    labelStyle: TextStyle(color: AppColors.textSecondary),
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _descriptionController,
                  style: const TextStyle(color: AppColors.textPrimary),
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    labelStyle: TextStyle(color: AppColors.textSecondary),
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _iconUrlController,
                  style: const TextStyle(color: AppColors.textPrimary),
                  decoration: const InputDecoration(
                    labelText: 'Icon URL',
                    labelStyle: TextStyle(color: AppColors.textSecondary),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Checkbox(
                      value: _actif,
                      onChanged: (v) => setState(() => _actif = v ?? true),
                    ),
                    const Text('Active', style: TextStyle(color: AppColors.textPrimary)),
                  ],
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
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              widget.onSubmit({
                'nom': _nameController.text.trim(),
                'description': _descriptionController.text.trim().isEmpty ? null : _descriptionController.text.trim(),
                'parentId': _parentCategory?.id,
                'displayOrder': int.tryParse(_displayOrderController.text) ?? 0,
                'iconUrl': _iconUrlController.text.trim().isEmpty ? null : _iconUrlController.text.trim(),
                'actif': _actif,
              });
            }
          },
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.accent),
          child: Text(isEditing ? 'Update' : 'Create'),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _displayOrderController.dispose();
    _iconUrlController.dispose();
    super.dispose();
  }
}