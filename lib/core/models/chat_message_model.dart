class ChatMessageModel {
  final String role;
  final String content;
  final DateTime createdAt;

  const ChatMessageModel({
    required this.role,
    required this.content,
    required this.createdAt,
  });

  factory ChatMessageModel.fromJson(Map<String, dynamic> json) {
    return ChatMessageModel(
      role: json['role'] ?? json['sender'] ?? 'assistant',
      content: json['content'] ?? json['message'] ?? json['text'] ?? '',
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'role': role,
      'content': content,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}