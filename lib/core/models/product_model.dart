class ProductModel {
  final int id;
  final String name;
  final String description;
  final double price;
  final String? imageUrl;
  final String? category;
  final bool isFavorite;

  ProductModel({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    this.imageUrl,
    this.category,
    this.isFavorite = false,
  });

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    return ProductModel(
      id: json['id'] ?? json['articleId'] ?? 0,
      name: json['nom'] ?? json['name'] ?? 'Unknown',
      description: json['description'] ?? '',
      price: double.tryParse((json['salePrice'] ?? json['prix'] ?? json['price'] ?? '0').toString()) ?? 0.0,
      imageUrl: json['imageUrl'] ?? json['previewImage'] ?? json['image'],
      category: json['categorieNom'] ?? json['category'],
    );
  }

  // >>> ADD THIS NEW METHOD BELOW <<<
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nom': name,
      'description': description,
      'prix': price,
      'imageUrl': imageUrl,
      'categorieNom': category,
    };
  }
}