import 'package:flutter/material.dart';

import '../../data/vietnam_administrative_data.dart';

/// Tinh chon san khi nguoi dung chua nhap gi. Giu nguyen lua chon cu cua nhom
/// de dia chi moi khong tu nhien nhay sang tinh khac.
const String kTinhMacDinh = 'Thành phố Hồ Chí Minh';

/// Bo ba Tinh / Quan / Phuong cua mot dia chi.
class DonViHanhChinh {
  final String province;
  final String district;
  final String ward;

  const DonViHanhChinh({
    required this.province,
    required this.district,
    required this.ward,
  });

  /// Chuan hoa ve bo ba dung duoc: ten tinh theo danh sach moi, quan thuoc
  /// tinh, phuong thuoc quan. Gia tri cu khong con trong danh sach thi van
  /// duoc giu lai de dia chi da luu truoc day khong bi doi sang noi khac.
  factory DonViHanhChinh.chuanHoa({
    String province = '',
    String district = '',
    String ward = '',
  }) {
    final tinh = normalizeProvince(
      province.trim().isEmpty ? kTinhMacDinh : province.trim(),
    );

    final dsQuan = getDistrictsForProvince(tinh);
    var quan = district.trim();
    if (quan.isEmpty && dsQuan.isNotEmpty) quan = dsQuan.first;

    final dsPhuong =
        quan.isEmpty ? getWardsForProvince(tinh) : getWardsForDistrict(tinh, quan);
    var phuong = ward.trim();
    if (phuong.isEmpty && dsPhuong.isNotEmpty) phuong = dsPhuong.first;

    return DonViHanhChinh(province: tinh, district: quan, ward: phuong);
  }

  /// Phan duoi cua dia chi, vi du "Phuong Ben Cat, Huyen Bau Bang, ...".
  String get moTa =>
      [ward, district, province].where((phan) => phan.trim().isNotEmpty).join(', ');

  bool get dayDu => province.trim().isNotEmpty && ward.trim().isNotEmpty;
}

/// Ba o chon Tinh / Quan / Phuong, chon tinh thi hai o con lai doi theo.
///
/// Dung chung cho so dia chi va man dat hang de hai noi khong lech nhau.
class AdministrativeUnitPicker extends StatefulWidget {
  final DonViHanhChinh giaTri;
  final ValueChanged<DonViHanhChinh> onChanged;

  const AdministrativeUnitPicker({
    super.key,
    required this.giaTri,
    required this.onChanged,
  });

  @override
  State<AdministrativeUnitPicker> createState() =>
      _AdministrativeUnitPickerState();
}

class _AdministrativeUnitPickerState extends State<AdministrativeUnitPicker> {
  late DonViHanhChinh _giaTri;

  @override
  void initState() {
    super.initState();
    _giaTri = widget.giaTri;
  }

  @override
  void didUpdateWidget(AdministrativeUnitPicker cu) {
    super.didUpdateWidget(cu);
    if (widget.giaTri.province != cu.giaTri.province ||
        widget.giaTri.district != cu.giaTri.district ||
        widget.giaTri.ward != cu.giaTri.ward) {
      _giaTri = widget.giaTri;
    }
  }

  void _capNhat(DonViHanhChinh moi) {
    setState(() => _giaTri = moi);
    widget.onChanged(moi);
  }

  /// Them gia tri dang chon vao danh sach neu no khong con trong du lieu moi,
  /// de dropdown khong bi loi "khong tim thay muc dang chon".
  List<String> _danhSachCo(List<String> goc, String dangChon) {
    if (dangChon.isEmpty || goc.contains(dangChon)) return goc;
    return [dangChon, ...goc];
  }

  Widget _oChon({
    required String nhan,
    required String giaTri,
    required List<String> danhSach,
    required ValueChanged<String> onChanged,
  }) {
    final trangTri = InputDecoration(
      labelText: nhan,
      border: const OutlineInputBorder(),
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
    );

    if (danhSach.isEmpty) {
      // Khong co du lieu san thi de nguoi dung tu go, con hon chan ho lai.
      return TextFormField(
        initialValue: giaTri,
        decoration: trangTri,
        style: const TextStyle(fontSize: 13),
        onChanged: onChanged,
      );
    }

    return DropdownButtonFormField<String>(
      key: ValueKey('$nhan-$giaTri'),
      initialValue: giaTri.isEmpty ? null : giaTri,
      isExpanded: true,
      menuMaxHeight: 350,
      decoration: trangTri,
      items: danhSach
          .map((muc) => DropdownMenuItem(
                value: muc,
                child: Text(
                  muc,
                  style: const TextStyle(fontSize: 13),
                  overflow: TextOverflow.ellipsis,
                ),
              ))
          .toList(),
      onChanged: (chon) {
        if (chon != null) onChanged(chon);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final dsTinh = _danhSachCo(kVietnamProvinces, _giaTri.province);
    final dsQuan = _danhSachCo(
      getDistrictsForProvince(_giaTri.province),
      _giaTri.district,
    );
    final dsPhuong = _danhSachCo(
      _giaTri.district.isEmpty
          ? getWardsForProvince(_giaTri.province)
          : getWardsForDistrict(_giaTri.province, _giaTri.district),
      _giaTri.ward,
    );

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _oChon(
                nhan: 'Tỉnh / Thành phố',
                giaTri: _giaTri.province,
                danhSach: dsTinh,
                // Doi tinh thi quan va phuong cu khong con dung nua.
                onChanged: (tinh) =>
                    _capNhat(DonViHanhChinh.chuanHoa(province: tinh)),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _oChon(
                nhan: 'Quận / Huyện',
                giaTri: _giaTri.district,
                danhSach: dsQuan,
                onChanged: (quan) => _capNhat(DonViHanhChinh.chuanHoa(
                  province: _giaTri.province,
                  district: quan,
                )),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        _oChon(
          nhan: 'Phường / Xã',
          giaTri: _giaTri.ward,
          danhSach: dsPhuong,
          onChanged: (phuong) => _capNhat(DonViHanhChinh(
            province: _giaTri.province,
            district: _giaTri.district,
            ward: phuong,
          )),
        ),
      ],
    );
  }
}
