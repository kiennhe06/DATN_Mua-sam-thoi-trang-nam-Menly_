import 'package:flutter/foundation.dart';
import '../../../../core/network/api_client.dart';

class NotificationItem {
  final String id;
  final String title;
  final String body;
  final String type;
  bool isRead;
  final DateTime createdAt;

  NotificationItem({
    required this.id,
    required this.title,
    required this.body,
    this.type = 'general',
    this.isRead = false,
    required this.createdAt,
  });

  factory NotificationItem.fromJson(Map<String, dynamic> json) {
    return NotificationItem(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      body: json['body']?.toString() ?? json['message']?.toString() ?? '',
      type: json['type']?.toString() ?? 'general',
      isRead: json['is_read'] == true,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}

/// Quan ly trang thai cho: Thong bao
/// Ket noi: GET/PATCH/DELETE /api/v1/notifications
class NotificationProvider extends ChangeNotifier {
  final ApiClient _api = ApiClient();
  List<NotificationItem> _notifications = [];
  bool _isLoading = false;

  NotificationProvider({bool autoLoad = true}) {
    if (autoLoad) loadNotifications();
  }

  List<NotificationItem> get notifications => _notifications;
  bool get isLoading => _isLoading;
  int get unreadCount => _notifications.where((n) => !n.isRead).length;

  /// Load danh sach thong bao tu backend (GET /api/v1/notifications)
  Future<void> loadNotifications() async {
    _isLoading = true;
    notifyListeners();
    try {
      final res = await _api.dio.get('/notifications');
      if (res.statusCode == 200 && res.data['data'] != null) {
        final list = res.data['data'] as List;
        _notifications = list
            .map((item) => NotificationItem.fromJson(Map<String, dynamic>.from(item)))
            .toList();
      }
    } catch (_) {
      // Khong co thong bao hoac chua dang nhap
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Danh dau 1 thong bao da doc (PATCH /api/v1/notifications/:id/read)
  Future<void> markRead(String id) async {
    final idx = _notifications.indexWhere((n) => n.id == id);
    if (idx >= 0) {
      _notifications[idx].isRead = true;
      notifyListeners();
      try {
        await _api.dio.patch('/notifications/$id/read');
      } catch (_) {}
    }
  }

  /// Danh dau tat ca da doc (PATCH /api/v1/notifications/read-all)
  Future<void> markAllRead() async {
    for (var n in _notifications) {
      n.isRead = true;
    }
    notifyListeners();
    try {
      await _api.dio.patch('/notifications/read-all');
    } catch (_) {}
  }

  /// Xoa 1 thong bao (DELETE /api/v1/notifications/:id)
  Future<void> deleteNotification(String id) async {
    _notifications.removeWhere((n) => n.id == id);
    notifyListeners();
    try {
      await _api.dio.delete('/notifications/$id');
    } catch (_) {}
  }
}
