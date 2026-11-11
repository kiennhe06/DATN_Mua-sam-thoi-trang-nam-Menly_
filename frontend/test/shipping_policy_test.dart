import 'package:flutter_test/flutter_test.dart';
import 'package:menly_app/features/order/data/models/shipping_policy_model.dart';

/// Bang gia giao hang phai den tu API. Cac bai duoi chot lai hai viec: doc
/// dung du lieu may chu tra ve, va khong tu bia con so khi du lieu thieu.
void main() {
  Map<String, dynamic> duLieuMayChu() => {
        'standardBaseFee': 30000,
        'expressBaseFee': 50000,
        'freeShippingThreshold': 600000,
        'supportedMethods': [
          {
            'id': 'standard',
            'name': 'Giao hàng tiêu chuẩn',
            'description': 'Giao toàn quốc',
            'baseFee': 30000,
            'estimatedDays': '2–4 ngày làm việc',
          },
          {
            'id': 'express',
            'name': 'Giao hàng hỏa tốc',
            'description': 'Nội thành trong ngày',
            'baseFee': 50000,
            'estimatedDays': 'Trong ngày hoặc 24h',
          },
        ],
      };

  test('Doc dung bang gia may chu tra ve, khong dung gia mac dinh cua app', () {
    final bangGia = ShippingPolicyModel.fromJson(duLieuMayChu());

    expect(bangGia.standardBaseFee, 30000);
    expect(bangGia.expressBaseFee, 50000);
    expect(bangGia.freeShippingThreshold, 600000);
    expect(bangGia.methods.length, 2);
    expect(bangGia.phiGoc('standard'), 30000);
    expect(bangGia.phiGoc('express'), 50000);
  });

  test('Dong tom tat cua phuong thuc ghep thoi gian va phi theo bang gia', () {
    final bangGia = ShippingPolicyModel.fromJson(duLieuMayChu());
    final tieuChuan = bangGia.methods.first;

    expect(tieuChuan.dongTomTat, '2–4 ngày làm việc • 30.000 đ');
  });

  test('Cau mo ta chinh sach lay so tu bang gia, khong viet cung', () {
    final moTa = ShippingPolicyModel.fromJson(duLieuMayChu()).moTaPhiGiaoHang;

    expect(moTa.contains('30.000 đ'), isTrue);
    expect(moTa.contains('50.000 đ'), isTrue);
    expect(moTa.contains('600.000 đ'), isTrue);
    // Khong duoc con dau vet cua bang gia cu go cung trong app.
    expect(moTa.contains('25.000'), isFalse);
    expect(moTa.contains('499.000'), isFalse);
  });

  test('Thieu truong thi tra ve 0 chu khong doan mot muc phi', () {
    final bangGia = ShippingPolicyModel.fromJson({});

    expect(bangGia.standardBaseFee, 0);
    expect(bangGia.expressBaseFee, 0);
    expect(bangGia.freeShippingThreshold, 0);
    expect(bangGia.methods, isEmpty);
  });
}
