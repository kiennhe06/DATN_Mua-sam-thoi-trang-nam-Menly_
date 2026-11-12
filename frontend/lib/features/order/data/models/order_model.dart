import 'package:menly_app/core/utils/image_url.dart';

/// Item trong don hang
class OrderItemModel {
  final String id;
  final String productName;
  final String size;
  final String color;
  final int unitPrice;
  final int quantity;
  final String thumbnailUrl;

  const OrderItemModel({
    required this.id,
    required this.productName,
    required this.size,
    required this.color,
    required this.unitPrice,
    required this.quantity,
    this.thumbnailUrl = '',
  });

  int get subtotal => unitPrice * quantity;

  factory OrderItemModel.fromJson(Map<String, dynamic> json) {
    return OrderItemModel(
      id: json['id']?.toString() ?? '',
      productName: json['product_name']?.toString() ?? json['productName']?.toString() ?? '',
      size: json['size']?.toString() ?? '',
      color: json['color']?.toString() ?? '',
      unitPrice: (json['unit_price'] is num) ? (json['unit_price'] as num).toInt() : 0,
      quantity: (json['quantity'] is num) ? (json['quantity'] as num).toInt() : 1,
      thumbnailUrl: duongDanAnhThat(
        json['thumbnail_url'] ?? json['thumbnailUrl'],
      ),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'product_name': productName,
    'size': size,
    'color': color,
    'unit_price': unitPrice,
    'quantity': quantity,
    'thumbnail_url': thumbnailUrl,
  };
}

/// Trang thai don hang
enum OrderStatus {
  pendingPayment, // Chờ thanh toán
  paid,            // Đã thanh toán
  processing,     // Đang xử lý
  shipping,       // Đang giao
  delivered,      // Đã giao
  completed,      // Hoàn tất
  canceled,       // Đã hủy
  expired,        // Hết hạn thanh toán
  returned,       // Trả hàng
}

extension OrderStatusExtension on OrderStatus {
  String get value {
    switch (this) {
      case OrderStatus.pendingPayment:
        return 'pending_payment';
      case OrderStatus.paid:
        return 'paid';
      case OrderStatus.processing:
        return 'processing';
      case OrderStatus.shipping:
        return 'shipping';
      case OrderStatus.delivered:
        return 'delivered';
      case OrderStatus.canceled:
        return 'cancelled';
      case OrderStatus.completed:
        return 'completed';
      case OrderStatus.expired:
        return 'expired';
      case OrderStatus.returned:
        return 'returned';
    }
  }

  String get label {
    switch (this) {
      case OrderStatus.pendingPayment:
        return 'Chờ thanh toán';
      case OrderStatus.paid:
        return 'Đã thanh toán';
      case OrderStatus.processing:
        return 'Đang xử lý';
      case OrderStatus.shipping:
        return 'Đang giao hàng';
      case OrderStatus.delivered:
        return 'Đã giao hàng';
      case OrderStatus.canceled:
        return 'Đã hủy';
      case OrderStatus.completed:
        return 'Hoàn tất';
      case OrderStatus.expired:
        return 'Hết hạn thanh toán';
      case OrderStatus.returned:
        return 'Đã trả hàng';
    }
  }

  static OrderStatus fromString(String val) {
    switch (val.toLowerCase()) {
      case 'pending_payment':
      case 'cho_thanh_toan':
        return OrderStatus.pendingPayment;
      case 'processing':
      case 'dang_xu_ly':
        return OrderStatus.processing;
      case 'shipping':
      case 'dang_giao':
        return OrderStatus.shipping;
      case 'delivered':
      case 'da_giao':
        return OrderStatus.delivered;
      case 'canceled':
      case 'cancelled':
      case 'da_huy':
        return OrderStatus.canceled;
      case 'paid':
        return OrderStatus.paid;
      case 'completed':
        return OrderStatus.completed;
      case 'expired':
        return OrderStatus.expired;
      case 'returned':
      case 'tra_hang':
        return OrderStatus.returned;
      default:
        return OrderStatus.processing;
    }
  }
}

/// Model don hang (AP-DH2, TM07, AP-QT9, AP-TT1)
/// Mot lan doi trang thai DA THUC SU xay ra, kem moc thoi gian.
///
/// Dung de ve hanh trinh giao hang theo du lieu that. Truoc day man chi tiet
/// suy ra ca hanh trinh tu mot trang thai hien tai, nen don vua dat da hien
/// san may buoc nhu the kho da xac nhan va dong goi xong.
class OrderStatusEvent {
  final OrderStatus fromStatus;
  final OrderStatus toStatus;
  final DateTime at;

