class SizeModel {
  final int id;
  final String pointure;

  SizeModel({required this.id, required this.pointure});

  static int _toInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  factory SizeModel.fromJson(Map<String, dynamic> json) => SizeModel(
    id: _toInt(json['id']),
    pointure: json['pointure']?.toString() ?? '',
  );
}