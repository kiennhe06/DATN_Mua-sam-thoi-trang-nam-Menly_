import 'package:menly_app/core/utils/format.dart';

/// Mot phuong thuc giao hang do may chu khai bao (tieu chuan, hoa toc...).
class ShippingMethodModel {
  final String id;
  final String name;
  final String description;
  final String estimatedDays;
  final int baseFee;

  const ShippingMethodModel({
    required this.id,
    required this.name,
    required this.description,
    required this.estimatedDays,
    required this.baseFee,
  });

  factory ShippingMethodModel.fromJson(Map<String, dynamic> json) {
    return ShippingMethodModel(
      id: json['id']?.toString() ?? 'standard',
      name: json['name']?.toString() ?? 'Giao hàng tiêu chuẩn',
      description: json['description']?.toString() ?? '',
      estimatedDays: json['estimatedDays']?.toString() ?? '',
      baseFee: (json['baseFee'] is num) ? (json['baseFee'] as num).toInt() : 0,
    );
  }

  /// Dong mo ta ngan duoi ten phuong thuc: "2–4 ngày làm việc • 25.000 đ".
  String get dongTomTat {
    final gia = formatPrice(baseFee);
    if (estimatedDays.isEmpty) return gia;
    return '$estimatedDays • $gia';
  }
}

/// Chinh sach giao hang lay tu API GET /api/v1/orders/shipping-policy.
///
/// Toan bo con so phi ship trong app deu phai di qua day. Khong viet thang
/// 25.000 hay 499.000 vao man hinh nua: doi gia ben may chu la app doi theo,
/// khong phai phat hanh ban moi.
class ShippingPolicyModel {
  final int standardBaseFee;
  final int expressBaseFee;
  final int freeShippingThreshold;
  final List<ShippingMethodModel> methods;

  const ShippingPolicyModel({
    required this.standardBaseFee,
    required this.expressBaseFee,
    required this.freeShippingThreshold,
    required this.methods,
  });

  factory ShippingPolicyModel.fromJson(Map<String, dynamic> json) {
    final rawMethods = json['supportedMethods'];
    return ShippingPolicyModel(
      standardBaseFee: (json['standardBaseFee'] is num)
          ? (json['standardBaseFee'] as num).toInt()
          : 0,
      expressBaseFee: (json['expressBaseFee'] is num)
          ? (json['expressBaseFee'] as num).toInt()
          : 0,
      freeShippingThreshold: (json['freeShippingThreshold'] is num)
          ? (json['freeShippingThreshold'] as num).toInt()
          : 0,
      methods: (rawMethods is List)
          ? rawMethods
              .whereType<Map>()
              .map((e) =>
                  ShippingMethodModel.fromJson(Map<String, dynamic>.from(e)))
              .toList()
          : const [],
    );
  }

  /// Phi goc cua mot phuong thuc, dung khi chua goi duoc API tinh phi.
  int phiGoc(String methodId) {
    for (final method in methods) {
      if (method.id == methodId) return method.baseFee;
    }
    return methodId == 'express' ? expressBaseFee : standardBaseFee;
  }

  /// Cau mo ta chinh sach, dung cho man Hoi dap, Chinh sach va Gioi thieu.
  String get moTaPhiGiaoHang =>
      'Giao tiêu chuẩn ${formatPrice(standardBaseFee)}, hỏa tốc '
      '${formatPrice(expressBaseFee)}. Miễn phí vận chuyển cho đơn từ '
      '${formatPrice(freeShippingThreshold)}.';
}
