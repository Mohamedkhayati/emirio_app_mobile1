import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/models/variation_model.dart';
import '../../core/api/api_client.dart';

class VariationGroupCard extends StatelessWidget {
  final Map<String, dynamic> group;
  final bool isAccessory;
  final bool canEdit;
  final VoidCallback onEditGroup;
  final Function(VariationModel) onEditVariation;
  final Function(VariationModel)? onDeleteVariation;
  final Function(VariationModel) onRestock;
  final Function(VariationModel) onSell;
  final VoidCallback? onDeleteGroup;

  const VariationGroupCard({
    super.key,
    required this.group,
    required this.isAccessory,
    required this.canEdit,
    required this.onEditGroup,
    required this.onEditVariation,
    this.onDeleteVariation,
    required this.onRestock,
    required this.onSell,
    this.onDeleteGroup,
  });

  String _getFullImageUrl(String url) {
    if (url == null || url.isEmpty) return '';
    if (url.startsWith('http')) return url;
    if (url.startsWith('/api')) return '${ApiClient.baseUrl}$url';
    return '${ApiClient.baseUrl}/$url';
  }

  @override
  Widget build(BuildContext context) {
    final items = group['items'] as List<VariationModel>;
    final colorHex = group['couleurCodeHex'] as String?;
    final imageUrls = group['imageUrls'] as List<String>?;

    Color? getColor() {
      if (colorHex == null) return null;
      try {
        return Color(int.parse(colorHex.substring(1), radix: 16) + 0xFF000000);
      } catch (e) {
        return null;
      }
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: AppColors.card,
      child: ExpansionTile(
        backgroundColor: AppColors.card,
        collapsedBackgroundColor: AppColors.card,
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: getColor() ?? AppColors.accent,
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.palette, color: Colors.white, size: 20),
        ),
        title: Text(
          group['couleurNom'] ?? 'Unknown Color',
          style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary),
        ),
        subtitle: isAccessory
            ? Text('Stock: ${group['totalStock']}', style: const TextStyle(color: AppColors.textSecondary))
            : Text('${items.length} sizes • Total stock: ${group['totalStock']}',
            style: const TextStyle(color: AppColors.textSecondary)),
        trailing: canEdit
            ? Row(mainAxisSize: MainAxisSize.min, children: [
          if (onDeleteGroup != null)
            IconButton(
              icon: const Icon(Icons.delete, size: 20, color: AppColors.error),
              onPressed: onDeleteGroup,
            ),
          IconButton(
            icon: const Icon(Icons.edit, size: 20),
            onPressed: onEditGroup,
            color: AppColors.textSecondary,
          ),
        ])
            : null,
        children: [
          // Image gallery
          if (imageUrls != null && imageUrls.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(12),
              child: SizedBox(
                height: 100,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: imageUrls.length,
                  itemBuilder: (_, i) {
                    final url = imageUrls[i];
                    final fullUrl = _getFullImageUrl(url);
                    print('🖼️ Loading variation image: $fullUrl');
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          fullUrl,
                          width: 100,
                          height: 100,
                          fit: BoxFit.cover,
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return Container(
                              width: 100,
                              height: 100,
                              color: AppColors.border,
                              child: const Center(
                                child: SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                ),
                              ),
                            );
                          },
                          errorBuilder: (_, __, ___) {
                            print('❌ Failed to load image: $fullUrl');
                            return Container(
                              width: 100,
                              height: 100,
                              color: AppColors.border,
                              child: const Icon(Icons.broken_image, color: AppColors.textSecondary),
                            );
                          },
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ...items.map((v) => _buildVariationTile(v)),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildVariationTile(VariationModel variation) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: AppColors.border.withOpacity(0.3))),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (!isAccessory && variation.taillePointure != null)
                  Text(
                    'Size ${variation.taillePointure}',
                    style: const TextStyle(fontWeight: FontWeight.w500, color: AppColors.textPrimary),
                  ),
                Text(
                  'Stock: ${variation.quantiteStock}',
                  style: TextStyle(
                    color: variation.quantiteStock <= 0 ? AppColors.error : AppColors.textSecondary,
                    fontSize: 12,
                  ),
                  softWrap: true,
                ),
              ],
            ),
          ),
          Container(
            margin: const EdgeInsets.only(right: 16),
            child: Text(
              '${variation.prix.toStringAsFixed(2)} DT',
              style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary),
            ),
          ),
          if (canEdit) ...[
            IconButton(
              icon: const Icon(Icons.edit, size: 18),
              onPressed: () => onEditVariation(variation),
              color: AppColors.textSecondary,
            ),
            if (onDeleteVariation != null)
              IconButton(
                icon: const Icon(Icons.delete, size: 18),
                onPressed: () => onDeleteVariation!(variation),
                color: AppColors.error,
              ),
          ],
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.remove_circle_outline, size: 22),
                onPressed: variation.quantiteStock > 0 ? () => onSell(variation) : null,
                color: variation.quantiteStock > 0 ? AppColors.error : AppColors.textSecondary,
              ),
              IconButton(
                icon: const Icon(Icons.add_circle_outline, size: 22),
                onPressed: () => onRestock(variation),
                color: AppColors.success,
              ),
            ],
          ),
        ],
      ),
    );
  }
}