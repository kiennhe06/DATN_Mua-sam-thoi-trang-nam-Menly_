import 'package:flutter/foundation.dart';
import '../../../../core/network/api_client.dart';
import '../../data/default_notifications.dart';
import '../../data/models/notification_model.dart';

export '../../data/models/notification_model.dart';

/// Provider quản lý thông báo cho Menly (AP-TB1)
/// Hỗ trợ lọc theo loại thông báo: Tất cả, Đơn hàng, Khuyến mãi, Hệ thống, Chưa đọc
/// Kết nối API: GET/POST/PATCH/DELETE /api/v1/notifications
class NotificationProvider extends ChangeNotifier {
  final ApiClient _api = ApiClient();

  static const String filterAll = 'all';
  static const String filterOrder = 'order';
  static const String filterPromo = 'promo';
  static const String filterSystem = 'system';
  static const String filterUnread = 'unread';

  List<NotificationModel> _notifications = [];
  bool _isLoading = false;
  String _selectedFilter = filterAll;

  NotificationProvider({bool autoLoad = true}) {
    // Khởi tạo trước với dữ liệu mẫu phong phú để giao diện luôn đầy đủ
    _notifications = getInitialSampleNotifications();
    if (autoLoad) {
      loadNotifications();
    }
  }

  List<NotificationModel> get notifications => _notifications;
  bool get isLoading => _isLoading;
  String get selectedFilter => _selectedFilter;

  /// Danh sách thông báo sau khi lọc theo loại đang chọn
  List<NotificationModel> get filteredNotifications {
    switch (_selectedFilter) {
      case filterOrder:
        return _notifications.where((n) => n.type == 'order').toList();
      case filterPromo:
        return _notifications
            .where((n) => n.type == 'promo' || n.type == 'voucher')
            .toList();
      case filterSystem:
        return _notifications
            .where((n) => n.type == 'system' || n.type == 'account')
            .toList();
      case filterUnread:
        return _notifications.where((n) => !n.isRead).toList();
      case filterAll:
      default:
        return _notifications;
    }
  }

  // Thống kê số lượng theo từng loại
  int get totalCount => _notifications.length;
  int get unreadCount => _notifications.where((n) => !n.isRead).length;
  int get orderCount => _notifications.where((n) => n.type == 'order').length;
  int get promoCount => _notifications
      .where((n) => n.type == 'promo' || n.type == 'voucher')
      .length;
  int get systemCount => _notifications
      .where((n) => n.type == 'system' || n.type == 'account')
      .length;

  int getCountForFilter(String filter) {
    switch (filter) {
      case filterOrder:
        return orderCount;
      case filterPromo:
        return promoCount;
      case filterSystem:
        return systemCount;
      case filterUnread:
        return unreadCount;
      case filterAll:
      default:
        return totalCount;
    }
  }

  /// Thay đổi bộ lọc hiện tại
  void setFilter(String filter) {
    if (_selectedFilter != filter) {
      _selectedFilter = filter;
      notifyListeners();
    }
  }

  /// Load danh sách thông báo từ backend (GET /api/v1/notifications)
  Future<void> loadNotifications() async {
    _isLoading = true;
    notifyListeners();
    try {
      final res = await _api.dio.get('/notifications');
      if (res.statusCode == 200 && res.data['data'] != null) {
        final list = res.data['data'] as List;
        final serverItems = list
            .map((item) =>
                NotificationModel.fromJson(Map<String, dynamic>.from(item)))
            .toList();

        if (serverItems.isNotEmpty) {
          // Kết hợp thông báo server với các thông báo hệ thống mặc định nếu chưa trùng
          final serverIds = serverItems.map((e) => e.id).toSet();
          final retained =
              _notifications.where((n) => !serverIds.contains(n.id)).toList();
          _notifications = [...serverItems, ...retained];
        }
      }
    } catch (_) {
      // Dùng dữ liệu hiện tại nếu offline hoặc chưa đăng nhập
      if (_notifications.isEmpty) {
        _notifications = getInitialSampleNotifications();
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Thêm một thông báo mới từ bất kỳ nơi nào trong ứng dụng
  /// (Khi đặt hàng, hủy thanh toán, áp voucher, cập nhật địa chỉ...)
  Future<void> addNotification({
    required String title,
    required String body,
    String type = 'system',
    Map<String, dynamic>? data,
  }) async {
    final newItem = NotificationModel(
      id: 'notif-${DateTime.now().millisecondsSinceEpoch}',
      title: title,
      body: body,
      type: type,
      isRead: false,
      createdAt: DateTime.now(),
      data: data,
    );

    _notifications.insert(0, newItem);
    notifyListeners();

    // Đồng bộ lên backend nếu đã đăng nhập
    try {
      final backendType = (type == 'order' || type == 'promo' || type == 'system')
          ? type
          : 'system';
      await _api.dio.post('/notifications', data: {
        'title': title,
        'body': body,
        'type': backendType,
        if (data != null) 'data': data,
      });
    } catch (_) {}
  }

  /// Đánh dấu 1 thông báo đã đọc (PATCH /api/v1/notifications/:id/read)
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

  /// Đánh dấu tất cả đã đọc (PATCH /api/v1/notifications/read-all)
  Future<void> markAllRead() async {
    for (var n in _notifications) {
      n.isRead = true;
    }
    notifyListeners();
    try {
      await _api.dio.patch('/notifications/read-all');
    } catch (_) {}
  }

  /// Xóa 1 thông báo (DELETE /api/v1/notifications/:id)
  Future<void> deleteNotification(String id) async {
    _notifications.removeWhere((n) => n.id == id);
    notifyListeners();
    try {
      await _api.dio.delete('/notifications/$id');
    } catch (_) {}
  }

  /// Xóa toàn bộ thông báo đã đọc
  void clearReadNotifications() {
    _notifications.removeWhere((n) => n.isRead);
    notifyListeners();
  }
}
