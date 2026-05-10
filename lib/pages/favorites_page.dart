import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/api/api_client.dart';
import '../core/models/product_model.dart';
import '../providers/favorites_provider.dart';
import '../widgets/navbar.dart';
import '../widgets/product_card.dart';

class FavoritesPage extends StatefulWidget {
  const FavoritesPage({super.key});
  @override
  State<FavoritesPage> createState() => _FavoritesPageState();
}

class _FavoritesPageState extends State<FavoritesPage> {
  List<ProductModel> _allArticles = [];
  bool _loading = true;
  String _search = '';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    try {
      final res = await ApiClient.get('/api/articles', auth: false);
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final list = data is List ? data : (data['content'] ?? data['products'] ?? []);

        _allArticles = (list as List).map((e) {
          try { return ProductModel.fromJson(e); } catch (_) {
            return ProductModel(
              id: e['id'] ?? 0, name: e['nom'] ?? 'Unknown', description: e['description'] ?? '',
              price: double.tryParse(e['prix']?.toString() ?? '0') ?? 0.0,
              imageUrl: e['imageUrl'] ?? e['previewImage'], category: e['categorieNom'],
            );
          }
        }).toList();
      }
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    // Watch global favorites instantly
    final favProvider = context.watch<FavoritesProvider>();

    final List<ProductModel> filteredFavorites = _allArticles
        .where((a) => favProvider.isFavorite(a.id))
        .where((a) {
      if (_search.isEmpty) return true;
      return a.name.toLowerCase().contains(_search.toLowerCase()) ||
          (a.category ?? '').toLowerCase().contains(_search.toLowerCase());
    }).toList()..sort((a, b) => b.id.compareTo(a.id));

    final bool isDesktop = MediaQuery.of(context).size.width > 920;

    return MainScaffold(
      currentIndex: 2,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: isDesktop ? 40 : 16, vertical: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              isDesktop
                  ? Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [_buildHeaderTitle(filteredFavorites.length), _buildSearchBar()])
                  : Column(crossAxisAlignment: CrossAxisAlignment.start, children: [_buildHeaderTitle(filteredFavorites.length), const SizedBox(height: 20), _buildSearchBar()]),

              const SizedBox(height: 32),

              if (_loading) const Center(child: Padding(padding: EdgeInsets.all(40.0), child: CircularProgressIndicator(color: Colors.black)))
              else if (filteredFavorites.isEmpty && _search.isEmpty) _buildEmptyState()
              else if (filteredFavorites.isEmpty && _search.isNotEmpty) const Center(child: Padding(padding: EdgeInsets.all(40.0), child: Text('No favorites match your search.', style: TextStyle(color: Colors.grey, fontSize: 16))))
                else
                  GridView.builder(
                    shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: isDesktop ? 4 : 2, childAspectRatio: 0.65, crossAxisSpacing: 16, mainAxisSpacing: 16,
                    ),
                    itemCount: filteredFavorites.length,
                    itemBuilder: (_, i) => ProductCard(product: filteredFavorites[i]),
                  ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderTitle(int count) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [const Text('My Favorites', style: TextStyle(fontSize: 36, fontWeight: FontWeight.w900, letterSpacing: -0.5)), const SizedBox(width: 12), const Text('❤️', style: TextStyle(fontSize: 24)), const SizedBox(width: 8), Text('($count)', style: const TextStyle(fontSize: 20, color: Color(0xFF666666)))]),
        const SizedBox(height: 6), Text('$count products saved', style: const TextStyle(color: Color(0xFF6B7280), fontSize: 16)),
      ],
    );
  }

  Widget _buildSearchBar() {
    return Container(
      width: 320, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFE5E7EB))),
      child: TextField(
        onChanged: (v) => setState(() => _search = v),
        decoration: const InputDecoration(hintText: 'Search in favorites...', border: InputBorder.none, contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14), prefixIcon: Icon(Icons.search, color: Colors.grey)),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 80.0, horizontal: 20.0),
        child: Column(
          children: [
            const Text('💔', style: TextStyle(fontSize: 80)), const SizedBox(height: 20),
            const Text('No favorites yet', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800)), const SizedBox(height: 12),
            const Text('Start adding products you love by clicking the heart icon.', style: TextStyle(color: Color(0xFF666666), fontSize: 16)), const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () => Navigator.pushNamed(context, '/catalog'),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.black, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 18), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30))),
              child: const Text('Browse Catalog →', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }
}