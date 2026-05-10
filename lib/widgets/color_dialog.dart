import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/models/color_model.dart';

class ColorDialog extends StatefulWidget {
  final ColorModel? initialColor;
  final Function(String nom, String codeHex) onSubmit;

  const ColorDialog({
    super.key,
    this.initialColor,
    required this.onSubmit,
  });

  @override
  State<ColorDialog> createState() => _ColorDialogState();
}

class _ColorDialogState extends State<ColorDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _hexController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.initialColor != null) {
      _nameController.text = widget.initialColor!.nom;
      _hexController.text = widget.initialColor!.codeHex;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.surface,
      title: Text(
        widget.initialColor == null ? 'Add Color' : 'Edit Color',
        style: const TextStyle(color: AppColors.textPrimary),
      ),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _nameController,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: const InputDecoration(
                labelText: 'Color Name *',
                labelStyle: TextStyle(color: AppColors.textSecondary),
                border: OutlineInputBorder(),
              ),
              validator: (v) => v == null || v.isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _hexController,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: const InputDecoration(
                labelText: 'Hex Color (e.g., #FF0000) *',
                labelStyle: TextStyle(color: AppColors.textSecondary),
                border: OutlineInputBorder(),
              ),
              validator: (v) {
                if (v == null || v.isEmpty) return 'Required';
                if (!RegExp(r'^#[0-9A-F]{6}$', caseSensitive: false).hasMatch(v)) {
                  return 'Invalid hex format';
                }
                return null;
              },
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
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              widget.onSubmit(_nameController.text.trim(), _hexController.text.trim().toUpperCase());
            }
          },
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.accent),
          child: Text(widget.initialColor == null ? 'Create' : 'Update'),
        ),
      ],
    );
  }
}