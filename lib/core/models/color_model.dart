class ColorModel {
  final int id;
  final String nom;
  final String codeHex;

  ColorModel({required this.id, required this.nom, required this.codeHex});

  static int _toInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  factory ColorModel.fromJson(Map<String, dynamic> json) => ColorModel(
    id: _toInt(json['id']),
    nom: json['nom']?.toString() ?? '',
    codeHex: json['codeHex']?.toString() ?? '#000000',
  );
}