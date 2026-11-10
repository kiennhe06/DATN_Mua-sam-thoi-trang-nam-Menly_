import 'package:flutter_test/flutter_test.dart';
import 'package:menly_app/features/address/data/vietnam_administrative_data.dart';
import 'package:menly_app/features/address/presentation/widgets/administrative_unit_picker.dart';

void main() {
  test('Dia chi trong thi tu dien tinh mac dinh va quan, phuong hop le', () {
    final donVi = DonViHanhChinh.chuanHoa();

    expect(donVi.province, kTinhMacDinh);
    expect(kVietnamProvinces, contains(donVi.province));
    expect(donVi.ward, isNotEmpty);
    expect(donVi.dayDu, isTrue);
  });

  test('Chon tinh moi thi quan va phuong doi theo, khong giu cua tinh cu', () {
    final hcm = DonViHanhChinh.chuanHoa(province: 'Thành phố Hồ Chí Minh');
    final hanoi = DonViHanhChinh.chuanHoa(province: 'Thành phố Hà Nội');

    expect(hcm.province, isNot(hanoi.province));
    expect(
      getWardsForProvince(hanoi.province),
      isNot(contains(hcm.ward)),
      reason: 'phuong cua tinh cu khong duoc dinh sang tinh moi',
    );
  });

  test('Dia chi luu tu truoc co ten khong con trong danh sach thi van giu lai', () {
    // Dia chi cu luu theo don vi hanh chinh truoc sap nhap. Thay bang muc dau
    // danh sach se lam don hang giao sai noi, nen phai giu nguyen.
    final donVi = DonViHanhChinh.chuanHoa(
      province: 'Thành phố Hồ Chí Minh',
      district: 'Quận Thủ Đức cũ',
      ward: 'Phường Linh Trung cũ',
    );

    expect(donVi.district, 'Quận Thủ Đức cũ');
    expect(donVi.ward, 'Phường Linh Trung cũ');
  });

  test('Mo ta ghep phuong, quan, tinh va bo phan de trong', () {
    const donVi = DonViHanhChinh(
      province: 'Ninh Bình',
      district: '',
      ward: 'Phường Tân Thành',
    );

    expect(donVi.moTa, 'Phường Tân Thành, Ninh Bình');
  });
}
