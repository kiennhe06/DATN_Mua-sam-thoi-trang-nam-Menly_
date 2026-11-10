import 'package:flutter/material.dart';

import '../../data/vietnam_administrative_data.dart';

/// Tỉnh chọn sẵn khi người dùng chưa nhập gì (theo 34 tỉnh thành mới)
const String kTinhMacDinh = 'Thành phố Hồ Chí Minh';

/// Bộ ba Tỉnh / Quận / Phường của một địa chỉ theo 34 Tỉnh/Thành phố mới
class DonViHanhChinh {
  final String province;
  final String district;
  final String ward;

  const DonViHanhChinh({
    required this.province,
    required this.district,
    required this.ward,
  });

  /// Chuẩn hóa về bộ ba hợp lệ theo 34 Tỉnh / Thành phố mới:
  /// Tên tỉnh theo danh sách mới, quận thuộc tỉnh, phường thuộc quận.
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

  /// Phần đuôi của địa chỉ, ví dụ: "Phường Bến Nghé, Quận 1, Thành phố Hồ Chí Minh".
  String get moTa =>
      [ward, district, province].where((phan) => phan.trim().isNotEmpty).join(', ');

  bool get dayDu => province.trim().isNotEmpty && ward.trim().isNotEmpty;
}

/// Helper loại bỏ dấu tiếng Việt để tìm kiếm không dấu mượt mà
String _removeVietnameseDiacritics(String str) {
  var result = str.toLowerCase();
  result = result.replaceAll(RegExp(r'[àáạảãâầấậẩẫăằắặẳẵ]'), 'a');
  result = result.replaceAll(RegExp(r'[èéẹẻẽêềếệểễ]'), 'e');
  result = result.replaceAll(RegExp(r'[ìíịỉĩ]'), 'i');
  result = result.replaceAll(RegExp(r'[òóọỏõôồốộổỗơờớợởỡ]'), 'o');
  result = result.replaceAll(RegExp(r'[ùúụủũưừứựửữ]'), 'u');
  result = result.replaceAll(RegExp(r'[ỳýỵỷỹ]'), 'y');
  result = result.replaceAll(RegExp(r'[đ]'), 'd');
  result = result.replaceAll(RegExp(r'[\u0300-\u036f]'), '');
  return result;
}

