import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/models/variation_model.dart';

class StockUpdateDialog extends StatefulWidget {
  final VariationModel variation;
  final bool increment;
  final Function(int) onConfirm;

  const StockUpdateDialog({
    super.key,
    required this.variation,
    required this.increment,
    required this.onConfirm,
  });

  @override
  State<StockUpdateDialog> createState() => _StockUpdateDialogState();
}

class _StockUpdateDialogState extends State<StockUpdateDialog> {
  final TextEditingController _quantityController = TextEditingController(text: '1');
  int _quantity = 1;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.surface,
      title: Text(
        '${widget.increment ? 'Restock' : 'Sell'} ${widget.variation.couleurNom}',
        style: const TextStyle(color: AppColors.textPrimary),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Current stock: ${widget.variation.quantiteStock}',
            style: const TextStyle(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _quantityController,
            keyboardType: TextInputType.number,
            style: const TextStyle(color: AppColors.textPrimary),
            decoration: const InputDecoration(
              labelText: 'Quantity',
              labelStyle: TextStyle(color: AppColors.textSecondary),
              border: OutlineInputBorder(),
            ),
            onChanged: (value) {
              _quantity = int.tryParse(value) ?? 1;
              if (_quantity < 1) _quantity = 1;
            },
          ),
          if (!widget.increment && _quantity > widget.variation.quantiteStock)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                'Not enough stock! Available: ${widget.variation.quantiteStock}',
                style: const TextStyle(color: AppColors.error, fontSize: 12),
              ),
            ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
        ),
        ElevatedButton(
          onPressed: () {
            if (!widget.increment && _quantity > widget.variation.quantiteStock) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Insufficient stock!')),
              );
              return;
            }
            Navigator.pop(context);
            widget.onConfirm(_quantity);
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: widget.increment ? AppColors.success : AppColors.error,
          ),
          child: Text(widget.increment ? 'Restock' : 'Sell'),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _quantityController.dispose();
    super.dispose();
  }
}