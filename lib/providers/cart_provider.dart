import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/models/product_model.dart';

// Helper class to match your React Cart Item structure
class CartItem {
  final int articleId;
  final int variationId;
  final ProductModel product;
  final String? selectedColor;
  final String? selectedSize;
  int quantity;
  final double price;

  CartItem({
    required this.articleId,
    required this.variationId,
    required this.product,
    this.selectedColor,
    this.selectedSize,
    required this.quantity,
    required this.price,
  });

  // Unique ID for the cart (like React's `${item.articleId}-${item.variationId}`)
  String get id => '$articleId-$variationId';
  double get total => price * quantity;

  // Convert to JSON for SharedPreferences (LocalStorage equivalent)
  Map<String, dynamic> toJson() => {
    'articleId': articleId,
    'variationId': variationId,
    'product': product.toJson(),
    'selectedColor': selectedColor,
    'selectedSize': selectedSize,
    'quantity': quantity,
    'price': price,
  };

  // Create from JSON
  factory CartItem.fromJson(Map<String, dynamic> json) => CartItem(
    articleId: json['articleId'] ?? json['product']['id'],
    variationId: json['variationId'] ?? 0,
    product: ProductModel.fromJson(json['product']),
    selectedColor: json['selectedColor'],
    selectedSize: json['selectedSize'],
    quantity: json['quantity'] ?? 1,
    price: (json['price'] ?? json['product']['price']).toDouble(),
  );
}

class CartProvider with ChangeNotifier {
  List<CartItem> _items = [];
  bool _isLoaded = false;

  static const String _cartKey = "cart_guest"; // Matching your React key

  List<CartItem> get items => _items;
  bool get isLoaded => _isLoaded;

  // Get total quantity of items (Matches your React 'cartCount')
  int get itemCount => _items.fold(0, (sum, item) => sum + item.quantity);

  // Get total price (Matches your React 'subtotal')
  double get total => _items.fold(0.0, (sum, item) => sum + item.total);

  CartProvider() {
    loadCart();
  }

  // Matches safeRead() in React
  Future<void> loadCart() async {
    final prefs = await SharedPreferences.getInstance();
    final String? cartJson = prefs.getString(_cartKey);

    if (cartJson != null) {
      try {
        final List<dynamic> decoded = jsonDecode(cartJson);
        _items = decoded.map((item) => CartItem.fromJson(item)).toList();
      } catch (e) {
        _items = [];
      }
    }
    _isLoaded = true;
    notifyListeners();
  }

  // Matches safeWrite() in React
  Future<void> _saveCart() async {
    final prefs = await SharedPreferences.getInstance();
    final String cartJson = jsonEncode(_items.map((item) => item.toJson()).toList());
    await prefs.setString(_cartKey, cartJson);
    notifyListeners();
  }

  // Add Item to Cart
  void addToCart(ProductModel product, {int qty = 1, String? color, String? size, int variationId = 0}) {
    // Generate the unique key checking exactly like React
    final existingIndex = _items.indexWhere((item) =>
    item.articleId == product.id && item.variationId == variationId
    );

    if (existingIndex >= 0) {
      // If it exists, just increase quantity
      _items[existingIndex].quantity += qty;
    } else {
      // If it's new, add it to the list
      _items.add(CartItem(
        articleId: product.id,
        variationId: variationId,
        product: product,
        selectedColor: color,
        selectedSize: size,
        quantity: qty,
        price: product.price,
      ));
    }
    _saveCart();
  }

  // Matches updateCartItemQty() in React
  void updateQuantity(String id, int newQuantity) {
    if (newQuantity < 1) return; // Minimum 1

    final index = _items.indexWhere((item) => item.id == id);
    if (index >= 0) {
      _items[index].quantity = newQuantity;
      _saveCart();
    }
  }

  // Matches removeFromCart() in React
  void removeFromCart(String id) {
    _items.removeWhere((item) => item.id == id);
    _saveCart();
  }

  // Matches clearCart() in React
  void clear() {
    _items.clear();
    _saveCart();
  }
}