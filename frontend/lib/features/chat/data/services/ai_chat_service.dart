import 'package:menly_app/core/network/api_client.dart';
import '../models/chat_message_model.dart';

class AiChatService {
  final ApiClient _api = ApiClient();

  /// Gọi API trợ lý tư vấn phong cách Menly AI Stylist
  Future<AiChatResponse> askAssistant({
    required String message,
    List<Map<String, String>> history = const [],
  }) async {
    try {
      final res = await _api.dio.post(
        '/ai-chat/message',
        data: {
          'message': message,
          'history': history,
        },
      );

      if (res.statusCode == 200 && res.data != null) {
        final payload = res.data['data'] as Map<String, dynamic>? ?? {};
        final reply = payload['reply']?.toString() ??
            'Dạ em có thể tư vấn cho anh mẫu phù hợp ngay ạ!';
        final rawProducts = payload['suggestedProducts'] as List? ?? [];
        final suggestedProducts = rawProducts
            .map((item) => SuggestedProductItem.fromJson(Map<String, dynamic>.from(item)))
            .toList();

        return AiChatResponse(
          reply: reply,
          suggestedProducts: suggestedProducts,
        );
      } else {
        throw Exception(res.data?['error'] ?? 'Không thể kết nối tới AI Stylist');
      }
    } catch (e) {
      throw Exception('Lỗi kết nối tới AI Stylist: ${e.toString().replaceAll("Exception: ", "")}');
    }
  }

  /// Phương thức tương thích ngược
  Future<Map<String, dynamic>> sendMessage(
    String message, {
    List<Map<String, String>> history = const [],
  }) async {
    final res = await askAssistant(message: message, history: history);
    return {
      'reply': res.reply,
      'suggestedProducts': res.suggestedProducts,
    };
  }
}
