import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import '../core/api/api_client.dart';
import '../providers/cart_provider.dart';
import '../core/models/product_model.dart';

class ProductDetailsPage extends StatefulWidget {
  final int productId;
  const ProductDetailsPage({super.key, required this.productId});

  @override
  State<ProductDetailsPage> createState() => _ProductDetailsPageState();
}

class _ProductDetailsPageState extends State<ProductDetailsPage> {
  Map<String, dynamic>? _article;
  List<dynamic> _reviews = [];
  List<dynamic> _related = [];
  List<dynamic> _variations = [];
  List<Map<String, dynamic>> _colors = [];
  List<dynamic> _sizeOptions = [];

  bool _loading = true;
  String _error = '';

  String? _selectedColorId;
  String? _selectedSizeId;
  Map<String, dynamic>? _selectedVariation;

  bool _isFavorite = false;
  bool _addingToCart = false;
  int _qty = 1;
  String _tab = 'details';

  double _rating = 5;
  final TextEditingController _reviewCtrl = TextEditingController();

  List<String> _gallery = [];
  int _currentImageIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _reviewCtrl.dispose();
    super.dispose();
  }

  String _getFullImageUrl(String? url) {
    if (url == null || url.isEmpty) return '';
    if (url.startsWith('http')) return url;
    if (url.startsWith('/api')) return '${ApiClient.baseUrl}$url';
    return '${ApiClient.baseUrl}/$url';
  }

  Future<void> _loadData() async {
    try {
      final resList = await Future.wait([
        ApiClient.get('/api/articles/${widget.productId}', auth: false),
        ApiClient.get('/api/articles/${widget.productId}/reviews', auth: false),
        ApiClient.get('/api/articles', auth: false),
      ]);

      final detailRes = resList[0];
      final reviewsRes = resList[1];
      final allRes = resList[2];

      if (detailRes.statusCode != 200) throw Exception('Cannot load product');

      _article = jsonDecode(detailRes.body);
      _variations = _article?['variations'] ?? _article?['variationDtos'] ?? _article?['variantes'] ?? [];

      if (reviewsRes.statusCode == 200) {
        final rData = jsonDecode(reviewsRes.body);
        _reviews = rData is List ? rData : [];
      }

      if (allRes.statusCode == 200) {
        final aData = jsonDecode(allRes.body);
        if (aData is List) {
          _related = aData
              .where((a) => a['id'] != widget.productId && a['actif'] != false)
              .where((a) => _article?['categorieId'] == null || a['categorieId'] == _article?['categorieId'])
              .take(4)
              .toList();
        }
      }

      _parseColorsAndSizes();

    } catch (e) {
      _error = 'Product not found or error loading data';
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _parseColorsAndSizes() {
    if (_article == null) return;

    final Map<String, Map<String, dynamic>> colorMap = {};
    for (var v in _variations) {
      final colorId = (v['couleurId'] ?? v['colorId'] ?? v['couleur']?['id'])?.toString();
      if (colorId == null) continue;

      if (!colorMap.containsKey(colorId)) {
        colorMap[colorId] = {
          'couleurId': colorId,
          'couleurNom': v['couleurNom'] ?? v['colorName'] ?? v['couleur']?['nom'] ?? 'Color',
          'couleurCodeHex': v['couleurCodeHex'] ?? v['colorCodeHex'] ?? v['couleur']?['codeHex'] ?? '#DDDDDD',
          'totalStock': 0,
        };
      }
      colorMap[colorId]!['totalStock'] += (v['quantiteStock'] ?? v['stock'] ?? 0) as int;
    }

    _colors = colorMap.values.toList();
    if (_colors.isNotEmpty && _selectedColorId == null) {
      _selectedColorId = _colors.firstWhere((c) => c['totalStock'] > 0, orElse: () => _colors.first)['couleurId'];
    }

    _updateSizeOptions();
    _updateGallery();
  }

  void _updateSizeOptions() {
    if (_selectedColorId == null) return;

    _sizeOptions = _variations.where((v) {
      final cid = (v['couleurId'] ?? v['colorId'] ?? v['couleur']?['id'])?.toString();
      return cid == _selectedColorId;
    }).toList();

    _sizeOptions.sort((a, b) {
      final sa = (a['taillePointure'] ?? a['size']?['pointure'] ?? '').toString();
      final sb = (b['taillePointure'] ?? b['size']?['pointure'] ?? '').toString();
      return sa.compareTo(sb);
    });

    if (_sizeOptions.isNotEmpty) {
      final firstAvail = _sizeOptions.firstWhere((v) => (v['quantiteStock'] ?? v['stock'] ?? 0) > 0, orElse: () => _sizeOptions.first);
      _selectedSizeId = (firstAvail['tailleId'] ?? firstAvail['sizeId'] ?? firstAvail['taille']?['id'])?.toString();
      _selectedVariation = firstAvail;
    } else {
      _selectedSizeId = null;
      _selectedVariation = null;
    }
    _qty = 1;
    _updateGallery();
  }

  void _updateGallery() {
    List<String> imgs = [];
    if (_selectedVariation != null) imgs = _extractImages(_selectedVariation!);
    if (imgs.isEmpty && _article != null) imgs = _extractImages(_article!);
    setState(() {
      _gallery = imgs.toSet().toList();
      _currentImageIndex = 0;
    });
  }

  List<String> _extractImages(Map<String, dynamic> obj) {
    final List<String> urls = [];

    // Collect all possible image fields
    final imageFields = ['imageUrl', 'imageUrl2', 'imageUrl3', 'imageUrl4', 'previewImage', 'image'];

    for (var field in imageFields) {
      final value = obj[field];
      if (value != null && value.toString().isNotEmpty) {
        urls.add(value.toString());
      }
    }

    // Also check variations for imageUrls
    if (obj.containsKey('imageUrls') && obj['imageUrls'] is List) {
      for (var url in obj['imageUrls']) {
        if (url != null && url.toString().isNotEmpty) {
          urls.add(url.toString());
        }
      }
    }

    return urls;
  }

  Color _hexToColor(String hex) {
    hex = hex.replaceAll('#', '');
    if (hex.length == 6) hex = 'FF$hex';
    return Color(int.tryParse(hex, radix: 16) ?? 0xFFDDDDDD);
  }

  bool _isSaleActive(Map<String, dynamic> p) {
    final price = double.tryParse(p['prix']?.toString() ?? '0') ?? 0;
    final salePrice = double.tryParse(p['salePrice']?.toString() ?? '0');
    return salePrice != null && salePrice < price;
  }

  double _getPrice() {
    if (_article == null) return 0.0;
    if (_isSaleActive(_article!)) return double.tryParse(_article!['salePrice'].toString()) ?? 0;
    if (_selectedVariation != null) return double.tryParse((_selectedVariation!['prix'] ?? _article!['prix']).toString()) ?? 0;
    return double.tryParse(_article!['prix']?.toString() ?? '0') ?? 0;
  }

  int _getRemainingStock() {
    if (_selectedVariation == null) return 0;

    final stockVal = _selectedVariation!['quantiteStock'] ?? _selectedVariation!['stock'] ?? 0;
    int rawStock = int.tryParse(stockVal.toString()) ?? 0;

    final cartItems = context.read<CartProvider>().items;

    int inCart = 0;
    for (var item in cartItems) {
      if (item.id.toString() == _article?['id']?.toString()) {
        inCart += item.quantity;
      }
    }

    return max(0, rawStock - inCart);
  }

  Future<void> _handleAddToCart() async {
    if (_selectedVariation == null || _article == null) return;

    final stock = _getRemainingStock();
    if (stock <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Sold out!')));
      return;
    }

    setState(() => _addingToCart = true);

    final productModel = ProductModel(
      id: _article!['id'] ?? 0,
      name: _article!['nom'] ?? 'Unknown',
      description: _article!['description'] ?? '',
      price: _getPrice(),
      imageUrl: _article!['imageUrl'] ?? _article!['previewImage'],
      category: _article!['categorieNom'],
    );

    final int variationId = int.tryParse(_selectedVariation!['id']?.toString() ?? '0') ?? 0;
    final colorName = _selectedVariation!['couleurNom'] ?? _selectedVariation!['couleur']?['nom'] ?? 'Standard';
    final sizeName = _selectedVariation!['taillePointure'] ?? _selectedVariation!['taille']?['pointure'] ?? 'Standard';

    context.read<CartProvider>().addToCart(
      productModel,
      qty: min(_qty, stock),
      color: colorName,
      size: sizeName,
      variationId: variationId,
    );

    if (mounted) {
      setState(() {
        _addingToCart = false;
        _qty = 1;
      });
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(children: [Icon(Icons.check_circle, color: Colors.white), SizedBox(width: 10), Text('Added to cart', style: TextStyle(fontWeight: FontWeight.bold))]),
            backgroundColor: Color(0xFF1F9D55),
            behavior: SnackBarBehavior.floating,
          )
      );
    }
  }

  Future<void> _submitReview() async {
    if (_reviewCtrl.text.isEmpty) return;
    try {
      await ApiClient.post('/api/articles/${widget.productId}/reviews', {
        'rating': _rating,
        'comment': _reviewCtrl.text,
      });
      _reviewCtrl.clear();
      _rating = 5;
      await _loadData();
      setState(() => _tab = 'reviews');
    } catch (_) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to submit review')));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Scaffold(backgroundColor: Colors.white, body: Center(child: CircularProgressIndicator(color: Colors.black)));
    if (_article == null || _error.isNotEmpty) return Scaffold(appBar: AppBar(), body: const Center(child: Text('Product not found')));

    final onSale = _isSaleActive(_article!);
    final price = _getPrice();
    final oldPrice = double.tryParse(_article!['prix']?.toString() ?? '0') ?? 0;
    final stock = _getRemainingStock();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Stack(
        children: [
          Positioned(
            top: 0, left: 0, right: 0,
            height: MediaQuery.of(context).size.height * 0.52,
            child: Stack(
              children: [
                Container(color: const Color(0xFFF3F3F3)),
                if (_gallery.isNotEmpty)
                  PageView.builder(
                    itemCount: _gallery.length,
                    onPageChanged: (idx) => setState(() => _currentImageIndex = idx),
                    itemBuilder: (ctx, idx) => CachedNetworkImage(
                      imageUrl: _getFullImageUrl(_gallery[idx]),
                      fit: BoxFit.cover,
                      width: double.infinity,
                      placeholder: (context, url) => const Center(child: CircularProgressIndicator()),
                      errorWidget: (context, url, error) => const Center(child: Icon(Icons.broken_image, size: 50, color: Colors.grey)),
                    ),
                  )
                else
                  const Center(child: Icon(Icons.image, size: 60, color: Colors.grey)),

                Positioned(
                  top: MediaQuery.of(context).padding.top + 10,
                  left: 16,
                  right: 16,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildGlassBtn(Icons.arrow_back_ios_new, () => Navigator.pop(context)),
                      _buildGlassBtn(_isFavorite ? Icons.favorite : Icons.favorite_border, () => setState(() => _isFavorite = !_isFavorite), color: _isFavorite ? const Color(0xFFFF2EA6) : Colors.black),
                    ],
                  ),
                ),

                if (_gallery.length > 1)
                  Positioned(
                    bottom: 40,
                    left: 0,
                    right: 0,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: _gallery.asMap().entries.map((e) => AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: _currentImageIndex == e.key ? 24 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                            color: _currentImageIndex == e.key ? Colors.black : Colors.black38,
                            borderRadius: BorderRadius.circular(10)
                        ),
                      )).toList(),
                    ),
                  ),
              ],
            ),
          ),

          Positioned(
            top: MediaQuery.of(context).size.height * 0.45,
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
                boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 20, offset: Offset(0, -5))],
              ),
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 32, 24, 120),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${_article!['categorieNom'] ?? 'CATEGORY'} • ${_article!['marque'] ?? 'EMIRIO'}',
                          style: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 13, fontWeight: FontWeight.w700, letterSpacing: 1.2)
                      ),
                      const SizedBox(height: 8),

                      Text(_article!['nom'] ?? '',
                          style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, height: 1.1, letterSpacing: -0.5)
                      ),

                      const SizedBox(height: 18),
                      // FIX: Wrap price row to prevent overflow
                      Wrap(
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 12,
                        runSpacing: 8,
                        children: [
                          Text('${price.toStringAsFixed(3)} TND',
                              style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: Colors.black)
                          ),
                          if (onSale)
                            Text('${oldPrice.toStringAsFixed(3)} TND',
                                style: const TextStyle(color: Color(0xFF9CA3AF), decoration: TextDecoration.lineThrough, fontSize: 20, fontWeight: FontWeight.w800)
                            ),
                          if (onSale)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(color: const Color(0xFFFEE2E2), borderRadius: BorderRadius.circular(20)),
                              child: const Text('SALE', style: TextStyle(color: Color(0xFFDC2626), fontSize: 13, fontWeight: FontWeight.w900)),
                            ),
                        ],
                      ),

                      const Padding(padding: EdgeInsets.symmetric(vertical: 24), child: Divider(height: 1, color: Color(0xFFECECEC))),

                      if (_colors.isNotEmpty) ...[
                        const Text('Color', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Color(0xFF555555))),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          children: _colors.map((c) {
                            final active = _selectedColorId == c['couleurId'];
                            final soldOut = c['totalStock'] <= 0;
                            return GestureDetector(
                              onTap: soldOut ? null : () {
                                setState(() => _selectedColorId = c['couleurId']);
                                _updateSizeOptions();
                              },
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                decoration: BoxDecoration(
                                  color: active ? Colors.black : Colors.white,
                                  border: Border.all(color: active ? Colors.black : const Color(0xFFDDDDDD)),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                        width: 18,
                                        height: 18,
                                        decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: _hexToColor(c['couleurCodeHex']),
                                            border: Border.all(color: Colors.black12)
                                        )
                                    ),
                                    const SizedBox(width: 8),
                                    Text(c['couleurNom'],
                                        style: TextStyle(
                                            color: active ? Colors.white : (soldOut ? Colors.grey : Colors.black),
                                            fontWeight: FontWeight.w700,
                                            fontSize: 14
                                        )
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 24),
                      ],

                      if (_sizeOptions.isNotEmpty) ...[
                        const Text('Size', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Color(0xFF555555))),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: _sizeOptions.map((v) {
                            final sizeId = (v['tailleId'] ?? v['sizeId'] ?? v['taille']?['id'])?.toString();
                            final active = _selectedSizeId == sizeId;
                            final sStock = (v['quantiteStock'] ?? v['stock'] ?? 0) as int;
                            final soldOut = sStock <= 0;

                            return GestureDetector(
                              onTap: () {
                                setState(() {
                                  _selectedSizeId = sizeId;
                                  _selectedVariation = v;
                                  _qty = 1;
                                  _updateGallery();
                                });
                              },
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                width: 58,
                                height: 58,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: active ? Colors.black : Colors.white,
                                  border: Border.all(color: active ? Colors.black : (soldOut ? const Color(0xFFEEEEEE) : const Color(0xFFDDDDDD))),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: Text(
                                    (v['taillePointure'] ?? v['size']?['pointure'] ?? '').toString(),
                                    style: TextStyle(
                                        color: active ? Colors.white : (soldOut ? Colors.grey : Colors.black),
                                        fontWeight: FontWeight.w800,
                                        fontSize: 15
                                    )
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 16),
                      ],

                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                            color: stock > 0 ? const Color(0xFFF0FDF4) : const Color(0xFFFEF2F2),
                            border: Border.all(color: stock > 0 ? const Color(0xFFBBF7D0) : const Color(0xFFFECACA)),
                            borderRadius: BorderRadius.circular(14)
                        ),
                        child: Row(
                          children: [
                            Icon(stock > 0 ? Icons.check_circle : Icons.error, color: stock > 0 ? const Color(0xFF166534) : const Color(0xFF991B1B), size: 20),
                            const SizedBox(width: 10),
                            Expanded(child: Text(stock > 0 ? '$stock items left in stock' : 'Sold out for this variant',
                                style: TextStyle(color: stock > 0 ? const Color(0xFF166534) : const Color(0xFF991B1B), fontWeight: FontWeight.w700)
                            )),
                          ],
                        ),
                      ),

                      const Padding(padding: EdgeInsets.symmetric(vertical: 24), child: Divider(height: 1, color: Color(0xFFECECEC))),

                      // Tabs - FIX for overflow
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            _buildTabBtn('details', 'Details'),
                            _buildTabBtn('reviews', 'Reviews (${_reviews.length})'),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      if (_tab == 'details') ...[
                        Text(_article!['description'] ?? 'No description available.',
                            style: const TextStyle(color: Color(0xFF6B7280), fontSize: 15, height: 1.6)
                        ),
                      ] else ...[
                        if (_reviews.isEmpty)
                          const Text('No reviews yet.', style: TextStyle(color: Colors.grey)),
                        ..._reviews.map((r) => Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(border: Border.all(color: const Color(0xFFECECEC)), borderRadius: BorderRadius.circular(16)),
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Row(children: List.generate(5, (i) => Icon(i < (r['rating'] ?? 0) ? Icons.star : Icons.star_border, size: 16, color: const Color(0xFFF4B400)))),
                            const SizedBox(height: 8),
                            Text(r['userFullName'] ?? 'User', style: const TextStyle(fontWeight: FontWeight.bold)),
                            const SizedBox(height: 4),
                            Text(r['comment'] ?? '', style: const TextStyle(color: Color(0xFF6B7280))),
                          ]),
                        )).toList(),

                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(color: const Color(0xFFFAFAFA), borderRadius: BorderRadius.circular(16)),
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            const Text('Write a Review', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                            const SizedBox(height: 12),
                            Row(children: List.generate(5, (i) => GestureDetector(
                                onTap: () => setState(() => _rating = i + 1.0),
                                child: Icon(i < _rating ? Icons.star : Icons.star_border, size: 28, color: const Color(0xFFF4B400))
                            ))),
                            const SizedBox(height: 12),
                            TextField(
                                controller: _reviewCtrl,
                                maxLines: 3,
                                decoration: const InputDecoration(
                                    hintText: 'Your comment...',
                                    border: OutlineInputBorder(),
                                    filled: true,
                                    fillColor: Colors.white
                                )
                            ),
                            const SizedBox(height: 12),
                            ElevatedButton(
                                onPressed: _submitReview,
                                style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.black,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30))
                                ),
                                child: const Text('Submit')
                            ),
                          ]),
                        ),
                      ],

                      if (_related.isNotEmpty) ...[
                        const Padding(padding: EdgeInsets.symmetric(vertical: 24), child: Divider(height: 1, color: Color(0xFFECECEC))),
                        const Text('YOU MIGHT ALSO LIKE', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, letterSpacing: -0.5)),
                        const SizedBox(height: 16),
                        SizedBox(
                          height: 220,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: _related.length,
                            itemBuilder: (ctx, i) {
                              final p = _related[i];
                              return GestureDetector(
                                onTap: () => Navigator.pushReplacementNamed(context, '/product/${p['id']}'),
                                child: Container(
                                  width: 140,
                                  margin: const EdgeInsets.only(right: 16),
                                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                    Expanded(
                                      child: Container(
                                        decoration: BoxDecoration(color: const Color(0xFFF3F4F6), borderRadius: BorderRadius.circular(16)),
                                        child: ClipRRect(
                                            borderRadius: BorderRadius.circular(16),
                                            child: p['imageUrl'] != null
                                                ? CachedNetworkImage(
                                              imageUrl: _getFullImageUrl(p['imageUrl']),
                                              fit: BoxFit.cover,
                                              width: double.infinity,
                                              errorWidget: (_, __, ___) => const Icon(Icons.image, color: Colors.grey),
                                            )
                                                : const Icon(Icons.image, color: Colors.grey)
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(p['nom'] ?? '', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                    Text('${p['prix']} TND', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14)),
                                  ]),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),

      bottomNavigationBar: Container(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom + 16, top: 16, left: 24, right: 24),
        decoration: BoxDecoration(
            color: Colors.white,
            border: const Border(top: BorderSide(color: Color(0xFFEEEEEE))),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -5))]
        ),
        child: Row(
          children: [
            Container(
              height: 58,
              decoration: BoxDecoration(color: const Color(0xFFF3F4F6), borderRadius: BorderRadius.circular(30)),
              child: Row(
                children: [
                  IconButton(icon: const Icon(Icons.remove), onPressed: () => setState(() => _qty = max(1, _qty - 1))),
                  Text('$_qty', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                  IconButton(icon: const Icon(Icons.add), onPressed: () => setState(() => _qty = min(_qty + 1, stock))),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: SizedBox(
                height: 58,
                child: ElevatedButton(
                  onPressed: (_addingToCart || stock <= 0) ? null : _handleAddToCart,
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                      elevation: 10,
                      shadowColor: Colors.black45
                  ),
                  child: _addingToCart
                      ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : Text(stock <= 0 ? 'Sold Out' : 'Add to Cart', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabBtn(String id, String label) {
    final active = _tab == id;
    return GestureDetector(
      onTap: () => setState(() => _tab = id),
      child: Container(
        padding: const EdgeInsets.only(bottom: 8, right: 24),
        decoration: BoxDecoration(border: Border(bottom: BorderSide(color: active ? Colors.black : Colors.transparent, width: 2))),
        child: Text(label, style: TextStyle(color: active ? Colors.black : const Color(0xFF9CA3AF), fontWeight: FontWeight.bold, fontSize: 16)),
      ),
    );
  }

  Widget _buildGlassBtn(IconData icon, VoidCallback onTap, {Color color = Colors.black}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.9),
              shape: BoxShape.circle,
              boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10)]
          ),
          child: Icon(icon, color: color, size: 22)
      ),
    );
  }
}