/// Widget lựa chọn địa chỉ 3 cấp chuẩn theo 34 Tỉnh / Thành phố mới
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

  /// Mở modal tìm kiếm và chọn đơn vị hành chính theo từng cấp
  Future<String?> _showSearchableModal({
    required BuildContext context,
    required String title,
    required List<String> items,
    required String currentValue,
    bool isProvinceSelection = false,
    bool isWardSelection = false,
  }) async {
    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        String searchQuery = '';
        return StatefulBuilder(
          builder: (modalCtx, setModalState) {
            final queryNorm = _removeVietnameseDiacritics(searchQuery.trim());

            // Lọc danh sách theo từ khóa tìm kiếm
            final filteredItems = items.where((item) {
              if (queryNorm.isEmpty) return true;
              final itemNorm = _removeVietnameseDiacritics(item);
              if (itemNorm.contains(queryNorm)) return true;

              // Nếu đang chọn tỉnh: Cho phép tìm kiếm cả theo tên tỉnh cũ
              if (isProvinceSelection) {
                for (final entry in kOldProvinceToNewMapping.entries) {
                  if (entry.value == item) {
                    final oldKeyNorm = _removeVietnameseDiacritics(entry.key);
                    if (oldKeyNorm.contains(queryNorm)) return true;
                  }
                }
              }

              // Nếu đang chọn phường/xã: Cho phép tìm kiếm cả theo nguồn gốc sáp nhập cũ
              if (isWardSelection) {
                final note = getWardMergeNote(_giaTri.province, item);
                if (note != null) {
                  final noteNorm = _removeVietnameseDiacritics(note);
                  if (noteNorm.contains(queryNorm)) return true;
                }
              }

              return false;
            }).toList();

            return DraggableScrollableSheet(
              initialChildSize: 0.75,
              minChildSize: 0.45,
              maxChildSize: 0.92,
              expand: false,
              builder: (_, scrollController) {
                return Column(
                  children: [
                    // Thanh gạt modal
                    Container(
                      margin: const EdgeInsets.symmetric(vertical: 10),
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),

                    // Tiêu đề modal
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              title,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1C1B17),
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close_rounded,
                                color: Colors.grey),
                            onPressed: () => Navigator.pop(modalCtx),
                          ),
                        ],
                      ),
                    ),

                    // Search input
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: TextField(
                        autofocus: false,
                        decoration: InputDecoration(
                          hintText: 'Tìm kiếm...',
                          hintStyle: TextStyle(
                              fontSize: 13, color: Colors.grey.shade400),
                          prefixIcon: const Icon(Icons.search_rounded,
                              size: 20, color: Colors.grey),
                          suffixIcon: searchQuery.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear_rounded,
                                      size: 18),
                                  onPressed: () =>
                                      setModalState(() => searchQuery = ''),
                                )
                              : null,
                          filled: true,
                          fillColor: const Color(0xFFF6F4F1),
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 12),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        onChanged: (val) =>
                            setModalState(() => searchQuery = val),
                      ),
                    ),

                    const SizedBox(height: 10),
                    const Divider(height: 1),

                    // Danh sách lựa chọn
                    Expanded(
                      child: filteredItems.isEmpty
                          ? Center(
                              child: Padding(
                                padding: const EdgeInsets.all(24),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.search_off_rounded,
                                        size: 48, color: Colors.grey.shade400),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Không tìm thấy "$searchQuery"',
                                      style: TextStyle(
                                          color: Colors.grey.shade600,
                                          fontWeight: FontWeight.w500),
                                    ),
                                  ],
                                ),
                              ),
                            )
                          : ListView.separated(
                              controller: scrollController,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 8),
                              itemCount: filteredItems.length,
                              separatorBuilder: (_, __) =>
                                  const Divider(height: 1, indent: 16),
                              itemBuilder: (itemCtx, index) {
                                final item = filteredItems[index];
                                final isSelected = item == currentValue;

                                return ListTile(
                                  contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 2),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  tileColor: isSelected
                                      ? const Color(0xFFF0E4D4)
                                      : null,
                                  title: Text(
                                    item,
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: isSelected
                                          ? FontWeight.bold
                                          : FontWeight.w500,
                                      color: isSelected
                                          ? const Color(0xFFB8824A)
                                          : const Color(0xFF1C1B17),
                                    ),
                                  ),
                                  trailing: isSelected
                                      ? const Icon(Icons.check_circle_rounded,
                                          color: Color(0xFFB8824A), size: 20)
                                      : null,
                                  onTap: () => Navigator.pop(modalCtx, item),
                                );
                              },
                            ),
                    ),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }

  /// Xử lý khi bấm chọn Tỉnh / Thành phố
  Future<void> _chonTinh() async {
    const dsTinh = kVietnamProvinces;
    final ketQua = await _showSearchableModal(
      context: context,
      title: 'Tỉnh / Thành phố',
      items: dsTinh,
      currentValue: _giaTri.province,
      isProvinceSelection: true,
    );

    if (ketQua != null && ketQua != _giaTri.province && mounted) {
      final moi = DonViHanhChinh.chuanHoa(province: ketQua);
      _capNhat(moi);

      // Tự động mở bước tiếp theo: Chọn Quận / Huyện
      await Future.delayed(const Duration(milliseconds: 250));
      if (mounted) _chonQuan();
    }
  }

  /// Xử lý khi bấm chọn Quận / Huyện
  Future<void> _chonQuan() async {
    final dsQuan = getDistrictsForProvince(_giaTri.province);
    if (dsQuan.isEmpty) return;

    final ketQua = await _showSearchableModal(
      context: context,
      title: 'Quận / Huyện',
      items: dsQuan,
      currentValue: _giaTri.district,
    );

    if (ketQua != null && ketQua != _giaTri.district && mounted) {
      final dsPhuong = getWardsForDistrict(_giaTri.province, ketQua);
      final phuongMoi = dsPhuong.isNotEmpty ? dsPhuong.first : '';
      final moi = DonViHanhChinh(
        province: _giaTri.province,
        district: ketQua,
        ward: phuongMoi,
      );
      _capNhat(moi);

      // Tự động mở bước tiếp theo: Chọn Phường / Xã
      await Future.delayed(const Duration(milliseconds: 250));
      if (mounted) _chonPhuong();
    }
  }

  /// Xử lý khi bấm chọn Phường / Xã
  Future<void> _chonPhuong() async {
    final dsPhuong = _giaTri.district.isNotEmpty
        ? getWardsForDistrict(_giaTri.province, _giaTri.district)
        : getWardsForProvince(_giaTri.province);

    if (dsPhuong.isEmpty) return;

    final ketQua = await _showSearchableModal(
      context: context,
      title: 'Phường / Xã',
      items: dsPhuong,
      currentValue: _giaTri.ward,
      isWardSelection: true,
    );

    if (ketQua != null && mounted) {
      _capNhat(DonViHanhChinh(
        province: _giaTri.province,
        district: _giaTri.district,
        ward: ketQua,
      ));
    }
  }

  /// Widget hiển thị ô chọn đơn vị hành chính
  Widget _buildSelectionBox({
    required String label,
    required String value,
    required String placeholder,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    final hasValue = value.trim().isNotEmpty;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFF9FAFB),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: hasValue ? const Color(0xFFD1D5DB) : const Color(0xFFE5E7EB),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, size: 20, color: const Color(0xFF8A6234)),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    hasValue ? value : placeholder,
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight:
                          hasValue ? FontWeight.w600 : FontWeight.normal,
                      color: hasValue
                          ? const Color(0xFF1C1B17)
                          : Colors.grey.shade400,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Icon(Icons.keyboard_arrow_down_rounded,
                size: 20, color: Colors.grey.shade500),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. Ô chọn Tỉnh / Thành phố
        _buildSelectionBox(
          label: 'Tỉnh / Thành phố',
          value: _giaTri.province,
          placeholder: 'Chọn Tỉnh / Thành phố...',
          icon: Icons.location_city_rounded,
          onTap: _chonTinh,
        ),
        const SizedBox(height: 8),

        // 2 & 3. Hàng chọn Quận/Huyện và Phường/Xã
        Row(
          children: [
            // Quận / Huyện
            Expanded(
              child: _buildSelectionBox(
                label: 'Quận / Huyện',
                value: _giaTri.district,
                placeholder: 'Chọn Quận / Huyện...',
                icon: Icons.apartment_rounded,
                onTap: _chonQuan,
              ),
            ),
            const SizedBox(width: 8),
            // Phường / Xã
            Expanded(
              child: _buildSelectionBox(
                label: 'Phường / Xã',
                value: _giaTri.ward,
                placeholder: 'Chọn Phường / Xã...',
                icon: Icons.holiday_village_rounded,
                onTap: _chonPhuong,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
