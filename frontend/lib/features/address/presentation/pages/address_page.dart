import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:menly_app/core/theme/app_colors.dart';
import 'package:menly_app/core/theme/app_spacing.dart';
import 'package:menly_app/core/theme/app_theme.dart';
import 'package:menly_app/core/widgets/app_buttons.dart';
import 'package:menly_app/core/widgets/state_views.dart';
import 'package:menly_app/features/address/data/models/address_model.dart';
import '../providers/address_provider.dart';
import '../widgets/administrative_unit_picker.dart';
import 'package:menly_app/features/notification/presentation/providers/notification_provider.dart';

/// Man hinh So dia chi giao hang & Chon dia chi khi dat hang (AP-DC1)
class AddressPage extends StatelessWidget {
  final bool isSelectionMode;

  const AddressPage({super.key, this.isSelectionMode = false});

  void _showAddressDialog(BuildContext context, {AddressModel? addressToEdit}) {
    final c = AppColors.of(context);
    final nameCtrl = TextEditingController(text: addressToEdit?.recipientName ?? '');
    final phoneCtrl = TextEditingController(text: addressToEdit?.phone ?? '');

    // Bo ba Tinh / Quan / Phuong do AdministrativeUnitPicker quan ly.
    var donViHanhChinh = DonViHanhChinh.chuanHoa(
      province: addressToEdit?.province ?? '',
      district: addressToEdit?.district ?? '',
      ward: addressToEdit?.ward ?? '',
    );
    final detailCtrl = TextEditingController(text: addressToEdit?.detailAddress ?? '');
    bool isDefault = addressToEdit?.isDefault ?? false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppTheme.radiusXl),
        ),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setState) {
            return Padding(
              padding: EdgeInsets.only(
                top: AppSpacing.xl,
                left: AppSpacing.lg,
                right: AppSpacing.lg,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + AppSpacing.xl,
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
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: c.textPrimary,
                          ),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(ctx),
                          child: Text('Đóng', style: TextStyle(color: c.textMuted, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),
                    TextField(
                      controller: nameCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Họ và tên người nhận',
                        isDense: true,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    TextField(
                      controller: phoneCtrl,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        labelText: 'Số điện thoại',
                        isDense: true,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    AdministrativeUnitPicker(
                      giaTri: donViHanhChinh,
                      onChanged: (chon) => donViHanhChinh = chon,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    TextField(
                      controller: detailCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Địa chỉ cụ thể (Số nhà, tên đường)',
                        isDense: true,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Đặt làm địa chỉ mặc định'),
                      value: isDefault,
                      activeThumbColor: c.primary,
                      onChanged: (val) => setState(() => isDefault = val),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    PrimaryButton(
                      label: addressToEdit == null ? 'Lưu địa chỉ' : 'Cập nhật',
                      onPressed: () async {
                        final finalProvince = donViHanhChinh.province;
                        final finalDistrict = donViHanhChinh.district;
                        final finalWard = donViHanhChinh.ward;

                        if (nameCtrl.text.trim().isEmpty ||
                            phoneCtrl.text.trim().isEmpty ||
                            detailCtrl.text.trim().isEmpty ||
                            finalProvince.trim().isEmpty ||
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
                              backgroundColor: c.danger,
                              duration: const Duration(seconds: 4),
                            ),
                          );
                        }
                        if (!ctx.mounted) return;
                        Navigator.pop(ctx);
                      },
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
    final c = AppColors.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(isSelectionMode ? 'Chọn địa chỉ nhận hàng' : 'Sổ địa chỉ của tôi'),
        centerTitle: true,
      ),
      body: addrProv.addresses.isEmpty
          ? const StatusView(
              icon: Icons.location_on_outlined,
              title: 'Bạn chưa có địa chỉ nhận hàng nào',
              message: 'Thêm địa chỉ ngay để thuận tiện khi mua sắm nhé!',
            )
          : ListView.separated(
              padding: const EdgeInsets.all(AppSpacing.lg),
              itemCount: addrProv.addresses.length,
              separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.md),
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
                  borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                  child: Container(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    decoration: BoxDecoration(
                      color: c.surface,
                      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                      border: Border.all(
                        // Vien 2px mau ink tren the trang nhin nhu mot khung
                        // den dong khung, nang hon han cac the khac trong app.
                        color: isSelected ? c.primary : c.border,
                        width: isSelected ? 1.4 : 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: c.shadow,
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
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                                color: c.textPrimary,
                              ),
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            Text(
                              '| ${addr.phone}',
                              style: TextStyle(color: c.textSecondary, fontSize: 13),
                            ),
                            const Spacer(),
                            if (addr.isDefault)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: AppSpacing.sm,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: c.primary.withValues(alpha: 0.10),
                                  borderRadius:
                                      BorderRadius.circular(AppTheme.radiusPill),
                                ),
                                child: Text(
                                  'Mặc định',
                                  style: TextStyle(
                                      color: c.primary,
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          addr.fullAddress,
                          style: TextStyle(fontSize: 13, color: c.textSecondary),
                        ),
                        const Divider(height: 18),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            if (!addr.isDefault)
                              TextButton(
                                onPressed: () => addrProv.setDefaultAddress(addr.id),
                                child: Text('Đặt làm mặc định', style: TextStyle(fontSize: 12, color: c.textMuted)),
                              ),
                            TextButton(
                              onPressed: () => _showAddressDialog(context, addressToEdit: addr),
                              child: Text('Sửa', style: TextStyle(color: c.textSecondary, fontWeight: FontWeight.bold)),
                            ),
                            TextButton(
                              onPressed: () => addrProv.deleteAddress(addr.id),
                              child: Text('Xóa', style: TextStyle(color: c.danger, fontWeight: FontWeight.bold)),
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
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: SafeArea(
          child: PrimaryButton(
            label: 'Thêm địa chỉ nhận hàng mới',
            onPressed: () => _showAddressDialog(context),
          ),
        ),
      ),
    );
  }
}
