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

  /// Doi phuong da doc tin nay chua. Chi co y nghia voi tin do minh gui.
  final bool isRead;

  const SupportChatMessage({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.senderRole,
    required this.content,
    required this.createdAt,
    this.isRead = false,
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
      isRead: json['is_read'] == true,
    );
  }
}

/// Mot lan tai tin nhan: danh sach tin va ben kia co dang go phim khong.
class KetQuaTaiTinNhan {
  final List<SupportChatMessage> messages;
  final bool khachDangSoan;
  final bool nhanVienDangSoan;

  /// Con tin cu hon chua tai ve hay khong.
  final bool conTinCu;

  const KetQuaTaiTinNhan({
    required this.messages,
    this.khachDangSoan = false,
    this.nhanVienDangSoan = false,
    this.conTinCu = false,
  });
}

/// So tin tai moi lan, ca lan mo man lan khi bam xem tin cu hon.
const int soTinMoiLan = 50;

class SupportChatService {
  final Dio _dio = ApiClient().dio;

  Map<String, dynamic> _map(dynamic value) {
    if (value is Map) return Map<String, dynamic>.from(value);
    throw const FormatException('Dữ liệu chat trả về không hợp lệ');
  }

  // Dio tra ve doi tuong Response, phan than nam trong response.data.
  // Truyen thang ca Response vao _map se luon nem FormatException.
  dynamic _data(Response<dynamic> response) => _map(response.data)['data'];

  /// Doc khoi 'typing' nam canh 'data'. Thieu khoi nay thi coi nhu khong ai go.
  ({bool khach, bool nhanVien}) _dangSoan(Response<dynamic> response) {
    final than = response.data;
    final typing = than is Map ? than['typing'] : null;
    if (typing is! Map) return (khach: false, nhanVien: false);
    return (khach: typing['customer'] == true, nhanVien: typing['staff'] == true);
  }

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

  /// Lay hoi thoai cua minh kem tin nhan trong dung mot lan goi mang.
  ///
  /// Truoc day man chat goi /mine xong moi goi tiep /:id/messages, hai request
  /// phai cho nhau nen lan dau mo man lau gap doi can thiet.
  Future<SupportChatSnapshot> getMyChat() async {
    try {
      final res = await _dio.get('/support-chat/mine');
      final data = _map(_data(res));
      final rawMessages = data['messages'];
      final messages = rawMessages is List
          ? rawMessages
              .map((item) => SupportChatMessage.fromJson(_map(item)))
              .toList()
          : <SupportChatMessage>[];
      final dangSoan = _dangSoan(res);
      final than = res.data;
      return SupportChatSnapshot(
        conversation: SupportConversation.fromJson(data),
        messages: messages,
        khachDangSoan: dangSoan.khach,
        nhanVienDangSoan: dangSoan.nhanVien,
        conTinCu: than is Map && than['conTinCu'] == true,
      );
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

  /// Lay tin nhan theo tung doan.
  ///
  /// [tuMoc] de vong tu lam moi chi xin nhung tin moi, [truocMoc] de bam xem
  /// tin cu hon. Khong truyen gi thi lay [limit] tin moi nhat.
  Future<KetQuaTaiTinNhan> getMessages(
    String conversationId, {
    String? tuMoc,
    String? truocMoc,
    int limit = soTinMoiLan,
  }) async {
    try {
      final res = await _dio.get(
        '/support-chat/$conversationId/messages',
        queryParameters: {
          if (tuMoc != null) 'tuMoc': tuMoc,
          if (truocMoc != null) 'truocMoc': truocMoc,
          'limit': limit,
        },
      );
      final data = _data(res);
      if (data is! List) {
        throw const FormatException('Danh sách tin nhắn không hợp lệ');
      }
      final dangSoan = _dangSoan(res);
      final than = res.data;
      return KetQuaTaiTinNhan(
        messages: data
            .map((item) => SupportChatMessage.fromJson(_map(item)))
            .toList(),
        khachDangSoan: dangSoan.khach,
        nhanVienDangSoan: dangSoan.nhanVien,
        conTinCu: than is Map && than['conTinCu'] == true,
      );
    } catch (error) {
      throw Exception(_message(error));
    }
  }

  /// Bao cho may chu biet minh dang go phim.
  ///
  /// Goi roi quen luon: tin hieu nay chi song vai giay, hong mot lan cung khong
  /// anh huong gi den viec nhan tin.
  Future<void> baoDangSoan(String conversationId) async {
    try {
      await _dio.post('/support-chat/$conversationId/typing');
    } catch (_) {
      // Bo qua co y: bao dang soan that bai khong duoc lam phien nguoi dung.
    }
  }

  /// Gui tin va tra ve chinh tin vua duoc tao.
  ///
  /// Can ban ghi that de man chat thay the tin tam dang hien; neu khong tin
  /// tam se nam lai mai va moi tin gui di hien thanh hai bong chat.
  Future<SupportChatMessage> sendMessage(
    String conversationId,
    String content,
  ) async {
    try {
      final res = await _dio.post(
        '/support-chat/$conversationId/messages',
        data: {'content': content},
      );
      return SupportChatMessage.fromJson(_map(_data(res)));
    } catch (error) {
      throw Exception(_message(error));
    }
  }
}

/// Ket qua mot lan mo man chat: hoi thoai va tin nhan di kem.
class SupportChatSnapshot {
  final SupportConversation conversation;
  final List<SupportChatMessage> messages;
  final bool khachDangSoan;
  final bool nhanVienDangSoan;
  final bool conTinCu;

  const SupportChatSnapshot({
    required this.conversation,
    required this.messages,
    this.khachDangSoan = false,
    this.nhanVienDangSoan = false,
    this.conTinCu = false,
  });
}
