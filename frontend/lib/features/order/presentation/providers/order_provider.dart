import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/network/api_client.dart';
import 'package:menly_app/features/cart/data/models/cart_item_model.dart';
import 'package:menly_app/features/order/data/models/order_model.dart';
import 'package:menly_app/features/order/data/models/order_return_model.dart';

/// Provider quan ly Don hang khach hang & Don hang nhan vien tren app
/// Phu trach boi: Thanh Toan (AP-DH2, TM07, AP-QT9, AP-TT1)
/// Ket noi truc tiep cac API:
/// - GET /api/v1/orders (Danh sach don cua toi)
/// - POST /api/v1/orders (Tao don hang moi)
/// - GET /api/v1/orders/:id (Chi tiet don hang)
/// - PUT /api/v1/orders/:id/cancel (Huy don hang)
class OrderProvider extends ChangeNotifier {
  final ApiClient _api = ApiClient();
  List<OrderModel> _orders = [];
  List<OrderReturnModel> _returns = [];
  bool _isLoading = false;
  String? _errorMessage;
  String _selectedStatusFilter =
      'all'; // 'all', 'pending_payment', 'processing', 'shipping', 'delivered', 'canceled'

  // Staff management state (AP-QT9)
  String _staffStatusFilter = 'all';
  String _staffSearchQuery = '';

  OrderProvider() {
    loadOrders();
  }

  List<OrderModel> get allOrders => _orders;
  List<OrderReturnModel> get returnRequests => _returns;
  bool get isLoading => _isLoading;
  String get selectedStatusFilter => _selectedStatusFilter;
  String get staffStatusFilter => _staffStatusFilter;
  String get staffSearchQuery => _staffSearchQuery;
  String? get errorMessage => _errorMessage;

  // =================== AP-DH2 & TM07: ĐƠN CỦA TÔI ===================

