import 'dart:convert';
import 'package:flutter/material.dart';
import '../core/api/api_client.dart';
import '../widgets/navbar.dart';
import '../widgets/product_card.dart';
// Note: We intentionally avoid ProductModel.fromJson if it causes mapping issues
import '../core/models/product_model.dart';

class CatalogPage extends StatefulWidget {
  const CatalogPage({super.key});
  @override
  State<CatalogPage> createState() => _CatalogPageState();
}

class _CatalogPageState extends State<CatalogPage> {
  List<Map<String, dynamic>> _allProducts = [];
  List<Map<String, dynamic>> _filteredProducts = [];
  bool _loading = true;
  String _search = '';

  String _selectedMainCategoryId = '';
  String _selectedSubCategoryId = '';
  String _selectedColorId = '';
  String _selectedSizeId = '';
  String _minPrice = '';
  String _maxPrice = '';
  String _brand = '';
  String _getFullImageUrl(String? url) {
    if (url == null || url.isEmpty) return '';
    if (url.startsWith('http')) return url;
    if (url.startsWith('/api')) return '${ApiClient.baseUrl}$url';
    return '${ApiClient.baseUrl}/$url';
  }
  List<Map<String, dynamic>> _categories = [];
  List<Map<String, dynamic>> _colors = [];
  List<Map<String, dynamic>> _sizes = [];
  List<String> _brands = [];

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    try {
      final resList = await Future.wait([
        ApiClient.get('/api/articles', auth: false),
        ApiClient.get('/api/categories', auth: false),
        ApiClient.get('/api/colors', auth: false),
        ApiClient.get('/api/sizes', auth: false),
      ]);

      // 1. Load Products (RAW JSON)
      if (resList[0].statusCode == 200) {
        final data = jsonDecode(resList[0].body);
        final list = data is List ? data : (data['content'] ?? data['products'] ?? []);

        _allProducts = (list as List).cast<Map<String, dynamic>>();

        // Extract brands
        final Set<String> brandSet = {};
        for (var p in _allProducts) {
          final String? marque = p['marque']?.toString();
          if (marque != null && marque.trim().isNotEmpty) brandSet.add(marque.trim());
        }
        _brands = brandSet.toList()..sort();
      }

      // 2. Load Categories
      if (resList[1].statusCode == 200) {
        final catData = jsonDecode(resList[1].body);
        _categories = _flattenCategories(catData);
      }

      // 3. Load Colors & Sizes
      if (resList[2].statusCode == 200) _colors = (jsonDecode(resList[2].body) as List).cast<Map<String, dynamic>>();
      if (resList[3].statusCode == 200) _sizes = (jsonDecode(resList[3].body) as List).cast<Map<String, dynamic>>();

      _applyFilters();
    } catch (e) {
      debugPrint('Catalog Load Error: $e');
    }
    if (mounted) setState(() => _loading = false);
  }

  List<Map<String, dynamic>> _flattenCategories(Map<String, dynamic> data) {
    final List<Map<String, dynamic>> flat = [];
    if (data['chaussures'] != null) {
      (data['chaussures'] as Map).forEach((k, subCat) {
        flat.add({'id': subCat['id'].toString(), 'nom': subCat['nom'], 'parentId': null});
        if (subCat['children'] is List) {
          for (var child in subCat['children']) {
            flat.add({'id': child['id'].toString(), 'nom': child['nom'], 'parentId': subCat['id'].toString()});
          }
        }
      });
    }
    if (data['accessoires'] is List) {
      for (var acc in data['accessoires']) {
        flat.add({'id': acc['id'].toString(), 'nom': acc['nom'], 'parentId': null});
      }
    }
    return flat;
  }

  void _applyFilters() {
    setState(() {
      _filteredProducts = _allProducts.where((p) {
        // 1. Search
        final String name = (p['nom'] ?? '').toString().toLowerCase();
        final String desc = (p['description'] ?? '').toString().toLowerCase();
        final bool matchSearch = _search.isEmpty || name.contains(_search.toLowerCase()) || desc.contains(_search.toLowerCase());

        // 2. Category
        bool matchCat = true;
        final String catId = p['categorieId']?.toString() ?? '';
        if (_selectedSubCategoryId.isNotEmpty) {
          matchCat = catId == _selectedSubCategoryId;
        } else if (_selectedMainCategoryId.isNotEmpty) {
          // Check if article's category is a child of the selected main category
          final isDirectChild = catId == _selectedMainCategoryId;
          final isSubChild = _categories.any((c) => c['id'] == catId && c['parentId'] == _selectedMainCategoryId);
          matchCat = isDirectChild || isSubChild;
        }

        // 3. Brand
        final String marque = p['marque']?.toString() ?? '';
        final bool matchBrand = _brand.isEmpty || marque == _brand;

        // 4. Price
        final double price = double.tryParse((p['salePrice'] ?? p['prix'] ?? 0).toString()) ?? 0.0;
        bool matchPrice = true;
        if (_minPrice.isNotEmpty) matchPrice &= price >= (double.tryParse(_minPrice) ?? 0);
        if (_maxPrice.isNotEmpty) matchPrice &= price <= (double.tryParse(_maxPrice) ?? double.infinity);

        return matchSearch && matchCat && matchBrand && matchPrice;
      }).toList();
    });
  }

  void _resetFilters() {
    setState(() {
      _search = '';
      _selectedMainCategoryId = '';
      _selectedSubCategoryId = '';
      _brand = '';
      _selectedColorId = '';
      _selectedSizeId = '';
      _minPrice = '';
      _maxPrice = '';
    });
    _applyFilters();
  }

  // Converts raw JSON back to ProductModel for your existing ProductCard widget
  ProductModel _mapToModel(Map<String, dynamic> json) {
    try {
      return ProductModel.fromJson(json);
    } catch (e) {
      // Safe fallback if mapping fails so UI doesn't break
      return ProductModel(
        id: json['id'] ?? 0,
        name: json['nom'] ?? 'Unknown',
        description: json['description'] ?? '',
        price: double.tryParse(json['prix']?.toString() ?? '0') ?? 0.0,
        imageUrl: json['imageUrl'] ?? json['previewImage'],
        category: json['categorieNom'],
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isDesktop = MediaQuery.of(context).size.width > 920;

    return MainScaffold(
      currentIndex: 1,
      child: Scaffold(
        key: _scaffoldKey,
        backgroundColor: Colors.white,
        endDrawer: isDesktop ? null : Drawer(child: _buildSidebar()),
        body: Container(
          color: Colors.white,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (isDesktop)
                Container(
                  width: 320,
                  margin: const EdgeInsets.only(left: 24, top: 28, bottom: 48),
                  child: _buildSidebar(),
                ),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: isDesktop ? 26 : 16, vertical: 28),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Catalog', style: TextStyle(fontSize: 36, fontWeight: FontWeight.w900, letterSpacing: -0.5)),
                              const SizedBox(height: 6),
                              Text('${_filteredProducts.length} found', style: const TextStyle(color: Color(0xFF6B7280))),
                            ],
                          ),
                          if (!isDesktop)
                            ElevatedButton.icon(
                              onPressed: () => _scaffoldKey.currentState?.openEndDrawer(),
                              icon: const Icon(Icons.filter_list, size: 18),
                              label: const Text('Filters'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.black,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      Expanded(
                        child: _loading
                            ? const Center(child: CircularProgressIndicator(color: Colors.black))
                            : _filteredProducts.isEmpty
                            ? const Center(child: Text('No products match your filters', style: TextStyle(color: Colors.grey, fontSize: 16)))
                            : GridView.builder(
                          padding: const EdgeInsets.only(bottom: 40),
                          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: isDesktop ? 3 : 2,
                            childAspectRatio: 0.65,
                            crossAxisSpacing: 16,
                            mainAxisSpacing: 16,
                          ),
                          itemCount: _filteredProducts.length,
                          itemBuilder: (_, i) => ProductCard(product: _mapToModel(_filteredProducts[i])),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSidebar() {
    final mainCats = _categories.where((c) => c['parentId'] == null).toList();
    final subCats = _categories.where((c) => c['parentId'] == _selectedMainCategoryId && _selectedMainCategoryId.isNotEmpty).toList();

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFECECEC)),
        borderRadius: BorderRadius.circular(28),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 44, offset: Offset(0, 16))],
      ),
      padding: const EdgeInsets.all(22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Filters', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, letterSpacing: -0.5)),
          const SizedBox(height: 18),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildInputRow('Search anything', _search, (v) { _search = v; _applyFilters(); }),
                  const SizedBox(height: 18),

                  const Text('Category', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Color(0xFF374151))),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 10, runSpacing: 10,
                    children: [
                      _buildChip('All', _selectedMainCategoryId.isEmpty, () { _selectedMainCategoryId = ''; _selectedSubCategoryId = ''; _applyFilters(); }),
                      ...mainCats.map((c) => _buildChip(c['nom'], _selectedMainCategoryId == c['id'], () { _selectedMainCategoryId = c['id']; _selectedSubCategoryId = ''; _applyFilters(); })),
                    ],
                  ),

                  if (subCats.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 10, runSpacing: 10,
                      children: subCats.map((c) => _buildChip(c['nom'], _selectedSubCategoryId == c['id'], () { _selectedSubCategoryId = c['id']; _applyFilters(); })).toList(),
                    ),
                  ],
                  const SizedBox(height: 18),

                  const Text('Price', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Color(0xFF374151))),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(child: _buildInputRow('Min', _minPrice, (v) { _minPrice = v; _applyFilters(); }, isNumber: true)),
                      const SizedBox(width: 10),
                      Expanded(child: _buildInputRow('Max', _maxPrice, (v) { _maxPrice = v; _applyFilters(); }, isNumber: true)),
                    ],
                  ),
                  const SizedBox(height: 18),

                  const Text('Brand', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Color(0xFF374151))),
                  const SizedBox(height: 10),
                  _buildDropdown(_brand, ['All', ..._brands], (v) { _brand = v == 'All' ? '' : v!; _applyFilters(); }),
                  const SizedBox(height: 24),

                  SizedBox(
                    width: double.infinity, height: 50,
                    child: ElevatedButton(
                      onPressed: _resetFilters,
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.black, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30))),
                      child: const Text('Reset filters', style: TextStyle(fontWeight: FontWeight.w800)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChip(String label, bool isActive, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isActive ? Colors.black : Colors.white,
          border: Border.all(color: isActive ? Colors.black : const Color(0xFFE5E7EB)),
          borderRadius: BorderRadius.circular(30),
        ),
        child: Text(label, style: TextStyle(color: isActive ? Colors.white : Colors.black, fontWeight: FontWeight.w700, fontSize: 13)),
      ),
    );
  }

  Widget _buildInputRow(String hint, String value, Function(String) onChanged, {bool isNumber = false}) {
    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFE5E7EB))),
      child: TextField(
        controller: TextEditingController(text: value)..selection = TextSelection.collapsed(offset: value.length),
        onChanged: onChanged,
        keyboardType: isNumber ? TextInputType.number : TextInputType.text,
        decoration: InputDecoration(hintText: hint, border: InputBorder.none, contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13)),
      ),
    );
  }

  Widget _buildDropdown(String value, List<String> items, Function(String?) onChanged) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFE5E7EB))),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          isExpanded: true,
          value: value.isEmpty ? 'All' : value,
          items: items.map((i) => DropdownMenuItem(value: i, child: Text(i))).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}