import 'package:flutter_test/flutter_test.dart';
import 'package:menly_app/features/order/data/models/order_model.dart';

/// Nut "Tra hang" chi duoc hien khi don that su con tra duoc. Han tra hang do
/// may chu tinh va gui xuong o truong return_deadline; app chi so sanh voi gio
/// hien tai chu khong tu tinh lai so ngay.
void main() {
  OrderModel donHang({
    String status = 'delivered',
    DateTime? hanTraHang,
    bool daHoanTien = false,
  }) {
    return OrderModel.fromJson({
      'id': 'don-1',
      'code': 'MENLY-1',
      'status': status,
      'payment_method': 'cod',
      'subtotal': 300000,
      'shipping_fee': 0,
      'total': 300000,
      'ship_name': 'Nguyễn Văn A',
      'ship_phone': '0900000000',
      'ship_address': 'Hà Nội',
      'created_at': DateTime.now().toIso8601String(),
      'items': const [],
      'refunded': daHoanTien,
      'return_deadline': hanTraHang?.toIso8601String(),
    });
  }

  test('đơn đã giao và còn trong hạn thì trả hàng được', () {
    final don = donHang(hanTraHang: DateTime.now().add(const Duration(days: 3)));

    expect(don.quaHanTraHang, isFalse);
    expect(don.canReturn, isTrue);
  });

  test('đơn đã quá hạn thì không trả hàng được nữa', () {
    final don = donHang(hanTraHang: DateTime.now().subtract(const Duration(days: 1)));

    expect(don.quaHanTraHang, isTrue);
    expect(don.canReturn, isFalse);
  });

  test('máy chủ không gửi hạn thì không chặn người dùng', () {
    // Don cu khong con lich su trang thai se khong co han. Chan luon se lam
    // khach mat quyen tra hang vi loi du lieu, nen coi nhu con han.
    final don = donHang();

    expect(don.quaHanTraHang, isFalse);
    expect(don.canReturn, isTrue);
  });

  test('đơn đã hoàn tiền thì không trả hàng lại được dù còn hạn', () {
    final don = donHang(
      hanTraHang: DateTime.now().add(const Duration(days: 3)),
      daHoanTien: true,
    );

    expect(don.canReturn, isFalse);
  });

  test('đơn chưa giao thì không trả hàng được', () {
    final don = donHang(
      status: 'shipping',
      hanTraHang: DateTime.now().add(const Duration(days: 3)),
    );

    expect(don.canReturn, isFalse);
  });
}
