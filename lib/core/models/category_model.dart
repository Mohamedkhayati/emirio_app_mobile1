class CategoryModel {
  final int id;
  final String nom;
  final String? description;
  final int? parentId;
  final int level;
  final int displayOrder;
  final String? iconUrl;
  final bool actif;

  CategoryModel({
    required this.id,
    required this.nom,
    this.description,
    this.parentId,
    required this.level,
    required this.displayOrder,
    this.iconUrl,
    required this.actif,
  });

  factory CategoryModel.fromJson(Map<String, dynamic> json) => CategoryModel(
    id: int.tryParse(json['id'].toString()) ?? 0,
    nom: json['nom'] ?? '',
    description: json['description'],
    parentId: json['parentId'] != null ? int.tryParse(json['parentId'].toString()) : null,
    level: int.tryParse(json['level'].toString()) ?? 0,
    displayOrder: int.tryParse(json['displayOrder'].toString()) ?? 0,
    iconUrl: json['iconUrl'],
    actif: json['actif'] ?? true,
  );
}