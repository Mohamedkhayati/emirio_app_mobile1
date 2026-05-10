class VariationModel {
  final int id;
  final int articleId;
  final int couleurId;
  final String couleurNom;
  final String couleurCodeHex;
  final int? tailleId;
  final String? taillePointure;
  final double prix;
  final int quantiteStock;
  final String? model3dUrl;
  final List<String> imageUrls;

  VariationModel({
    required this.id,
    required this.articleId,
    required this.couleurId,
    required this.couleurNom,
    required this.couleurCodeHex,
    this.tailleId,
    this.taillePointure,
    required this.prix,
    required this.quantiteStock,
    this.model3dUrl,
    this.imageUrls = const [],
  });

  static int _toInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  factory VariationModel.fromJson(Map<String, dynamic> json) => VariationModel(
    id: _toInt(json['id']),
    articleId: _toInt(json['articleId']),
    couleurId: _toInt(json['couleurId']),
    couleurNom: json['couleurNom'] ?? '',
    couleurCodeHex: json['couleurCodeHex'] ?? '#000000',
    tailleId: json['tailleId'] != null ? _toInt(json['tailleId']) : null,
    taillePointure: json['taillePointure'],
    prix: (json['prix'] ?? 0).toDouble(),
    quantiteStock: _toInt(json['quantiteStock']),
    model3dUrl: json['model3dUrl'],
    imageUrls: json['imageUrls'] != null ? List<String>.from(json['imageUrls']) : [],
  );
}