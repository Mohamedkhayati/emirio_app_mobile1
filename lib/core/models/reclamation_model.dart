class ReclamationModel {
  final int id;
  final String subject;
  final String description;
  final String status;
  final String? userName;
  final String? userEmail;
  final int? userId;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final List<ReclamationMessage> messages;

  ReclamationModel({
    required this.id,
    required this.subject,
    required this.description,
    required this.status,
    this.userName,
    this.userEmail,
    this.userId,
    required this.createdAt,
    this.updatedAt,
    this.messages = const [],
  });

  factory ReclamationModel.fromJson(Map<String, dynamic> json) {
    return ReclamationModel(
      id: json['id'],
      subject: json['subject'] ?? '',
      description: json['description'] ?? json['message'] ?? '',
      status: json['status'] ?? 'OPEN',
      userName: json['userName'] ?? json['customerName'],
      userEmail: json['userEmail'] ?? json['customerEmail'],
      userId: json['userId'],
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt']) : null,
      messages: (json['messages'] as List? ?? [])
          .map((m) => ReclamationMessage.fromJson(m))
          .toList(),
    );
  }
}

class ReclamationMessage {
  final int id;
  final String content;
  final String senderName;
  final String senderRole;
  final DateTime timestamp;

  ReclamationMessage({
    required this.id,
    required this.content,
    required this.senderName,
    required this.senderRole,
    required this.timestamp,
  });

  factory ReclamationMessage.fromJson(Map<String, dynamic> json) {
    return ReclamationMessage(
      id: json['id'],
      content: json['content'] ?? json['message'] ?? '',
      senderName: json['senderName'] ?? json['senderName'] ?? 'Unknown',
      senderRole: json['senderRole'] ?? (json['senderRole'] == 'Admin' ? 'Admin' : 'Client'),
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'])
          : DateTime.now(),
    );
  }
}

class ReclamationHistoryEntry {
  final int id;
  final String action;
  final String? oldValue;
  final String? newValue;
  final String? details;
  final String actorName;
  final String actorRole;
  final DateTime createdAt;

  ReclamationHistoryEntry({
    required this.id,
    required this.action,
    this.oldValue,
    this.newValue,
    this.details,
    required this.actorName,
    required this.actorRole,
    required this.createdAt,
  });

  factory ReclamationHistoryEntry.fromJson(Map<String, dynamic> json) {
    return ReclamationHistoryEntry(
      id: json['id'],
      action: json['action'] ?? '',
      oldValue: json['oldValue'] ?? json['oldStatus'],
      newValue: json['newValue'] ?? json['newStatus'],
      details: json['details'],
      actorName: json['actorName'] ?? json['userName'] ?? 'System',
      actorRole: json['actorRole'] ?? 'System',
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
    );
  }

  String getActionIcon() {
    switch (action) {
      case 'CREATED':
        return '📝';
      case 'STATUS_CHANGED':
        return '🔄';
      case 'MESSAGE_ADDED':
        return '💬';
      default:
        return '📌';
    }
  }

  String getActionDisplayName() {
    switch (action) {
      case 'CREATED':
        return 'Created';
      case 'STATUS_CHANGED':
        return 'Status changed';
      case 'MESSAGE_ADDED':
        return 'Message added';
      default:
        return action.replaceAll('_', ' ');
    }
  }
}