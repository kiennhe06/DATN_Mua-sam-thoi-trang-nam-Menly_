import 'package:flutter/foundation.dart';
import '../../../../core/network/api_client.dart';
import '../../../../models/cart_item_model.dart';
import '../../../../models/order_model.dart';

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
  bool _isLoading = false;
  String _selectedStatusFilter = 'all'; // 'all', 'pending_payment', 'processing', 'shipping', 'delivered', 'canceled'

  // Staff management state (AP-QT9)
  String _staffStatusFilter = 'all';
  String _staffSearchQuery = '';

  OrderProvider() {
    loadOrders();
  }

  List<OrderModel> get allOrders => _orders;
  bool get isLoading => _isLoading;
  String get selectedStatusFilter => _selectedStatusFilter;
  String get staffStatusFilter => _staffStatusFilter;
  String get staffSearchQuery => _staffSearchQuery;

  // =================== AP-DH2 & TM07: ĐƠN CỦA TÔI ===================

  /// Tai danh sach don hang tu Backend API (GET /api/v1/orders)
  Future<void> loadOrders() async {
    _isLoading = true;
    notifyListeners();

    try {
      final res = await _api.dio.get('/orders');
      if (res.statusCode == 200 && res.data != null) {
        final rawList = res.data['data'] ?? res.data;
        if (rawList is List) {
          _orders = rawList
              .map((item) => OrderModel.fromJson(Map<String, dynamic>.from(item)))
              .toList();
        }
      }
    } catch (_) {
      // Giu nguyen don hang cuc bo khi backend chua san sang hoac khong co mang
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

  Future<bool> cancelOrderApi(String orderId, {String reason = 'Khách hàng yêu cầu hủy'}) =>
      cancelOrder(orderId, reason: reason);

  /// Huy don hang (AP-DH2) - Dong bo PUT /api/v1/orders/:id/cancel
  Future<bool> cancelOrder(String orderId, {String reason = 'Khách hàng yêu cầu hủy'}) async {
    final index = _orders.indexWhere((o) => o.id == orderId);
    if (index >= 0) {
      final order = _orders[index];
      if (order.canCancel) {
        order.status = OrderStatus.canceled;
        order.cancelReason = reason;
        notifyListeners();

        try {
          await _api.dio.put('/orders/$orderId/cancel', data: {'reason': reason});
        } catch (_) {}

        return true;
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
    final orderItems = items.map((item) {
      return OrderItemModel(
        id: 'ord-item-${DateTime.now().millisecondsSinceEpoch}-${item.id}',
        productName: item.product.name,
        size: item.size,
        color: item.color,
        unitPrice: item.product.price,
        quantity: item.quantity,
        thumbnailUrl: item.product.thumbnailUrl,
      );
    }).toList();

    OrderModel createdOrder = OrderModel(
      id: 'ord-${DateTime.now().millisecondsSinceEpoch}',
      code: 'MNL-${DateTime.now().millisecondsSinceEpoch % 100000}',
      status: paymentMethod == 'vnpay' ? OrderStatus.pendingPayment : OrderStatus.processing,
      paymentMethod: paymentMethod,
      isPaid: false,
      subtotal: subtotal,
      discountAmount: discountAmount,
      shippingFee: shippingFee,
      total: total,
      shipName: shipName,
      shipPhone: shipPhone,
      shipAddress: shipAddress,
      createdAt: DateTime.now(),
      items: orderItems,
    );

    // Goi Backend API POST /api/v1/orders
    try {
      final res = await _api.dio.post('/orders', data: {
        'payment_method': paymentMethod,
        'ship_name': shipName,
        'ship_phone': shipPhone,
        'ship_address': shipAddress,
        'subtotal': subtotal,
        'shipping_fee': shippingFee,
        'discount_amount': discountAmount,
        'total': total,
        if (voucherCode != null && voucherCode.isNotEmpty) 'voucher_code': voucherCode,
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

      if ((res.statusCode == 200 || res.statusCode == 201) && res.data != null) {
        final data = res.data['data'] ?? res.data;
        if (data is Map<String, dynamic>) {
          createdOrder = OrderModel.fromJson(data);
        }
      }
    } catch (_) {}

    _orders.insert(0, createdOrder);
    notifyListeners();
    return createdOrder;
  }

  /// AP-TT1: Xac nhan thanh toan VNPay thanh cong
  void markAsPaidVNPay(String orderId) {
    final index = _orders.indexWhere((o) => o.id == orderId);
    if (index >= 0) {
      final order = _orders[index];
      _orders[index] = OrderModel(
        id: order.id,
        code: order.code,
        status: OrderStatus.processing,
        paymentMethod: 'vnpay',
        isPaid: true,
        subtotal: order.subtotal,
        discountAmount: order.discountAmount,
        shippingFee: order.shippingFee,
        total: order.total,
        shipName: order.shipName,
        shipPhone: order.shipPhone,
        shipAddress: order.shipAddress,
        createdAt: order.createdAt,
        items: order.items,
        cancelReason: order.cancelReason,
      );
      notifyListeners();
    }
  }

  // =================== AP-QT9: QUẢN LÝ ĐƠN CHO NHÂN VIÊN TRÊN APP ===================

  /// Danh sach don hang cho nhan vien quan ly (co tim kiem va loc)
  List<OrderModel> get staffOrders {
    List<OrderModel> result = List.from(_orders);

    if (_staffStatusFilter != 'all') {
      result = result.where((o) => o.status.value == _staffStatusFilter).toList();
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
  void updateOrderStatusByStaff(String orderId, OrderStatus nextStatus) {
    final index = _orders.indexWhere((o) => o.id == orderId);
    if (index >= 0) {
      _orders[index].status = nextStatus;
      notifyListeners();
    }
  }

  /// Thong ke tong quan cho nhan vien
  Map<String, dynamic> get staffStatistics {
    final totalRevenue = _orders
        .where((o) => o.status != OrderStatus.canceled)
        .fold(0, (sum, o) => sum + o.total);

    final pendingCount = _orders.where((o) => o.status == OrderStatus.processing).length;
    final shippingCount = _orders.where((o) => o.status == OrderStatus.shipping).length;
    final deliveredCount = _orders.where((o) => o.status == OrderStatus.delivered).length;

    return {
      'totalOrders': _orders.length,
      'totalRevenue': totalRevenue,
      'pendingCount': pendingCount,
      'shippingCount': shippingCount,
      'deliveredCount': deliveredCount,
    };
  }
}