  const OrderStatusEvent({
    required this.fromStatus,
    required this.toStatus,
    required this.at,
  });

  factory OrderStatusEvent.fromJson(Map<String, dynamic> json) {
    return OrderStatusEvent(
      fromStatus: OrderStatusExtension.fromString(
          json['from_status']?.toString() ?? 'processing'),
      toStatus: OrderStatusExtension.fromString(
          json['to_status']?.toString() ?? 'processing'),
      at: DateTime.tryParse(json['created_at']?.toString() ?? '') ??
          DateTime.now(),
    );
  }
}

class OrderModel {
  final String id;
  final String code;
  OrderStatus status;
  final String paymentMethod; // 'cod' hoac 'vnpay'
  final bool isPaid;
  final int subtotal;
  final int discountAmount;
  final int shippingFee;
  final int total;
  final String shipName;
  final String shipPhone;
  final String shipAddress;
  final DateTime createdAt;
  final List<OrderItemModel> items;
  /// Cac lan doi trang thai da ghi lai, xep theo thoi gian tang dan.
  final List<OrderStatusEvent> statusHistory;

  /// Ma cua tat ca don duoc tao trong cung lan dat hang.
  ///
  /// Moi san pham tao mot don rieng, nen mot lan bam dat hang co the sinh ra
  /// nhieu don. Chi co gia tri ngay sau khi dat, khong luu lai.
  final List<String> splitOrderCodes;
  String? cancelReason;

  /// Don da duoc hoan tien qua yeu cau tra hang chua.
  ///
  /// Bang orders khong co trang thai "da hoan tien", nen phai mang rieng co
  /// nay tu may chu. Khong co no thi don da hoan tien van hien "Da giao hang"
  /// voi khach - nhin nhu shop chua tra lai tien.
  final bool daHoanTien;

  /// Thoi diem hoan tien, de ve dung moc tren hanh trinh don hang.
  final DateTime? hoanTienLuc;

  OrderModel({
    required this.id,
    required this.code,
    required this.status,
    required this.paymentMethod,
    this.isPaid = false,
    required this.subtotal,
    this.discountAmount = 0,
    this.shippingFee = 0,
    required this.total,
    required this.shipName,
    required this.shipPhone,
    required this.shipAddress,
    required this.createdAt,
    required this.items,
    this.statusHistory = const [],
    this.splitOrderCodes = const [],
    this.cancelReason,
    this.daHoanTien = false,
    this.hoanTienLuc,
  });

  /// Nhan trang thai de hien cho nguoi dung.
  ///
  /// Dung cai nay o moi cho ve chip trang thai, dung dung status.label: don da
  /// hoan tien phai noi la da hoan tien chu khong phai trang thai giao hang cu.
  String get nhanTrangThai =>
      daHoanTien ? 'Đã hoàn tiền' : status.label;

  OrderModel copyWith({
    String? id,
    String? code,
    OrderStatus? status,
    String? paymentMethod,
    bool? isPaid,
    int? subtotal,
    int? discountAmount,
    int? shippingFee,
    int? total,
    String? shipName,
    String? shipPhone,
    String? shipAddress,
    DateTime? createdAt,
    List<OrderItemModel>? items,
    String? cancelReason,
    bool? daHoanTien,
    DateTime? hoanTienLuc,
  }) {
    return OrderModel(
      id: id ?? this.id,
      code: code ?? this.code,
      status: status ?? this.status,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      isPaid: isPaid ?? this.isPaid,
      subtotal: subtotal ?? this.subtotal,
      discountAmount: discountAmount ?? this.discountAmount,
      shippingFee: shippingFee ?? this.shippingFee,
      total: total ?? this.total,
      shipName: shipName ?? this.shipName,
      shipPhone: shipPhone ?? this.shipPhone,
      shipAddress: shipAddress ?? this.shipAddress,
      createdAt: createdAt ?? this.createdAt,
      items: items ?? this.items,
      cancelReason: cancelReason ?? this.cancelReason,
      daHoanTien: daHoanTien ?? this.daHoanTien,
      hoanTienLuc: hoanTienLuc ?? this.hoanTienLuc,
    );
  }

