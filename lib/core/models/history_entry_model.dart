class HistoryEntryModel {
  final int id;
  final String action;
  final String targetType;
  final int? articleId;
  final int? variationId;
  final String? articleName;
  final String? variationLabel;
  final String summary;
  final String actorName;
  final DateTime actionAt;
  final String? detailsJson;

  HistoryEntryModel({
    required this.id,
    required this.action,
    required this.targetType,
    this.articleId,
    this.variationId,
    this.articleName,
    this.variationLabel,
    required this.summary,
    required this.actorName,
    required this.actionAt,
    this.detailsJson,
  });

  factory HistoryEntryModel.fromJson(Map<String, dynamic> json) => HistoryEntryModel(
    id: json['id'],
    action: json['action'] ?? '',
    targetType: json['targetType'] ?? '',
    articleId: json['articleId'],
    variationId: json['variationId'],
    articleName: json['articleName'],
    variationLabel: json['variationLabel'],
    summary: json['summary'] ?? '',
    actorName: json['actorName'] ?? 'SYSTEM',
    actionAt: DateTime.parse(json['actionAt'] ?? DateTime.now().toIso8601String()),
    detailsJson: json['detailsJson'],
  );
}