import 'product_model.dart';

class CartItemModel {
  final int id;
  final ProductModel product;
  int quantity;
  final String? selectedSize;
  final String? selectedColor;

  CartItemModel({
    required this.id,
    required this.product,
    required this.quantity,
    this.selectedSize,
    this.selectedColor,
  });

  factory CartItemModel.fromJson(Map<String, dynamic> json) => CartItemModel(
    id: json['id'],
    product: ProductModel.fromJson(json['product']),
    quantity: json['quantity'],
    selectedSize: json['size'],
    selectedColor: json['color'],
  );

  double get total => product.price * quantity;
}