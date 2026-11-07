class OrderReturnModel {
  final String id;
  final String orderId;
  final String reason;
  final List<String> proofImages;
  final String status;
  final int refundAmount;
  final String? rejectionReason;
  final DateTime createdAt;

  const OrderReturnModel({
    required this.id,
    required this.orderId,
    required this.reason,
    this.proofImages = const [],
    required this.status,
    this.refundAmount = 0,
    this.rejectionReason,
    required this.createdAt,
  });

  bool get isOpen =>
      status == 'requested' ||
      status == 'shop_approved' ||
      status == 'admin_dispute_review';

  String get statusLabel {
    switch (status) {
      case 'requested':
        return 'Đang chờ xử lý';
      case 'shop_approved':
        return 'Shop đã duyệt';
      case 'shop_rejected':
        return 'Shop từ chối';
      case 'admin_dispute_review':
        return 'Admin đang xem xét';
      case 'refunded':
        return 'Đã hoàn tiền';
      case 'rejected':
        return 'Đã từ chối';
      default:
        return status;
    }
  }

  factory OrderReturnModel.fromJson(Map<String, dynamic> json) {
    final rawImages = json['proof_images'] ?? json['proofImages'];
    List<String> images = [];
    if (rawImages is List) {
      images = rawImages.map((item) => item.toString()).where((url) => url.isNotEmpty).toList();
    }

    return OrderReturnModel(
      id: json['id']?.toString() ?? '',
      orderId: json['order_id']?.toString() ?? json['orderId']?.toString() ?? '',
      reason: json['reason']?.toString() ?? '',
      proofImages: images,
      status: json['status']?.toString() ?? 'requested',
      refundAmount: (json['refund_amount'] is num)
          ? (json['refund_amount'] as num).toInt()
          : (json['refundAmount'] is num)
              ? (json['refundAmount'] as num).toInt()
              : 0,
      rejectionReason: json['rejection_reason']?.toString() ?? json['rejectionReason']?.toString(),
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? json['createdAt']?.toString() ?? '') ??
          DateTime.now(),
    );
  }
}
