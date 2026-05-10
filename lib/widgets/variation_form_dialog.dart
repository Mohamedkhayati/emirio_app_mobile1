import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import '../core/constants/app_colors.dart';
import '../core/models/color_model.dart';
import '../core/models/size_model.dart';
import '../core/models/variation_model.dart';
import '../core/services/admin_catalog_service.dart';

// ----------------------------------------------------------------------
// VariationFormDialog (individual create/edit)
// ----------------------------------------------------------------------
class VariationFormDialog extends StatefulWidget {
  final int articleId;
  final VariationModel? initialVariation;
  final bool isAccessory;
  final List<ColorModel> colors;
  final List<SizeModel> sizes;
  final VoidCallback onSubmit;

  const VariationFormDialog({
    super.key,
    required this.articleId,
    this.initialVariation,
    required this.isAccessory,
    required this.colors,
    required this.sizes,
    required this.onSubmit,
  });

  @override
  State<VariationFormDialog> createState() => _VariationFormDialogState();
}

class _VariationFormDialogState extends State<VariationFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late int _selectedColorId;
  int? _selectedSizeId;
  double _prix = 0;
  int _quantiteStock = 0;
  final List<String> _existingImageUrls = [];
  final List<File> _newImageFiles = [];
  File? _model3dFile;
  String _existingModel3dUrl = '';
  final TextEditingController _prixController = TextEditingController();
  final TextEditingController _stockController = TextEditingController();

  final ImagePicker _imagePicker = ImagePicker();
  bool _isLoading = false;

  bool get isEditing => widget.initialVariation != null;

  @override
  void initState() {
    super.initState();
    if (widget.initialVariation != null) {
      _selectedColorId = widget.initialVariation!.couleurId;
      _selectedSizeId = widget.initialVariation!.tailleId;
      _prix = widget.initialVariation!.prix;
      _quantiteStock = widget.initialVariation!.quantiteStock;
      _existingImageUrls.addAll(widget.initialVariation!.imageUrls);
      _existingModel3dUrl = widget.initialVariation!.model3dUrl ?? '';
      _prixController.text = _prix.toString();
      _stockController.text = _quantiteStock.toString();
    } else {
      _selectedColorId = widget.colors.isNotEmpty ? widget.colors.first.id : 0;
    }
  }

  Future<void> _pickImages() async {
    final List<XFile>? pickedImages = await _imagePicker.pickMultiImage();
    if (pickedImages != null && pickedImages.isNotEmpty) {
      setState(() {
        _newImageFiles.addAll(pickedImages.map((x) => File(x.path)));
      });
    }
  }

  Future<void> _pickModel3d() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['glb', 'gltf'],
    );

    if (result != null && result.files.single.path != null) {
      setState(() {
        _model3dFile = File(result.files.single.path!);
      });
    }
  }

  void _removeNewImage(int index) {
    setState(() {
      _newImageFiles.removeAt(index);
    });
  }

  void _removeExistingImage(int index) {
    setState(() {
      _existingImageUrls.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.surface,
      title: Text(
        isEditing ? 'Edit Variation' : 'Add Variation',
        style: const TextStyle(color: AppColors.textPrimary),
      ),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Color selection
              DropdownButtonFormField<int>(
                value: _selectedColorId,
                dropdownColor: AppColors.surface,
                decoration: const InputDecoration(
                  labelText: 'Color *',
                  labelStyle: TextStyle(color: AppColors.textSecondary),
                  border: OutlineInputBorder(),
                ),
                items: widget.colors.map((c) {
                  return DropdownMenuItem(
                    value: c.id,
                    child: Row(
                      children: [
                        Container(
                          width: 20,
                          height: 20,
                          decoration: BoxDecoration(
                            color: Color(int.parse(c.codeHex.substring(1), radix: 16) + 0xFF000000),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(c.nom, style: const TextStyle(color: AppColors.textPrimary)),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() => _selectedColorId = value!);
                },
                validator: (v) => v == null || v == 0 ? 'Select a color' : null,
              ),
              const SizedBox(height: 16),

              // Size selection (if not accessory)
              if (!widget.isAccessory)
                DropdownButtonFormField<int>(
                  value: _selectedSizeId,
                  dropdownColor: AppColors.surface,
                  decoration: const InputDecoration(
                    labelText: 'Size *',
                    labelStyle: TextStyle(color: AppColors.textSecondary),
                    border: OutlineInputBorder(),
                  ),
                  items: widget.sizes.map((s) {
                    return DropdownMenuItem(
                      value: s.id,
                      child: Text(s.pointure, style: const TextStyle(color: AppColors.textPrimary)),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() => _selectedSizeId = value);
                  },
                  validator: (v) => v == null ? 'Select a size' : null,
                ),
              if (!widget.isAccessory) const SizedBox(height: 16),

              // Price
              TextFormField(
                controller: _prixController,
                style: const TextStyle(color: AppColors.textPrimary),
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Price *',
                  labelStyle: TextStyle(color: AppColors.textSecondary),
                  border: OutlineInputBorder(),
                  suffixText: 'DT',
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Required';
                  if (double.tryParse(v) == null) return 'Invalid number';
                  return null;
                },
                onChanged: (v) {
                  _prix = double.tryParse(v) ?? 0;
                },
              ),
              const SizedBox(height: 16),

              // Stock quantity (only for accessory)
              if (widget.isAccessory)
                TextFormField(
                  controller: _stockController,
                  style: const TextStyle(color: AppColors.textPrimary),
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Stock Quantity *',
                    labelStyle: TextStyle(color: AppColors.textSecondary),
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Required';
                    if (int.tryParse(v) == null) return 'Invalid number';
                    return null;
                  },
                  onChanged: (v) {
                    _quantiteStock = int.tryParse(v) ?? 0;
                  },
                ),
              if (!widget.isAccessory) const SizedBox(height: 16),

              // Images Section - with file picker
              const Text('Variation Images', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),

              // Existing saved images (from server)
              if (_existingImageUrls.isNotEmpty) ...[
                const Text('Saved Images:', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                const SizedBox(height: 4),
                SizedBox(
                  height: 100,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _existingImageUrls.length,
                    itemBuilder: (_, i) {
                      final url = _existingImageUrls[i];
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(
                                url,
                                width: 90,
                                height: 90,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Container(
                                  width: 90,
                                  height: 90,
                                  color: AppColors.border,
                                  child: const Icon(Icons.broken_image),
                                ),
                              ),
                            ),
                            Positioned(
                              top: 4,
                              right: 4,
                              child: CircleAvatar(
                                radius: 12,
                                backgroundColor: Colors.black54,
                                child: IconButton(
                                  icon: const Icon(Icons.close, size: 12, color: Colors.white),
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                  onPressed: () => _removeExistingImage(i),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 8),
              ],

              // New selected images (from device)
              if (_newImageFiles.isNotEmpty) ...[
                const Text('New Images:', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                const SizedBox(height: 4),
                SizedBox(
                  height: 100,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _newImageFiles.length,
                    itemBuilder: (_, i) {
                      final file = _newImageFiles[i];
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.file(
                                file,
                                width: 90,
                                height: 90,
                                fit: BoxFit.cover,
                              ),
                            ),
                            Positioned(
                              top: 4,
                              right: 4,
                              child: CircleAvatar(
                                radius: 12,
                                backgroundColor: Colors.black54,
                                child: IconButton(
                                  icon: const Icon(Icons.close, size: 12, color: Colors.white),
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                  onPressed: () => _removeNewImage(i),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 8),
              ],

              // Add image button
              ElevatedButton.icon(
                onPressed: _pickImages,
                icon: const Icon(Icons.add_photo_alternate),
                label: const Text('Select Images from Gallery'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  foregroundColor: Colors.white,
                ),
              ),
              const SizedBox(height: 16),

              // 3D Model Section
              const Text('3D Model (.glb or .gltf)', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),

              if (_existingModel3dUrl.isNotEmpty) ...[
                Row(
                  children: [
                    const Icon(Icons.model_training, size: 20, color: AppColors.success),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Current model saved',
                        style: const TextStyle(color: AppColors.textSecondary),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, size: 20, color: AppColors.error),
                      onPressed: () {
                        setState(() => _existingModel3dUrl = '');
                      },
                    ),
                  ],
                ),
              ],

              if (_model3dFile != null) ...[
                Row(
                  children: [
                    const Icon(Icons.model_training, size: 20, color: AppColors.success),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _model3dFile!.path.split('/').last,
                        style: const TextStyle(color: AppColors.textSecondary),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 20, color: AppColors.error),
                      onPressed: () {
                        setState(() => _model3dFile = null);
                      },
                    ),
                  ],
                ),
              ],

              ElevatedButton.icon(
                onPressed: _pickModel3d,
                icon: const Icon(Icons.add),
                label: const Text('Upload 3D Model'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _submit,
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.accent),
          child: _isLoading
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
              : Text(isEditing ? 'Update' : 'Create'),
        ),
      ],
    );
  }

  void _submit() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      try {
        if (isEditing) {
          await AdminCatalogService.updateVariation(
            widget.initialVariation!.id,
            couleurId: _selectedColorId,
            tailleId: _selectedSizeId,
            prix: _prix,
            quantiteStock: widget.isAccessory ? _quantiteStock : 0,
            existingImageUrls: _existingImageUrls,
            images: _newImageFiles,
            model3d: _model3dFile,
          );
        } else {
          await AdminCatalogService.createVariation(
            widget.articleId,
            couleurId: _selectedColorId,
            tailleId: _selectedSizeId,
            prix: _prix,
            quantiteStock: widget.isAccessory ? _quantiteStock : 0,
            existingImageUrls: _existingImageUrls,
            images: _newImageFiles,
            model3d: _model3dFile,
          );
        }
        widget.onSubmit();
        if (mounted) Navigator.pop(context);
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to ${isEditing ? "update" : "create"} variation: $e')),
          );
        }
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _prixController.dispose();
    _stockController.dispose();
    super.dispose();
  }
}

// ----------------------------------------------------------------------
// VariationGroupEditDialog (bulk edit sizes for a color)
// ----------------------------------------------------------------------
class VariationGroupEditDialog extends StatefulWidget {
  final int articleId;
  final Map<String, dynamic> group;
  final bool isAccessory;
  final List<ColorModel> colors;
  final List<SizeModel> sizes;
  final VoidCallback onSubmit;

  const VariationGroupEditDialog({
    super.key,
    required this.articleId,
    required this.group,
    required this.isAccessory,
    required this.colors,
    required this.sizes,
    required this.onSubmit,
  });

  @override
  State<VariationGroupEditDialog> createState() => _VariationGroupEditDialogState();
}

class _VariationGroupEditDialogState extends State<VariationGroupEditDialog> {
  late List<Map<String, dynamic>> _rows;
  late double _basePrix;
  final List<File> _newImageFiles = [];
  final List<String> _existingImageUrls = [];
  File? _model3dFile;
  String _existingModel3dUrl = '';
  final ImagePicker _imagePicker = ImagePicker();

  @override
  void initState() {
    super.initState();
    final items = widget.group['items'] as List<VariationModel>;
    _basePrix = widget.group['prix'] ?? 0.0;
    _existingImageUrls.addAll(widget.group['imageUrls'] ?? []);
    _existingModel3dUrl = items.isNotEmpty ? (items.first.model3dUrl ?? '') : '';
    if (widget.isAccessory) {
      _rows = [
        {
          'tailleId': null,
          'label': 'Stock only',
          'variationId': items.isNotEmpty ? items.first.id : null,
          'checked': true,
          'quantiteStock': items.isNotEmpty ? items.first.quantiteStock : 0,
          'prix': _basePrix,
        }
      ];
    } else {
      _rows = widget.sizes.map((s) {
        VariationModel? found;
        try {
          found = items.firstWhere((v) => v.tailleId == s.id);
        } catch (_) {
          found = null;
        }
        return {
          'tailleId': s.id,
          'label': s.pointure,
          'variationId': found?.id,
          'checked': found != null,
          'quantiteStock': found?.quantiteStock ?? 0,
          'prix': found?.prix ?? _basePrix,
        };
      }).toList();
    }
  }

  Future<void> _pickGroupImages() async {
    final List<XFile>? pickedImages = await _imagePicker.pickMultiImage();
    if (pickedImages != null && pickedImages.isNotEmpty) {
      setState(() {
        _newImageFiles.addAll(pickedImages.map((x) => File(x.path)));
      });
    }
  }

  Future<void> _pickGroupModel3d() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['glb', 'gltf'],
    );

    if (result != null && result.files.single.path != null) {
      setState(() {
        _model3dFile = File(result.files.single.path!);
      });
    }
  }

  void _removeNewGroupImage(int index) {
    setState(() {
      _newImageFiles.removeAt(index);
    });
  }

  void _removeExistingGroupImage(int index) {
    setState(() {
      _existingImageUrls.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.surface,
      title: Text('Edit ${widget.group['couleurNom']} Group',
          style: const TextStyle(color: AppColors.textPrimary)),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!widget.isAccessory)
              const Text('Check sizes and set stock values',
                  style: TextStyle(color: AppColors.textSecondary)),
            const SizedBox(height: 16),
            ..._rows.map((row) => _buildSizeRow(row)).toList(),
            const SizedBox(height: 16),

            // Images Section
            const Text('Images', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),

            // Existing saved images
            if (_existingImageUrls.isNotEmpty) ...[
              const Text('Saved Images:', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
              const SizedBox(height: 4),
              SizedBox(
                height: 100,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _existingImageUrls.length,
                  itemBuilder: (_, i) {
                    final url = _existingImageUrls[i];
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              url,
                              width: 90,
                              height: 90,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(
                                width: 90,
                                height: 90,
                                color: AppColors.border,
                                child: const Icon(Icons.broken_image),
                              ),
                            ),
                          ),
                          Positioned(
                            top: 4,
                            right: 4,
                            child: CircleAvatar(
                              radius: 12,
                              backgroundColor: Colors.black54,
                              child: IconButton(
                                icon: const Icon(Icons.close, size: 12, color: Colors.white),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                                onPressed: () => _removeExistingGroupImage(i),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 8),
            ],

            // New selected images
            if (_newImageFiles.isNotEmpty) ...[
              const Text('New Images:', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
              const SizedBox(height: 4),
              SizedBox(
                height: 100,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _newImageFiles.length,
                  itemBuilder: (_, i) {
                    final file = _newImageFiles[i];
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.file(
                              file,
                              width: 90,
                              height: 90,
                              fit: BoxFit.cover,
                            ),
                          ),
                          Positioned(
                            top: 4,
                            right: 4,
                            child: CircleAvatar(
                              radius: 12,
                              backgroundColor: Colors.black54,
                              child: IconButton(
                                icon: const Icon(Icons.close, size: 12, color: Colors.white),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                                onPressed: () => _removeNewGroupImage(i),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 8),
            ],

            // Add image button
            ElevatedButton.icon(
              onPressed: _pickGroupImages,
              icon: const Icon(Icons.add_photo_alternate),
              label: const Text('Select Images from Gallery'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accent,
                foregroundColor: Colors.white,
              ),
            ),
            const SizedBox(height: 16),

            // 3D Model Section
            const Text('3D Model', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),

            if (_existingModel3dUrl.isNotEmpty) ...[
              Row(
                children: [
                  const Icon(Icons.model_training, size: 20, color: AppColors.success),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Current model saved',
                      style: const TextStyle(color: AppColors.textSecondary),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, size: 20, color: AppColors.error),
                    onPressed: () {
                      setState(() => _existingModel3dUrl = '');
                    },
                  ),
                ],
              ),
            ],

            if (_model3dFile != null) ...[
              Row(
                children: [
                  const Icon(Icons.model_training, size: 20, color: AppColors.success),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _model3dFile!.path.split('/').last,
                      style: const TextStyle(color: AppColors.textSecondary),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 20, color: AppColors.error),
                    onPressed: () {
                      setState(() => _model3dFile = null);
                    },
                  ),
                ],
              ),
            ],

            ElevatedButton.icon(
              onPressed: _pickGroupModel3d,
              icon: const Icon(Icons.add),
              label: const Text('Upload 3D Model'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accent,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
        ),
        ElevatedButton(
          onPressed: _saveGroup,
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.accent),
          child: const Text('Save All'),
        ),
      ],
    );
  }

  Widget _buildSizeRow(Map<String, dynamic> row) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Row(
          children: [
            Checkbox(
              value: row['checked'],
              onChanged: (val) {
                setState(() => row['checked'] = val ?? false);
              },
            ),
            Expanded(
              child: Text(row['label'], style: const TextStyle(color: AppColors.textPrimary)),
            ),
            SizedBox(
              width: 100,
              child: TextFormField(
                initialValue: row['quantiteStock'].toString(),
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Stock', border: OutlineInputBorder()),
                onChanged: (val) => row['quantiteStock'] = int.tryParse(val) ?? 0,
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              width: 100,
              child: TextFormField(
                initialValue: row['prix'].toString(),
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Price', border: OutlineInputBorder()),
                onChanged: (val) => row['prix'] = double.tryParse(val) ?? 0,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveGroup() async {
    try {
      final activeRows = _rows.where((r) => r['checked'] == true).toList();
      for (final row in activeRows) {
        final variationId = row['variationId'];
        if (variationId != null) {
          await AdminCatalogService.updateVariation(
            variationId,
            couleurId: widget.group['couleurId'],
            tailleId: row['tailleId'],
            prix: row['prix'],
            quantiteStock: row['quantiteStock'],
            existingImageUrls: _existingImageUrls,
            images: _newImageFiles,
            model3d: _model3dFile,
          );
        } else {
          await AdminCatalogService.createVariation(
            widget.articleId,
            couleurId: widget.group['couleurId'],
            tailleId: row['tailleId'],
            prix: row['prix'],
            quantiteStock: row['quantiteStock'],
            existingImageUrls: _existingImageUrls,
            images: _newImageFiles,
            model3d: _model3dFile,
          );
        }
      }
      // Delete unchecked variations that existed
      final toDelete = _rows.where((r) => r['checked'] == false && r['variationId'] != null).toList();
      for (final row in toDelete) {
        await AdminCatalogService.deleteVariation(row['variationId']);
      }
      widget.onSubmit();
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Failed to save group: $e')));
      }
    }
  }
}