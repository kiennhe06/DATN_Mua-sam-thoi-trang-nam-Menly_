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
      productName: json['product_name']?.toString() ?? '',
      size: json['size']?.toString() ?? 'M',
      color: json['color']?.toString() ?? 'Đen',
      unitPrice: (json['unit_price'] is num) ? (json['unit_price'] as num).toInt() : 0,
      quantity: (json['quantity'] is num) ? (json['quantity'] as num).toInt() : 1,
      thumbnailUrl: (json['thumbnail_url'] != null && json['thumbnail_url'].toString().isNotEmpty && !json['thumbnail_url'].toString().contains('picsum'))
          ? json['thumbnail_url'].toString()
          : (json['thumbnailUrl'] != null && json['thumbnailUrl'].toString().isNotEmpty && !json['thumbnailUrl'].toString().contains('picsum'))
              ? json['thumbnailUrl'].toString()
              : 'https://images.unsplash.com/photo-1602810318383-e386cc2a3ccf?w=500&auto=format&fit=crop',
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
  String? cancelReason;

  OrderModel({
    required this.id,
    required this.code,
    required this.status,
    required this.paymentMethod,
    this.isPaid = false,
    required this.subtotal,
    this.discountAmount = 0,
    this.shippingFee = 25000,
    required this.total,
    required this.shipName,
    required this.shipPhone,
    required this.shipAddress,
    required this.createdAt,
    required this.items,
    this.cancelReason,
  });

  /// Co the huy don khong? (Chi cho phep huy khi con o trang thai cho thanh toan hoac dang xu ly)
  bool get canCancel =>
      status == OrderStatus.pendingPayment || status == OrderStatus.processing;

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    var rawItems = json['items'] ?? json['order_items'];
    List<OrderItemModel> parsedItems = [];
    if (rawItems is List) {
      parsedItems = rawItems
          .map((i) => OrderItemModel.fromJson(Map<String, dynamic>.from(i)))
          .toList();
    }
    return OrderModel(
      id: json['id']?.toString() ?? '',
      code: json['code']?.toString() ?? 'MNL-${DateTime.now().millisecondsSinceEpoch % 100000}',
      status: OrderStatusExtension.fromString(json['status']?.toString() ?? 'processing'),
      paymentMethod: json['payment_method']?.toString() ?? 'cod',
      isPaid: json['is_paid'] ?? false,
      subtotal: (json['subtotal'] is num) ? (json['subtotal'] as num).toInt() : 0,
      discountAmount: (json['discount_amount'] is num) ? (json['discount_amount'] as num).toInt() : 0,
      shippingFee: (json['shipping_fee'] is num) ? (json['shipping_fee'] as num).toInt() : 25000,
      total: (json['total'] is num) ? (json['total'] as num).toInt() : 0,
      shipName: json['ship_name']?.toString() ?? '',
      shipPhone: json['ship_phone']?.toString() ?? '',
      shipAddress: json['ship_address']?.toString() ?? '',
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
      items: parsedItems,
      cancelReason: json['cancel_reason']?.toString(),
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
