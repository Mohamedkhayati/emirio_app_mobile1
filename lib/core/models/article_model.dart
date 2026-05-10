import '../../core/utils/json_helpers.dart';

class ArticleModel {
  final int id;
  final String nom;
  final String description;
  final String details;
  final double prix;
  final double? salePrice;
  final DateTime? saleStartAt;
  final DateTime? saleEndAt;
  final bool actif;
  final bool recommended;
  final int categorieId;
  final String categorieNom;
  final String marque;
  final String matiere;
  final String sku;

  ArticleModel({
    required this.id,
    required this.nom,
    required this.description,
    required this.details,
    required this.prix,
    this.salePrice,
    this.saleStartAt,
    this.saleEndAt,
    required this.actif,
    required this.recommended,
    required this.categorieId,
    required this.categorieNom,
    required this.marque,
    required this.matiere,
    required this.sku,
  });

  static int _toInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  factory ArticleModel.fromJson(Map<String, dynamic> json) => ArticleModel(
    id: toInt(json['id']),
    nom: json['nom'] ?? '',
    description: json['description'] ?? '',
    details: json['details'] ?? '',
    prix: (json['prix'] ?? 0).toDouble(),
    salePrice: json['salePrice']?.toDouble(),
    saleStartAt: json['saleStartAt'] != null ? DateTime.parse(json['saleStartAt']) : null,
    saleEndAt: json['saleEndAt'] != null ? DateTime.parse(json['saleEndAt']) : null,
    actif: json['actif'] ?? false,
    recommended: json['recommended'] ?? false,
    categorieId: _toInt(json['categorieId']),
    categorieNom: json['categorieNom'] ?? '',
    marque: json['marque'] ?? '',
    matiere: json['matiere'] ?? '',
    sku: json['sku'] ?? '',
  );

  Map<String, dynamic> toJson() => {
    'nom': nom,
    'description': description,
    'details': details,
    'prix': prix,
    'salePrice': salePrice,
    'saleStartAt': saleStartAt?.toIso8601String(),
    'saleEndAt': saleEndAt?.toIso8601String(),
    'actif': actif,
    'recommended': recommended,
    'categorieId': categorieId,
    'marque': marque,
    'matiere': matiere,
    'sku': sku,
  };
}