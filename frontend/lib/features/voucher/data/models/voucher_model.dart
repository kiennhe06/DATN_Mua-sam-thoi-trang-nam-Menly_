/// Model ma giam gia Voucher / Coupon (AP-VC1, TM10)
class VoucherModel {
  final String id;
  final String code;
  final String title;
  final String discountType; // 'percentage' hoac 'fixed_amount'
  final int discountValue;
  final int minOrderValue;
  final int? maxDiscount;
  final DateTime endDate;
  final bool isActive;

  const VoucherModel({
    required this.id,
    required this.code,
    required this.title,
    required this.discountType,
    required this.discountValue,
    this.minOrderValue = 0,
    this.maxDiscount,
    required this.endDate,
    this.isActive = true,
  });

  /// Tinh so tien giam gia dua tren tong don hang
  int calculateDiscount(int orderSubtotal) {
    // Khong gioi han so tien don hang de ap dung voucher
    if (orderSubtotal <= 0) return 0;
    if (discountType == 'percentage') {
      int calculated = (orderSubtotal * discountValue ~/ 100);
      if (maxDiscount != null && calculated > maxDiscount!) {
        return maxDiscount!;
      }
      return calculated;
    } else {
      return discountValue > orderSubtotal ? orderSubtotal : discountValue;
    }
  }

  factory VoucherModel.fromJson(Map<String, dynamic> json) {
    return VoucherModel(
      id: json['id']?.toString() ?? '',
      code: json['code']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      discountType: json['discount_type']?.toString() ?? 'percentage',
      discountValue: (json['discount_value'] is num) ? (json['discount_value'] as num).toInt() : 0,
      minOrderValue: (json['min_order_value'] is num) ? (json['min_order_value'] as num).toInt() : 0,
      maxDiscount: (json['max_discount'] is num) ? (json['max_discount'] as num).toInt() : null,
      endDate: json['end_date'] != null
          ? DateTime.tryParse(json['end_date'].toString()) ?? DateTime.now().add(const Duration(days: 30))
          : DateTime.now().add(const Duration(days: 30)),
      isActive: json['is_active'] ?? true,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'code': code,
    'title': title,
    'discount_type': discountType,
    'discount_value': discountValue,
    'min_order_value': minOrderValue,
    'max_discount': maxDiscount,
    'end_date': endDate.toIso8601String(),
    'is_active': isActive,
  };
}

