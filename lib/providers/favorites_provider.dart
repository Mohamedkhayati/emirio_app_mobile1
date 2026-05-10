import 'dart:convert';
import 'package:flutter/material.dart';
import '../core/api/api_client.dart';

class FavoritesProvider with ChangeNotifier {
  List<int> _favoriteIds = [];
  List<int> get favoriteIds => _favoriteIds;

  FavoritesProvider() {
    fetchFavorites();
  }

  Future<void> fetchFavorites() async {
    try {
      final res = await ApiClient.get('/api/favorites');
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as List;
        _favoriteIds = data.map((e) => (e['id'] ?? e['articleId'] ?? e) as int).toList();
        notifyListeners();
      }
    } catch (_) {}
  }

  bool isFavorite(int id) => _favoriteIds.contains(id);

  Future<void> toggleFavorite(int id) async {
    final bool isFav = isFavorite(id);

    // Optimistic update for instant UI feedback (like React)
    if (isFav) {
      _favoriteIds.remove(id);
    } else {
      _favoriteIds.add(id);
    }
    notifyListeners();

    try {
      final endpoint = isFav ? '/api/favorites/remove/$id' : '/api/favorites/add/$id';
      final res = isFav ? await ApiClient.delete(endpoint) : await ApiClient.post(endpoint, {});

      if (res.statusCode != 200 && res.statusCode != 201) {
        throw Exception('API failed');
      }
    } catch (e) {
      // Revert if backend fails
      if (isFav) {
        _favoriteIds.add(id);
      } else {
        _favoriteIds.remove(id);
      }
      notifyListeners();
    }
  }
}