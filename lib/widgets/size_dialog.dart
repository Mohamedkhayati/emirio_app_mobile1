import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/models/size_model.dart';

class SizeDialog extends StatefulWidget {
  final SizeModel? initialSize;
  final Function(String pointure) onSubmit;

  const SizeDialog({
    super.key,
    this.initialSize,
    required this.onSubmit,
  });

  @override
  State<SizeDialog> createState() => _SizeDialogState();
}

class _SizeDialogState extends State<SizeDialog> {
  final _formKey = GlobalKey<FormState>();
  final _pointureController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.initialSize != null) {
      _pointureController.text = widget.initialSize!.pointure;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.surface,
      title: Text(
        widget.initialSize == null ? 'Add Size' : 'Edit Size',
        style: const TextStyle(color: AppColors.textPrimary),
      ),
      content: Form(
        key: _formKey,
        child: TextFormField(
          controller: _pointureController,
          style: const TextStyle(color: AppColors.textPrimary),
          decoration: const InputDecoration(
            labelText: 'Size (e.g., 39, 40, S, M, L) *',
            labelStyle: TextStyle(color: AppColors.textSecondary),
            border: OutlineInputBorder(),
          ),
          validator: (v) => v == null || v.isEmpty ? 'Required' : null,
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
              widget.onSubmit(_pointureController.text.trim());
            }
          },
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.accent),
          child: Text(widget.initialSize == null ? 'Create' : 'Update'),
        ),
      ],
    );
  }
}