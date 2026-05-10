import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../core/models/product_model.dart';
import '../core/api/api_client.dart';

class ProductCard extends StatefulWidget {
  final ProductModel product;
  const ProductCard({super.key, required this.product});

  @override
  State<ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends State<ProductCard> {
  bool _isFavorite = false;

  bool get _onSale => widget.product.price > 50 && widget.product.id % 2 == 0;
  double get _salePrice => widget.product.price * 0.8;
  int get _discount => 20;

  @override
  Widget build(BuildContext context) {
    final imgUrl = widget.product.imageUrl != null
        ? '${ApiClient.baseUrl}${widget.product.imageUrl}'
        : null;

    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, '/product/${widget.product.id}'),
      child: Container(
        width: double.infinity, // Set explicit width
        constraints: const BoxConstraints(
          minHeight: 380,
          maxHeight: 420,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(26),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.07),
              blurRadius: 34,
              offset: const Offset(0, 16),
            )
          ],
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min, // Use min to prevent infinite height
          children: [
            // --- IMAGE WRAPPER ---
            SizedBox(
              height: 180, // Fixed height instead of Expanded
              width: double.infinity,
              child: Stack(
                children: [
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF3F4F6),
                      borderRadius: BorderRadius.circular(22),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(22),
                      child: imgUrl != null
                          ? CachedNetworkImage(
                        imageUrl: imgUrl,
                        fit: BoxFit.cover,
                        width: double.infinity,
                        height: 180,
                        placeholder: (_, __) => const Center(
                          child: CircularProgressIndicator(color: Colors.grey, strokeWidth: 2),
                        ),
                        errorWidget: (_, __, ___) => const Center(
                          child: Icon(Icons.image, color: Colors.grey, size: 40),
                        ),
                      )
                          : const Center(
                        child: Text('No image', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ),

                  // --- SALE RIBBON ---
                  if (_onSale)
                    Positioned(
                      top: 14,
                      left: 14,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFF4D4F),
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: Text(
                          'SALE -$_discount%',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),

                  // --- FAVORITE BUTTON ---
                  Positioned(
                    top: 14,
                    right: 14,
                    child: GestureDetector(
                      onTap: () => setState(() => _isFavorite = !_isFavorite),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: _isFavorite ? Colors.black : Colors.white.withOpacity(0.96),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.12),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            )
                          ],
                        ),
                        child: Icon(
                          _isFavorite ? Icons.favorite : Icons.favorite_border,
                          color: _isFavorite ? Colors.white : Colors.black,
                          size: 18,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // --- PRODUCT INFO AREA ---
            const SizedBox(height: 12),

            Text(
              widget.product.name,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.3,
              ),
            ),

            const SizedBox(height: 4),

            Text(
              widget.product.category ?? 'EMIRIO',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Colors.grey, fontSize: 12),
            ),

            // --- MINI COUNTDOWN ---
            if (_onSale)
              Container(
                margin: const EdgeInsets.only(top: 8),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF3F3),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: const Text(
                  'Ends soon',
                  style: TextStyle(
                    color: Color(0xFFC62828),
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),

            const SizedBox(height: 8),

            // --- PRICE ROW (Fixed) ---
            Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 8,
              children: [
                Text(
                  '${(_onSale ? _salePrice : widget.product.price).toStringAsFixed(3)} TND',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: Colors.black,
                  ),
                ),
                if (_onSale)
                  Text(
                    '${widget.product.price.toStringAsFixed(3)} TND',
                    style: const TextStyle(
                      color: Colors.grey,
                      decoration: TextDecoration.lineThrough,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}