  /// Co the huy don khong? (Chi cho phep huy khi con o trang thai cho thanh toan hoac dang xu ly)
  bool get canCancel =>
      status == OrderStatus.pendingPayment || status == OrderStatus.processing;

  /// Co the gui yeu cau tra hang khi don da giao / hoan tat.
  ///
  /// Don da hoan tien thi thoi: may chu cung chan lan tra hang thu hai, de nut
  /// hien ra chi khien nguoi dung bam vao roi an loi.
  bool get canReturn =>
      !daHoanTien &&
      (status == OrderStatus.delivered || status == OrderStatus.completed);

  /// Chi danh gia duoc khi da nhan hang, giong quy tac o may chu.
  bool get canReview =>
      status == OrderStatus.delivered || status == OrderStatus.completed;

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    var rawItems = json['items'] ?? json['order_items'];
    List<OrderItemModel> parsedItems = [];
    if (rawItems is List) {
      parsedItems = rawItems
          .map((i) => OrderItemModel.fromJson(Map<String, dynamic>.from(i)))
          .toList();
    }
    final rawHistory = json['order_status_history'];
    final parsedHistory = rawHistory is List
        ? (rawHistory
            .map((item) =>
                OrderStatusEvent.fromJson(Map<String, dynamic>.from(item)))
            .toList()
          ..sort((a, b) => a.at.compareTo(b.at)))
        : <OrderStatusEvent>[];

    return OrderModel(
      id: json['id']?.toString() ?? '',
      code: json['code']?.toString() ?? 'MNL-${DateTime.now().millisecondsSinceEpoch % 100000}',
      status: OrderStatusExtension.fromString(json['status']?.toString() ?? 'processing'),
      paymentMethod: json['payment_method']?.toString() ?? 'cod',
      isPaid: json['is_paid'] ?? false,
      subtotal: (json['subtotal'] is num) ? (json['subtotal'] as num).toInt() : 0,
      discountAmount: (json['discount_amount'] is num) ? (json['discount_amount'] as num).toInt() : 0,
      // Phi ship la so da luu cung don hang; thieu truong thi de 0 chu khong
      // doan mot muc phi, vi doan sai se lam tong tien hien ra khong khop.
      shippingFee: (json['shipping_fee'] is num) ? (json['shipping_fee'] as num).toInt() : 0,
      total: (json['total'] is num) ? (json['total'] as num).toInt() : 0,
      shipName: json['ship_name']?.toString() ?? '',
      shipPhone: json['ship_phone']?.toString() ?? '',
      shipAddress: json['ship_address']?.toString() ?? '',
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
      items: parsedItems,
      statusHistory: parsedHistory,
      splitOrderCodes: json['split_order_codes'] is List
          ? (json['split_order_codes'] as List).map((e) => e.toString()).toList()
          : const [],
      cancelReason: json['cancel_reason']?.toString(),
      daHoanTien: json['refunded'] == true,
      hoanTienLuc: json['refunded_at'] != null
          ? DateTime.tryParse(json['refunded_at'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'code': code,
    'status': status.value,
    'payment_method': paymentMethod,
    'is_paid': isPaid,
    'subtotal': subtotal,
    'discount_amount': discountAmount,
    'shipping_fee': shippingFee,
    'total': total,
    'ship_name': shipName,
    'ship_phone': shipPhone,
    'ship_address': shipAddress,
    'created_at': createdAt.toIso8601String(),
    'items': items.map((i) => i.toJson()).toList(),
    'cancel_reason': cancelReason,
  };

  String get statusStr => status.value;
  String get recipientName => shipName;
  String get recipientPhone => shipPhone;
  String get recipientAddress => shipAddress;
  String get shippingAddress => shipAddress;
}

typedef Order = OrderModel;
typedef OrderItem = OrderItemModel;
