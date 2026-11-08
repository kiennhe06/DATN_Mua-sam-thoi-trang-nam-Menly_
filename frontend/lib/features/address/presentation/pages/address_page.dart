import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:menly_app/features/address/data/models/address_model.dart';
import '../../data/vietnam_administrative_data.dart';
import '../providers/address_provider.dart';
import 'package:menly_app/features/notification/presentation/providers/notification_provider.dart';

/// Man hinh So dia chi giao hang & Chon dia chi khi dat hang (AP-DC1)
class AddressPage extends StatelessWidget {
  final bool isSelectionMode;

  const AddressPage({super.key, this.isSelectionMode = false});

  void _showAddressDialog(BuildContext context, {AddressModel? addressToEdit}) {
    final nameCtrl = TextEditingController(text: addressToEdit?.recipientName ?? '');
    final phoneCtrl = TextEditingController(text: addressToEdit?.phone ?? '');

    // Chuẩn hóa Tỉnh / Thành phố từ 34 tỉnh thành Việt Nam theo Nghị quyết 202/2025/QH15
    String selectedProvince = normalizeProvince(addressToEdit?.province ?? 'Thành phố Hồ Chí Minh');
    final provinceList = List<String>.from(kVietnamProvinces);
    if (!provinceList.contains(selectedProvince)) {
      provinceList.insert(0, selectedProvince);
    }

    // Lấy danh sách Quận / Huyện tương ứng với Tỉnh / Thành phố
    List<String> availableDistricts = getDistrictsForProvince(selectedProvince);
    String? selectedDistrict = addressToEdit?.district;
    if (selectedDistrict != null && selectedDistrict.isNotEmpty) {
      if (!availableDistricts.contains(selectedDistrict)) {
        availableDistricts = [selectedDistrict, ...availableDistricts];
      }
    } else if (availableDistricts.isNotEmpty) {
      selectedDistrict = availableDistricts.first;
    }

    // Lấy danh sách Phường / Xã tương ứng với Tỉnh / Thành phố và Quận / Huyện
    List<String> availableWards = getWardsForDistrict(selectedProvince, selectedDistrict ?? '');
    String? selectedWard = addressToEdit?.ward;
    if (selectedWard != null && selectedWard.isNotEmpty) {
      if (!availableWards.contains(selectedWard)) {
        availableWards = [selectedWard, ...availableWards];
      }
    } else if (availableWards.isNotEmpty) {
      selectedWard = availableWards.first;
    }

    final districtCtrl = TextEditingController(text: selectedDistrict ?? 'Quận 1');
    final wardCtrl = TextEditingController(text: selectedWard ?? 'Phường Bến Nghé');
    final detailCtrl = TextEditingController(text: addressToEdit?.detailAddress ?? '');
    bool isDefault = addressToEdit?.isDefault ?? false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setState) {
            return Padding(
              padding: EdgeInsets.only(
                top: 20,
                left: 16,
                right: 16,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          addressToEdit == null ? 'Thêm địa chỉ nhận hàng' : 'Cập nhật địa chỉ',
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Đóng', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold))),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: nameCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Họ và tên người nhận',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: phoneCtrl,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        labelText: 'Số điện thoại',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        // Dropdown Tỉnh / Thành phố với 34 tỉnh thành Việt Nam theo Nghị quyết 202/2025/QH15
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            key: ValueKey('province_$selectedProvince'),
                            initialValue: selectedProvince,
                            isExpanded: true,
                            menuMaxHeight: 350,
                            decoration: const InputDecoration(
                              labelText: 'Tỉnh / Thành phố',
                              border: OutlineInputBorder(),
                              isDense: true,
                              contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                            ),
                            items: provinceList.map((p) => DropdownMenuItem(
                              value: p,
                              child: Text(
                                p,
                                style: const TextStyle(fontSize: 13),
                                overflow: TextOverflow.ellipsis,
                              ),
                            )).toList(),
                            onChanged: (val) {
                              if (val == null) return;
                              setState(() {
                                selectedProvince = val;
                                availableDistricts = getDistrictsForProvince(val);
                                if (availableDistricts.isNotEmpty) {
                                  selectedDistrict = availableDistricts.first;
                                  districtCtrl.text = selectedDistrict!;
                                  availableWards = getWardsForDistrict(val, selectedDistrict!);
                                  if (availableWards.isNotEmpty) {
                                    selectedWard = availableWards.first;
                                    wardCtrl.text = selectedWard!;
                                  } else {
                                    selectedWard = null;
                                    wardCtrl.text = '';
                                  }
                                } else {
                                  selectedDistrict = null;
                                  districtCtrl.text = '';
                                  availableWards = getWardsForProvince(val);
                                  if (availableWards.isNotEmpty) {
                                    selectedWard = availableWards.first;
                                    wardCtrl.text = selectedWard!;
                                  } else {
                                    selectedWard = null;
                                    wardCtrl.text = '';
                                  }
                                }
                              });
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Dropdown Quận / Huyện tương ứng theo Tỉnh / Thành phố đã chọn
                        Expanded(
                          child: availableDistricts.isNotEmpty
                              ? DropdownButtonFormField<String>(
                                  key: ValueKey('district_${selectedProvince}_$selectedDistrict'),
                                  initialValue: availableDistricts.contains(selectedDistrict)
                                      ? selectedDistrict
                                      : (availableDistricts.isNotEmpty ? availableDistricts.first : null),
                                  isExpanded: true,
                                  menuMaxHeight: 350,
                                  decoration: const InputDecoration(
                                    labelText: 'Quận / Huyện',
                                    border: OutlineInputBorder(),
                                    isDense: true,
                                    contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                                  ),
                                  items: availableDistricts.map((d) => DropdownMenuItem(
                                    value: d,
                                    child: Text(
                                      d,
                                      style: const TextStyle(fontSize: 13),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  )).toList(),
                                  onChanged: (val) {
                                    if (val == null) return;
                                    setState(() {
                                      selectedDistrict = val;
                                      districtCtrl.text = val;
                                      availableWards = getWardsForDistrict(selectedProvince, val);
                                      if (availableWards.isNotEmpty) {
                                        selectedWard = availableWards.first;
                                        wardCtrl.text = selectedWard!;
                                      } else {
                                        selectedWard = null;
                                        wardCtrl.text = '';
                                      }
                                    });
                                  },
                                )
                              : TextField(
                                  controller: districtCtrl,
                                  decoration: const InputDecoration(
                                    labelText: 'Quận / Huyện',
                                    border: OutlineInputBorder(),
                                    isDense: true,
                                    contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                                  ),
                                ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    // Dropdown Phường / Xã tương ứng theo Quận / Huyện và Tỉnh / Thành phố
                    availableWards.isNotEmpty
                        ? DropdownButtonFormField<String>(
                            key: ValueKey('ward_${selectedProvince}_${selectedDistrict}_$selectedWard'),
                            initialValue: availableWards.contains(selectedWard)
                                ? selectedWard
                                : (availableWards.isNotEmpty ? availableWards.first : null),
                            isExpanded: true,
                            menuMaxHeight: 350,
                            decoration: const InputDecoration(
                              labelText: 'Phường / Xã',
                              border: OutlineInputBorder(),
                              isDense: true,
                              contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                            ),
                            items: availableWards.map((w) => DropdownMenuItem(
                              value: w,
                              child: Text(
                                w,
                                style: const TextStyle(fontSize: 13),
                                overflow: TextOverflow.ellipsis,
                              ),
                            )).toList(),
                            onChanged: (val) {
                              if (val == null) return;
                              setState(() {
                                selectedWard = val;
                                wardCtrl.text = val;
                              });
                            },
                          )
                        : TextField(
                            controller: wardCtrl,
                            decoration: const InputDecoration(
                              labelText: 'Phường / Xã',
                              border: OutlineInputBorder(),
                              isDense: true,
                              contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                            ),
                          ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: detailCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Địa chỉ cụ thể (Số nhà, tên đường)',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                    ),
                    const SizedBox(height: 8),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Đặt làm địa chỉ mặc định'),
                      value: isDefault,
                      activeThumbColor: Colors.black,
                      onChanged: (val) => setState(() => isDefault = val),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.black87,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: () async {
                          final finalProvince = selectedProvince;
                          final finalDistrict = selectedDistrict ?? districtCtrl.text.trim();
                          final finalWard = selectedWard ?? wardCtrl.text.trim();

                          if (nameCtrl.text.trim().isEmpty ||
                              phoneCtrl.text.trim().isEmpty ||
                              detailCtrl.text.trim().isEmpty ||
                              finalProvince.trim().isEmpty ||
                              finalDistrict.trim().isEmpty ||
                              finalWard.trim().isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Vui lòng điền đầy đủ thông tin địa chỉ')),
                            );
                            return;
                          }

                          final addrProv = context.read<AddressProvider>();
                          final notifProv = context.read<NotificationProvider>();
                          final messenger = ScaffoldMessenger.of(context);
                          final laThemMoi = addressToEdit == null;
                          if (addressToEdit == null) {
                            await addrProv.addAddress(AddressModel(
                              id: 'addr-${DateTime.now().millisecondsSinceEpoch}',
                              recipientName: nameCtrl.text.trim(),
                              phone: phoneCtrl.text.trim(),
                              province: finalProvince,
                              district: finalDistrict,
                              ward: finalWard,
                              detailAddress: detailCtrl.text.trim(),
                              isDefault: isDefault,
                            ));
                          } else {
                            await addrProv.updateAddress(addressToEdit.copyWith(
                              recipientName: nameCtrl.text.trim(),
                              phone: phoneCtrl.text.trim(),
                              province: finalProvince,
                              district: finalDistrict,
                              ward: finalWard,
                              detailAddress: detailCtrl.text.trim(),
                              isDefault: isDefault,
                            ));
                          }
                          // Neu may chu tu choi thi phai noi ra, khong de nguoi
                          // dung tuong da luu vao so trong khi chua luu duoc.
                          final loi = addrProv.errorMessage;
                          // Chi bao da luu vao so khi may chu that su nhan.
                          if (loi == null) {
                            notifProv.addNotification(
                              title: laThemMoi
                                  ? 'Đã thêm địa chỉ nhận hàng mới'
                                  : 'Đã cập nhật địa chỉ nhận hàng',
                              body: laThemMoi
                                  ? 'Địa chỉ của ${nameCtrl.text.trim()} tại $finalDistrict, $finalProvince đã được thêm vào sổ địa chỉ.'
                                  : 'Địa chỉ giao hàng tại $finalDistrict, $finalProvince đã được cập nhật thành công.',
                              type: 'system',
                            );
                          }
                          if (loi != null) {
                            messenger.showSnackBar(
                              SnackBar(
                                content: Text(loi),
                                backgroundColor: Colors.red.shade700,
                                duration: const Duration(seconds: 4),
                              ),
                            );
                          }
                          if (!ctx.mounted) return;
                          Navigator.pop(ctx);
                        },
                        child: Text(addressToEdit == null ? 'Lưu địa chỉ' : 'Cập nhật'),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final addrProv = context.watch<AddressProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Text(isSelectionMode ? 'Chọn địa chỉ nhận hàng' : 'Sổ địa chỉ của tôi'),
        centerTitle: true,
      ),
      body: addrProv.addresses.isEmpty
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Bạn chưa có địa chỉ nhận hàng nào',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  SizedBox(height: 6),
                  Text('Thêm địa chỉ ngay để thuận tiện khi mua sắm nhé!'),
                ],
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: addrProv.addresses.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (ctx, i) {
                final addr = addrProv.addresses[i];
                final isSelected = addrProv.selectedAddress?.id == addr.id;

                return InkWell(
                  onTap: () {
                    addrProv.selectAddress(addr);
                    if (isSelectionMode) {
                      Navigator.pop(context, addr);
                    }
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected ? Colors.black : Colors.grey.shade200,
                        width: isSelected ? 2 : 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.03),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              addr.recipientName,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '| ${addr.phone}',
                              style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                            ),
                            const Spacer(),
                            if (addr.isDefault)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.red.shade50,
                                  border: Border.all(color: Colors.redAccent),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Text(
                                  'Mặc định',
                                  style: TextStyle(color: Colors.redAccent, fontSize: 11, fontWeight: FontWeight.bold),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          addr.fullAddress,
                          style: TextStyle(fontSize: 13, color: Colors.grey.shade800),
                        ),
                        const Divider(height: 18),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            if (!addr.isDefault)
                              TextButton(
                                onPressed: () => addrProv.setDefaultAddress(addr.id),
                                child: const Text('Đặt làm mặc định', style: TextStyle(fontSize: 12, color: Colors.grey)),
                              ),
                            TextButton(
                              onPressed: () => _showAddressDialog(context, addressToEdit: addr),
                              child: const Text('Sửa', style: TextStyle(color: Colors.blueGrey, fontWeight: FontWeight.bold)),
                            ),
                            TextButton(
                              onPressed: () => addrProv.deleteAddress(addr.id),
                              child: const Text('Xóa', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        child: SafeArea(
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.black87,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Thêm địa chỉ nhận hàng mới', style: TextStyle(fontWeight: FontWeight.bold)),
            onPressed: () => _showAddressDialog(context),
          ),
        ),
      ),
    );
  }
}
