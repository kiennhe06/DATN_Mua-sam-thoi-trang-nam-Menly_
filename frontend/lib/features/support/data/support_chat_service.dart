import 'package:dio/dio.dart';
import '../../../core/network/api_client.dart';

class SupportConversation {
  final String id;
  final String userId;
  final String? customerName;
  final String? customerEmail;
  final String? lastMessage;
  final DateTime lastMessageAt;
  final int unreadStaffCount;
  final String status;

  const SupportConversation({
    required this.id,
    required this.userId,
    this.customerName,
    this.customerEmail,
    this.lastMessage,
    required this.lastMessageAt,
    this.unreadStaffCount = 0,
    this.status = 'open',
  });

  factory SupportConversation.fromJson(Map<String, dynamic> json) {
    final customer = json['customer'] is Map
        ? Map<String, dynamic>.from(json['customer'] as Map)
        : const <String, dynamic>{};
    return SupportConversation(
      id: json['id']?.toString() ?? '',
      userId: json['user_id']?.toString() ?? '',
      customerName: customer['full_name']?.toString(),
      customerEmail: customer['email']?.toString(),
      lastMessage: json['last_message']?.toString(),
      lastMessageAt:
          DateTime.tryParse(json['last_message_at']?.toString() ?? '') ??
              DateTime.now(),
      unreadStaffCount: (json['unread_staff_count'] as num?)?.toInt() ?? 0,
      status: json['status']?.toString() ?? 'open',
    );
  }
}

class SupportChatMessage {
  final String id;
  final String conversationId;
  final String senderId;
  final String senderRole;
  final String content;
  final DateTime createdAt;

  const SupportChatMessage({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.senderRole,
    required this.content,
    required this.createdAt,
  });

  factory SupportChatMessage.fromJson(Map<String, dynamic> json) {
    return SupportChatMessage(
      id: json['id']?.toString() ?? '',
      conversationId: json['conversation_id']?.toString() ?? '',
      senderId: json['sender_id']?.toString() ?? '',
      senderRole: json['sender_role']?.toString() ?? 'customer',
      content: json['content']?.toString() ?? '',
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '') ??
          DateTime.now(),
    );
  }
}

class SupportChatService {
  final Dio _dio = ApiClient().dio;

  Map<String, dynamic> _map(dynamic value) {
    if (value is Map) return Map<String, dynamic>.from(value);
    throw const FormatException('Dữ liệu chat trả về không hợp lệ');
  }

  // Dio tra ve doi tuong Response, phan than nam trong response.data.
  // Truyen thang ca Response vao _map se luon nem FormatException.
  dynamic _data(Response<dynamic> response) => _map(response.data)['data'];

  String _message(Object error) {
    if (error is DioException) {
      final response = error.response?.data;
      if (response is Map && response['error'] is String) {
        return response['error'] as String;
      }
      if (error.type == DioExceptionType.connectionError ||
          error.type == DioExceptionType.connectionTimeout ||
          error.type == DioExceptionType.receiveTimeout) {
        return 'Không thể kết nối CSKH. Vui lòng kiểm tra mạng.';
      }
    }
    if (error is FormatException) return error.message;
    return 'Không thể thực hiện thao tác chat. Vui lòng thử lại.';
  }

  Future<SupportConversation> getMyConversation() async {
    try {
      return SupportConversation.fromJson(
          _map(_data(await _dio.get('/support-chat/mine'))));
    } catch (error) {
      throw Exception(_message(error));
    }
  }

  Future<List<SupportConversation>> getStaffConversations() async {
    try {
      final data = _data(await _dio.get('/support-chat/staff/conversations'));
      if (data is! List) {
        throw const FormatException('Danh sách hội thoại không hợp lệ');
      }
      return data
          .map((item) => SupportConversation.fromJson(_map(item)))
          .toList();
    } catch (error) {
      throw Exception(_message(error));
    }
  }

  Future<List<SupportChatMessage>> getMessages(String conversationId) async {
    try {
      final data = _data(
        await _dio.get('/support-chat/$conversationId/messages'),
      );
      if (data is! List) {
        throw const FormatException('Danh sách tin nhắn không hợp lệ');
      }
      return data
          .map((item) => SupportChatMessage.fromJson(_map(item)))
          .toList();
    } catch (error) {
      throw Exception(_message(error));
    }
  }

  Future<void> sendMessage(String conversationId, String content) async {
    try {
      await _dio.post(
        '/support-chat/$conversationId/messages',
        data: {'content': content},
      );
    } catch (error) {
      throw Exception(_message(error));
    }
  }
}