  /// Tai danh sach don hang tu Backend API (GET /api/v1/orders)
  Future<void> loadOrders() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final res = await _api.dio.get('/orders');
      if (res.statusCode == 200 && res.data != null) {
        final rawList = res.data['data'] ?? res.data;
        if (rawList is List) {
          _orders = rawList
              .map((item) =>
                  OrderModel.fromJson(Map<String, dynamic>.from(item)))
              .toList();
        }
      }
    } catch (error) {
      _errorMessage = 'Không thể tải đơn hàng: $error';
    } finally {
      _isLoading = false;
      notifyListeners();
      await loadReturnRequests();
    }
  }

  Future<void> loadStaffOrders() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final response = await _api.dio.get('/orders/staff');
      final rawList = response.data?['data'];
      if (rawList is! List) {
        throw StateError('Backend trả về danh sách đơn hàng không hợp lệ');
      }
      _orders = rawList
          .map((item) => OrderModel.fromJson(Map<String, dynamic>.from(item)))
          .toList();
    } catch (error) {
      _errorMessage = 'Không thể tải danh sách đơn hàng: $error';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Danh sach don hang da loc theo trang thai (TM07)
  List<OrderModel> get myFilteredOrders {
    if (_selectedStatusFilter == 'all') {
      return _orders;
    }
    if (_selectedStatusFilter == 'canceled' || _selectedStatusFilter == 'cancelled') {
      return _orders.where((o) => o.status == OrderStatus.canceled).toList();
    }
    return _orders.where((o) => o.status.value == _selectedStatusFilter).toList();
  }

  /// Dem so luong don hang theo tung trang thai de hien badge tren tab bar (TM07)
  int countByStatus(String statusValue) {
    if (statusValue == 'all') return _orders.length;
    if (statusValue == 'canceled' || statusValue == 'cancelled') {
      return _orders.where((o) => o.status == OrderStatus.canceled).length;
    }
    return _orders.where((o) => o.status.value == statusValue).length;
  }

  /// Dat trang thai loc (TM07)
  void setStatusFilter(String status) {
    _selectedStatusFilter = status;
    notifyListeners();
  }

  /// Tim don hang theo ID
  OrderModel? getOrderById(String orderId) {
    try {
      return _orders.firstWhere((o) => o.id == orderId);
    } catch (_) {
      return null;
    }
  }

  OrderModel? findById(String orderId) => getOrderById(orderId);

  OrderReturnModel? returnForOrder(String orderId) {
    try {
      return _returns.firstWhere((item) => item.orderId == orderId);
    } catch (_) {
      return null;
    }
  }

  bool canRequestReturn(OrderModel order) {
    if (!order.canReturn) return false;
    final existing = returnForOrder(order.id);
    return existing == null || !existing.isOpen;
  }

  Future<void> loadReturnRequests() async {
    try {
      final res = await _api.dio.get('/order-returns');
      final rawList = res.data?['data'] ?? res.data;
      if (rawList is List) {
        _returns = rawList
            .map((item) => OrderReturnModel.fromJson(Map<String, dynamic>.from(item)))
            .toList();
      }
    } catch (_) {
      // Giữ danh sách cũ nếu API lỗi, không chặn màn đơn hàng
    } finally {
      notifyListeners();
    }
  }

  Future<OrderReturnModel> submitReturnRequest({
    required String orderId,
    required String reason,
    List<XFile> images = const [],
  }) async {
    if (reason.trim().isEmpty) {
      throw Exception('Vui lòng nhập lý do trả hàng');
    }
    if (images.isEmpty) {
      throw Exception('Vui lòng đính kèm ít nhất 1 hình ảnh minh chứng');
    }

    final form = FormData();
    form.fields.add(MapEntry('orderId', orderId));
    form.fields.add(MapEntry('reason', reason.trim()));

    for (final image in images.take(5)) {
      final bytes = await image.readAsBytes();
      form.files.add(
        MapEntry('images', MultipartFile.fromBytes(bytes, filename: image.name)),
      );
    }

    try {
      final res = await _api.dio.post(
        '/order-returns',
        data: form,
        options: Options(contentType: 'multipart/form-data'),
      );
      final data = res.data['data'] ?? res.data;
      final created = OrderReturnModel.fromJson(Map<String, dynamic>.from(data));
      _returns.removeWhere((item) => item.orderId == created.orderId && !item.isOpen);
      _returns.insert(0, created);
      _errorMessage = null;
      notifyListeners();
      return created;
    } on DioException catch (e) {
      final data = e.response?.data;
      if (data is Map && data['error'] != null) {
        throw Exception(data['error'].toString());
      }
      throw Exception('Không thể gửi yêu cầu trả hàng. Vui lòng thử lại.');
    }
  }

  Future<bool> cancelOrderApi(String orderId,
          {String reason = 'Khách hàng yêu cầu hủy'}) =>
      cancelOrder(orderId, reason: reason);

  /// Huy don hang (AP-DH2) - Dong bo PUT /api/v1/orders/:id/cancel
  Future<bool> cancelOrder(String orderId,
      {String reason = 'Khách hàng yêu cầu hủy'}) async {
    final index = _orders.indexWhere((o) => o.id == orderId);
    if (index >= 0) {
      final order = _orders[index];
      if (order.canCancel) {
        try {
          final response = await _api.dio
              .put('/orders/$orderId/cancel', data: {'reason': reason});
          final rawOrder = response.data?['data'];
          if (rawOrder is! Map)
            throw StateError('Backend không trả về đơn hàng đã cập nhật');
          _orders[index] =
              OrderModel.fromJson(Map<String, dynamic>.from(rawOrder));
          _errorMessage = null;
          notifyListeners();
          return true;
        } catch (error) {
          _errorMessage = 'Không thể hủy đơn hàng: $error';
          notifyListeners();
          return false;
        }
      }
    }
    return false;
  }

  /// Tao don hang moi (tu gio hang hoac mua ngay) - Ket noi POST /api/v1/orders
  Future<OrderModel> createOrder({
    required List<CartItemModel> items,
    required String shipName,
    required String shipPhone,
    required String shipAddress,
    required String paymentMethod, // 'cod' hoac 'vnpay'
    required int subtotal,
    required int discountAmount,
    required int shippingFee,
    required int total,
    String? voucherCode,
  }) async {
    final response = await _api.dio.post('/orders', data: {
      'payment_method': paymentMethod,
      'ship_name': shipName,
      'ship_phone': shipPhone,
      'ship_address': shipAddress,
      'subtotal': subtotal,
      'shipping_fee': shippingFee,
      'discount_amount': discountAmount,
      'total': total,
      'idempotency_key': 'app-${DateTime.now().microsecondsSinceEpoch}',
      if (voucherCode != null && voucherCode.isNotEmpty)
        'voucher_code': voucherCode,
      'items': items
          .map((i) => {
                'variant_id': i.variantId,
                'quantity': i.quantity,
                'product_name': i.product.name,
                'size': i.size,
                'color': i.color,
                'unit_price': i.product.price,
              })
          .toList(),
    });

    final rawOrder = response.data?['data'];
    if (rawOrder is! Map)
      throw StateError('Backend không trả về đơn hàng vừa tạo');
    final createdOrder =
        OrderModel.fromJson(Map<String, dynamic>.from(rawOrder));
    if (createdOrder.id.isEmpty)
      throw StateError('Backend trả về mã đơn hàng không hợp lệ');
    _orders.insert(0, createdOrder);
    _errorMessage = null;
    notifyListeners();
    return createdOrder;
  }

  /// Làm mới trạng thái đơn từ backend sau khi backend xác thực kết quả VNPay.
  Future<void> refreshOrderAfterPayment(String orderId) async {
    try {
      final response = await _api.dio.get('/orders/$orderId');
      final rawOrder = response.data?['data'];
      if (rawOrder is! Map) {
        throw StateError('Backend không trả về đơn hàng đã thanh toán');
      }

      final updatedOrder =
          OrderModel.fromJson(Map<String, dynamic>.from(rawOrder));
      final index = _orders.indexWhere((order) => order.id == updatedOrder.id);
      if (index < 0) {
        _orders.insert(0, updatedOrder);
      } else {
        _orders[index] = updatedOrder;
      }
      _errorMessage = null;
    } catch (error) {
      _errorMessage = 'Không thể làm mới trạng thái đơn hàng: $error';
    } finally {
      notifyListeners();
    }
  }

  // =================== AP-QT9: QUẢN LÝ ĐƠN CHO NHÂN VIÊN TRÊN APP ===================

  /// Danh sach don hang cho nhan vien quan ly (co tim kiem va loc)
  List<OrderModel> get staffOrders {
    List<OrderModel> result = List.from(_orders);

    if (_staffStatusFilter != 'all') {
      result =
          result.where((o) => o.status.value == _staffStatusFilter).toList();
    }

    if (_staffSearchQuery.trim().isNotEmpty) {
      final q = _staffSearchQuery.trim().toLowerCase();
      result = result.where((o) {
        return o.code.toLowerCase().contains(q) ||
            o.shipPhone.contains(q) ||
            o.shipName.toLowerCase().contains(q);
      }).toList();
    }

    return result;
  }

  void setStaffStatusFilter(String status) {
    _staffStatusFilter = status;
    notifyListeners();
  }

  void setStaffSearchQuery(String query) {
    _staffSearchQuery = query;
    notifyListeners();
  }

  /// Nhan vien chuyen trang thai don hang (AP-QT9)
  Future<bool> updateOrderStatusByStaff(
      String orderId, OrderStatus nextStatus) async {
    final index = _orders.indexWhere((o) => o.id == orderId);
    if (index >= 0) {
      try {
        final response = await _api.dio.put('/orders/$orderId/status', data: {
          'status': nextStatus.value,
        });
        final rawOrder = response.data?['data'];
        if (rawOrder is! Map)
          throw StateError('Backend không trả về đơn hàng đã cập nhật');
        _orders[index] =
            OrderModel.fromJson(Map<String, dynamic>.from(rawOrder));
        _errorMessage = null;
        notifyListeners();
        return true;
      } catch (error) {
        _errorMessage = 'Không thể cập nhật trạng thái đơn hàng: $error';
        notifyListeners();
      }
    }
    return false;
  }

  /// Thong ke tong quan cho nhan vien
  Map<String, dynamic> get staffStatistics {
    final totalRevenue = _orders
        .where((o) =>
            o.status != OrderStatus.canceled && o.status != OrderStatus.expired)
        .fold(0, (sum, o) => sum + o.total);

    final pendingCount = _orders
        .where((o) =>
            o.status == OrderStatus.paid || o.status == OrderStatus.processing)
        .length;
    final shippingCount =
        _orders.where((o) => o.status == OrderStatus.shipping).length;
    final deliveredCount =
        _orders.where((o) => o.status == OrderStatus.delivered).length;

    return {
      'totalOrders': _orders.length,
      'totalRevenue': totalRevenue,
      'pendingCount': pendingCount,
      'shippingCount': shippingCount,
      'deliveredCount': deliveredCount,
    };
  }
}
