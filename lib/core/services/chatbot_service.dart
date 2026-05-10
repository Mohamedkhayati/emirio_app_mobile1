import 'dart:convert';
import '../api/api_client.dart';
import '../constants/api_routes.dart';
import '../models/chat_message_model.dart';

class ChatbotService {
  static List<dynamic> _extractList(dynamic decoded) {
    if (decoded is List) return decoded;
    if (decoded is Map<String, dynamic>) {
      if (decoded['content'] is List) return decoded['content'];
      if (decoded['data'] is List) return decoded['data'];
      if (decoded['items'] is List) return decoded['items'];
      if (decoded['messages'] is List) return decoded['messages'];
    }
    return [];
  }

  static String _extractReply(dynamic decoded) {
    if (decoded is String) return decoded;
    if (decoded is Map<String, dynamic>) {
      return decoded['reply']?.toString() ??
          decoded['response']?.toString() ??
          decoded['message']?.toString() ??
          decoded['answer']?.toString() ??
          decoded['content']?.toString() ??
          'Sorry, I could not generate a response.';
    }
    return 'Sorry, I could not generate a response.';
  }

  static Future<List<ChatMessageModel>> fetchHistory() async {
    try {
      final res = await ApiClient.get(ApiRoutes.chatbotHistory);
      if (res.statusCode == 200) {
        final decoded = jsonDecode(res.body);
        final list = _extractList(decoded);
        return list.map((e) => ChatMessageModel.fromJson(e)).toList();
      }
    } catch (_) {}
    return [];
  }

  static Future<String> sendMessage(String message) async {
    try {
      final res = await ApiClient.post(ApiRoutes.chatbotMessage, {
        'message': message,
      });
      if (res.statusCode == 200 || res.statusCode == 201) {
        return _extractReply(jsonDecode(res.body));
      }
    } catch (_) {}
    return 'An error occurred while contacting the assistant.';
  }

  static Future<bool> resetChat() async {
    try {
      final res = await ApiClient.post(ApiRoutes.chatbotReset, {});
      return res.statusCode == 200 || res.statusCode == 204;
    } catch (_) {
      return false;
    }
  }
}