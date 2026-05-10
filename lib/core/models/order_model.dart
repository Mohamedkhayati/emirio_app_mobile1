class OrderModel {
  final int id;
  final String status;
  final double total;
  final DateTime createdAt;
  final List<dynamic> items;

  OrderModel({
    required this.id,
    required this.status,
    required this.total,
    required this.createdAt,
    required this.items,
  });

  factory OrderModel.fromJson(Map<String, dynamic> json) => OrderModel(
    id: json['id'],
    status: json['status'] ?? 'PENDING',
    total: (json['total'] ?? 0).toDouble(),
    createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
    items: json['items'] ?? [],
  );
}