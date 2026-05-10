import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../core/api/api_client.dart';
import '../widgets/navbar.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<Map<String, dynamic>> _articles = [];
  List<Map<String, dynamic>> _flatCategories = [];

  bool _loading = true;
  String _error = '';
  String _searchQuery = '';
  int? _selectedCategoryId;

  late Timer _tickTimer;
  DateTime _nowTick = DateTime.now();
  int _currentHeroIndex = 0;

  @override
  void initState() {
    super.initState();
    _tickTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) setState(() => _nowTick = DateTime.now());
    });
    _loadData();
  }

  @override
  void dispose() {
    _tickTimer.cancel();
    super.dispose();
  }

  // Helper method to get full image URL
  String _getFullImageUrl(String? url) {
    if (url == null || url.isEmpty) return '';
    if (url.startsWith('http')) return url;
    if (url.startsWith('/api')) return '${ApiClient.baseUrl}$url';
    return '${ApiClient.baseUrl}/$url';
  }

  Future<void> _loadData() async {
    try {
      final resArticles = await ApiClient.get('/api/articles', auth: false);
      final resCategories = await ApiClient.get('/api/categories', auth: false);

      if (resArticles.statusCode == 200) {
        final List<dynamic> data = jsonDecode(resArticles.body);
        _articles = data.cast<Map<String, dynamic>>().where((a) => a['actif'] != false).toList();
      }

      if (resCategories.statusCode == 200) {
        final Map<String, dynamic> catData = jsonDecode(resCategories.body);
        _flatCategories = _flattenCategories(catData);
      }
    } catch (e) {
      _error = 'Failed to load catalog';
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<Map<String, dynamic>> _flattenCategories(Map<String, dynamic> data) {
    final List<Map<String, dynamic>> flat = [];
    if (data['chaussures'] != null) {
      (data['chaussures'] as Map).forEach((k, v) {
        flat.add({'id': v['id'], 'nom': v['nom']});
      });
    }
    if (data['accessoires'] is List) {
      for (var a in data['accessoires']) {
        flat.add({'id': a['id'], 'nom': a['nom']});
      }
    }
    return flat;
  }

  bool _isSaleActive(Map<String, dynamic> p) {
    final price = double.tryParse(p['prix']?.toString() ?? '0') ?? 0;
    final salePrice = double.tryParse(p['salePrice']?.toString() ?? '0');
    if (salePrice == null || salePrice >= price) return false;

    final start = p['saleStartAt'] != null ? DateTime.tryParse(p['saleStartAt']) : null;
    final end = p['saleEndAt'] != null ? DateTime.tryParse(p['saleEndAt']) : null;

    if (start != null && _nowTick.isBefore(start)) return false;
    if (end != null && _nowTick.isAfter(end)) return false;
    return true;
  }

  int? _getDiscountPercent(Map<String, dynamic> p) {
    if (!_isSaleActive(p)) return null;
    final price = double.tryParse(p['prix']?.toString() ?? '0') ?? 0;
    final salePrice = double.tryParse(p['salePrice']?.toString() ?? '0') ?? 0;
    if (price <= 0) return null;
    return (((price - salePrice) / price) * 100).round();
  }

  double _getDisplayPrice(Map<String, dynamic> p) {
    final price = double.tryParse(p['prix']?.toString() ?? '0') ?? 0;
    final salePrice = double.tryParse(p['salePrice']?.toString() ?? '0');
    return _isSaleActive(p) && salePrice != null ? salePrice : price;
  }

  String _formatCountdown(String? endAt) {
    if (endAt == null) return "Limited offer";
    final end = DateTime.tryParse(endAt);
    if (end == null) return "Limited offer";

    final diff = end.difference(_nowTick);
    if (diff.isNegative) return "Sale ended";

    final d = diff.inDays;
    final h = diff.inHours % 24;
    final m = diff.inMinutes % 60;
    final s = diff.inSeconds % 60;

    if (d > 0) return "${d}d ${h}h";
    if (h > 0) return "${h}h ${m}m";
    return "${m}m ${s}s";
  }

  @override
  Widget build(BuildContext context) {
    // Get screen width to adjust grid columns
    final screenWidth = MediaQuery.of(context).size.width;
    final crossAxisCount = screenWidth > 600 ? 3 : 2;

    var filtered = _articles;
    if (_selectedCategoryId != null) {
      filtered = filtered.where((a) => a['categorieId'] == _selectedCategoryId).toList();
    }
    if (_searchQuery.trim().isNotEmpty) {
      final q = _searchQuery.trim().toLowerCase();
      filtered = filtered.where((a) {
        final str = '${a['nom']} ${a['description']} ${a['marque']}'.toLowerCase();
        return str.contains(q);
      }).toList();
    }

    final saleArticles = filtered.where(_isSaleActive).toList();
    final recommended = filtered.where((a) => a['recommended'] == true).take(8).toList();
    final newArrivals = List<Map<String, dynamic>>.from(filtered)
      ..sort((a, b) => (b['id'] as int).compareTo(a['id'] as int));

    return MainScaffold(
      currentIndex: 0,
      child: _loading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFFF2EA6)))
          : SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeroSlider(filtered),

            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Align(
                alignment: Alignment.centerRight,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: TextField(
                    onChanged: (v) => setState(() => _searchQuery = v),
                    decoration: InputDecoration(
                      hintText: 'Search products',
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: const BorderSide(color: Color(0xFFDDDDDD))),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: const BorderSide(color: Color(0xFFDDDDDD))),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: const BorderSide(color: Color(0xFFFF2EA6))),
                    ),
                  ),
                ),
              ),
            ),

            if (saleArticles.isNotEmpty) _buildSection('Sale now', saleArticles.take(8).toList(), crossAxisCount),
            if (recommended.isNotEmpty) _buildSection('Best choice', recommended, crossAxisCount),

            _buildCategories(),

            if (newArrivals.isNotEmpty) _buildSection('New arrivals', newArrivals.take(8).toList(), crossAxisCount),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroSlider(List<Map<String, dynamic>> allArticles) {
    final saleItems = allArticles.where(_isSaleActive).toList();
    final heroItems = saleItems.isNotEmpty ? saleItems : allArticles;

    if (heroItems.isEmpty) return const SizedBox();

    return Stack(
      children: [
        Container(
          height: 460,
          width: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF111111), Color(0xFF1B1B1B), Color(0xFF2A2A2A)],
            ),
          ),
        ),
        Positioned(top: 42, left: -20, child: Container(width: 220, height: 220, decoration: BoxDecoration(shape: BoxShape.circle, color: const Color(0xFFFF5F6D).withOpacity(0.35)))),
        Positioned(bottom: 20, right: -10, child: Container(width: 260, height: 260, decoration: BoxDecoration(shape: BoxShape.circle, color: const Color(0xFFFFC371).withOpacity(0.28)))),

        CarouselSlider.builder(
          itemCount: heroItems.length,
          options: CarouselOptions(
            height: 460,
            viewportFraction: 1.0,
            autoPlay: heroItems.length > 1,
            autoPlayInterval: const Duration(seconds: 3),
            onPageChanged: (idx, _) => setState(() => _currentHeroIndex = idx),
          ),
          itemBuilder: (ctx, i, _) {
            final p = heroItems[i];
            final onSale = _isSaleActive(p);
            final img = _getFullImageUrl(p['imageUrl']);

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 56),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 1,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.14),
                            border: Border.all(color: Colors.white.withOpacity(0.22)),
                            borderRadius: BorderRadius.circular(30),
                          ),
                          child: Text(onSale ? 'EMIRIO SALE' : 'EMIRIO', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          p['nom'] ?? '',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w900, height: 1.1),
                        ),
                        const SizedBox(height: 12),

                        Wrap(
                          crossAxisAlignment: WrapCrossAlignment.center,
                          spacing: 8,
                          runSpacing: 4,
                          children: [
                            Text(
                              '${_getDisplayPrice(p).toStringAsFixed(3)} TND',
                              style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900),
                            ),
                            if (onSale)
                              Text(
                                '${p['prix']} TND',
                                style: TextStyle(color: Colors.white.withOpacity(0.55), fontSize: 16, decoration: TextDecoration.lineThrough, fontWeight: FontWeight.bold),
                              ),
                            if (onSale)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFF4D4F).withOpacity(0.18),
                                  border: Border.all(color: Colors.white.withOpacity(0.15)),
                                  borderRadius: BorderRadius.circular(30),
                                ),
                                child: Text('-${_getDiscountPercent(p)}%', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                              ),
                          ],
                        ),

                        if (onSale)
                          Container(
                            margin: const EdgeInsets.only(top: 12),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(color: Colors.white.withOpacity(0.08), borderRadius: BorderRadius.circular(14)),
                            child: Text(
                              'Ends in ${_formatCountdown(p['saleEndAt'])}',
                              style: const TextStyle(color: Colors.white, fontSize: 12),
                            ),
                          ),

                        const SizedBox(height: 20),
                        ElevatedButton(
                          onPressed: () => Navigator.pushNamed(context, '/product/${p['id']}'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                          ),
                          child: const Text('Shop Now', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 1,
                    child: Container(
                      height: 280,
                      decoration: BoxDecoration(color: Colors.white.withOpacity(0.08), borderRadius: BorderRadius.circular(28)),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(28),
                        child: img.isNotEmpty
                            ? CachedNetworkImage(
                          imageUrl: img,
                          fit: BoxFit.cover,
                          width: double.infinity,
                          height: 280,
                          placeholder: (context, url) => const Center(child: CircularProgressIndicator(color: Colors.white)),
                          errorWidget: (_, __, ___) => const Icon(Icons.image, color: Colors.white70, size: 40),
                        )
                            : const Center(child: Icon(Icons.image, color: Colors.white70, size: 40)),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildCategories() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Categories', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900)),
          const SizedBox(height: 18),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _buildCatChip('All', null),
              ..._flatCategories.map((c) => _buildCatChip(c['nom'], c['id'])),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCatChip(String label, int? id) {
    final active = _selectedCategoryId == id;
    return GestureDetector(
      onTap: () => setState(() => _selectedCategoryId = id),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        decoration: BoxDecoration(
          color: active ? Colors.black : const Color(0xFFEFEFEF),
          borderRadius: BorderRadius.circular(30),
        ),
        child: Text(
          label,
          style: TextStyle(color: active ? Colors.white : Colors.black, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }

  Widget _buildSection(String title, List<Map<String, dynamic>> items, int crossAxisCount) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Flexible(
                child: TextButton(
                  onPressed: () => Navigator.pushNamed(context, '/catalog'),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                    minimumSize: Size.zero,
                  ),
                  child: const Text('View all', style: TextStyle(color: Colors.black, decoration: TextDecoration.underline)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              childAspectRatio: 0.65,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
            ),
            itemCount: items.length,
            itemBuilder: (_, i) => _buildProductCard(items[i]),
          ),
        ],
      ),
    );
  }

  Widget _buildProductCard(Map<String, dynamic> p) {
    final productImage = _getFullImageUrl(p['imageUrl'] ?? p['previewImage']);

    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, '/product/${p['id']}'),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 4))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 3,
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                child: productImage.isNotEmpty
                    ? CachedNetworkImage(
                  imageUrl: productImage,
                  fit: BoxFit.cover,
                  width: double.infinity,
                  placeholder: (context, url) => Container(
                    color: Colors.grey[200],
                    child: const Center(child: CircularProgressIndicator()),
                  ),
                  errorWidget: (context, url, error) => Container(
                    color: Colors.grey[200],
                    child: const Icon(Icons.broken_image, size: 40, color: Colors.grey),
                  ),
                )
                    : Container(
                  color: Colors.grey[200],
                  child: const Icon(Icons.image, size: 40, color: Colors.grey),
                ),
              ),
            ),
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      p['nom'] ?? 'Unknown',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    const SizedBox(height: 4),
                    if (_isSaleActive(p)) ...[
                      Row(
                        children: [
                          Text(
                            '${_getDisplayPrice(p).toStringAsFixed(3)} TND',
                            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: Color(0xFFDC2626)),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${p['prix']} TND',
                            style: const TextStyle(decoration: TextDecoration.lineThrough, fontSize: 12, color: Colors.grey),
                          ),
                        ],
                      ),
                    ] else ...[
                      Text(
                        '${_getDisplayPrice(p).toStringAsFixed(3)} TND',
                        style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}