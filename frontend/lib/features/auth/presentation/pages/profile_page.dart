import 'dart:typed_data';
import 'package:image_picker/image_picker.dart';
import '../widgets/profile_menu_item.dart';
import '../widgets/profile_stat_item.dart';
import 'package:menly_app/core/widgets/display_settings.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:menly_app/core/theme/app_colors.dart';
import 'package:menly_app/core/theme/app_spacing.dart';
import 'package:menly_app/core/theme/app_theme.dart';
import 'package:menly_app/core/widgets/app_buttons.dart';
import 'package:menly_app/features/address/presentation/pages/address_page.dart';
import 'package:menly_app/features/auth/presentation/pages/change_password_page.dart';
import 'package:menly_app/features/auth/presentation/pages/login_page.dart';
import 'package:menly_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:menly_app/features/auth/presentation/widgets/profile_avatar.dart';
import 'package:menly_app/features/notification/presentation/pages/notifications_page.dart';
import 'package:menly_app/features/notification/presentation/providers/notification_provider.dart';
import 'package:menly_app/features/order/presentation/pages/my_orders_page.dart';
import 'package:menly_app/features/order/presentation/pages/order_track_page.dart';
import 'package:menly_app/features/order/presentation/pages/staff_order_management_page.dart';
import 'package:menly_app/features/order/presentation/providers/order_provider.dart';
import 'package:menly_app/features/support/presentation/pages/faq_page.dart';
import 'package:menly_app/features/support/presentation/pages/staff_support_inbox_page.dart';
import 'package:menly_app/features/chat/presentation/pages/live_chat_page.dart';
import 'package:menly_app/features/voucher/presentation/pages/voucher_list_page.dart';
import 'package:menly_app/features/voucher/presentation/providers/voucher_provider.dart';
import 'package:menly_app/features/wishlist/presentation/pages/wishlist_page.dart';
import 'package:menly_app/features/wishlist/presentation/providers/wishlist_provider.dart';
import 'package:menly_app/core/session/user_session.dart';

/// Trang Ca nhan (Profile) quan ly toan bo thong tin tai khoan, don hang, dia chi va tien ich
class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  void _showEditProfileModal(BuildContext context, AuthProvider auth) {
    final c = AppColors.of(context);
    final user = auth.user;
    final nameCtrl = TextEditingController(text: user?.fullName ?? '');
    final phoneCtrl = TextEditingController(text: user?.phone ?? '');
    final selectedPreset = AvatarPreset.find(user?.avatarUrl);
    final avatarCtrl = TextEditingController(
      text: selectedPreset == null ? user?.avatarUrl ?? '' : '',
    );
    String? selectedPresetId = selectedPreset?.id;
    XFile? pickedAvatarFile;
    Uint8List? pickedAvatarBytes;
    var isSaving = false;

    const avatarPresets = AvatarPreset.presets;

    Future<void> pickAvatar(
        StateSetter setModalState, ImageSource source) async {
      try {
        final picker = ImagePicker();
        final picked = await picker.pickImage(
          source: source,
          maxWidth: 1024,
          maxHeight: 1024,
          imageQuality: 85,
        );
        if (picked != null) {
          final bytes = await picked.readAsBytes();
          setModalState(() {
            pickedAvatarFile = picked;
            pickedAvatarBytes = bytes;
            selectedPresetId = null;
            avatarCtrl.clear();
          });
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(source == ImageSource.camera
                  ? 'Không thể mở máy ảnh: $e'
                  : 'Không thể mở bộ sưu tập: $e'),
            ),
          );
        }
      }
    }

    Future<void> showSourceSheet(
        BuildContext context, StateSetter setModalState) async {
      final source = await showModalBottomSheet<ImageSource>(
        context: context,
        backgroundColor: c.surface,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppTheme.radiusLg),
          ),
        ),
        builder: (sheetCtx) => SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                decoration: BoxDecoration(
                  color: c.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Text(
                  'Chọn ảnh đại diện',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: c.textPrimary,
                  ),
                ),
              ),
              const Divider(height: 1),
              ListTile(
                leading: Icon(Icons.camera_alt_outlined, color: c.primary),
                title: const Text('Chụp ảnh từ máy ảnh (Camera)'),
                onTap: () => Navigator.pop(sheetCtx, ImageSource.camera),
              ),
              ListTile(
                leading: Icon(Icons.photo_library_outlined, color: c.primary),
                title: const Text('Chọn ảnh từ bộ sưu tập (Thư viện)'),
                onTap: () => Navigator.pop(sheetCtx, ImageSource.gallery),
              ),
              const SizedBox(height: AppSpacing.sm),
            ],
          ),
        ),
      );

      if (source != null) {
        await pickAvatar(setModalState, source);
      }
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: c.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppTheme.radiusXl),
        ),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                top: AppSpacing.xl,
                left: AppSpacing.xl,
                right: AppSpacing.xl,
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
                          'Chỉnh sửa thông tin cá nhân',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: c.textPrimary,
                          ),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(ctx),
                          child: Text('Đóng',
                              style: TextStyle(
                                  color: c.textMuted,
                                  fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.lg),

                    Text(
                      'Chọn ảnh đại diện:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: c.textPrimary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),

                    // Avatar preview & Nut chup anh / chon tu bo suu tap
                    Row(
                      children: [
                        // Avatar preview (nhan truc tiep de mo menu chup anh / chon file)
                        GestureDetector(
                          onTap: () => showSourceSheet(ctx, setModalState),
                          child: Stack(
                            children: [
                              Container(
                                width: 72,
                                height: 72,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: pickedAvatarBytes != null
                                        ? c.success
                                        : c.primary,
                                    width: 2.5,
                                  ),
                                ),
                                child: pickedAvatarBytes != null
                                    ? ClipOval(
                                        child: Image.memory(
                                          pickedAvatarBytes!,
                                          width: 72,
                                          height: 72,
                                          fit: BoxFit.cover,
                                        ),
                                      )
                                    : ProfileAvatar(
                                        avatarUrl: selectedPresetId ??
                                            (avatarCtrl.text.trim().isEmpty
                                                ? null
                                                : avatarCtrl.text.trim()),
                                        radius: 36,
                                        fallbackText: user?.fullName ?? 'M',
                                      ),
                              ),
                              Positioned(
                                right: 0,
                                bottom: 0,
                                child: Container(
                                  padding: const EdgeInsets.all(AppSpacing.xs),
                                  decoration: BoxDecoration(
                                    color: pickedAvatarBytes != null
                                        ? c.success
                                        : c.primary,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                        color: c.surface, width: 1.5),
                                  ),
                                  child: Icon(
                                    pickedAvatarBytes != null
                                        ? Icons.check
                                        : Icons.camera_alt,
                                    size: 13,
                                    color: c.onPrimary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: AppSpacing.lg),
                        // 2 nut: Chup anh & Bo suu tap
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: OutlinedButton.icon(
                                      icon: const Icon(
                                          Icons.camera_alt_outlined,
                                          size: 15),
                                      label: const Text('Chụp ảnh',
                                          style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 12)),
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: c.primary,
                                        side: BorderSide(color: c.primary),
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 6,
                                            vertical: AppSpacing.sm),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                              AppTheme.radiusSm),
                                        ),
                                      ),
                                      onPressed: () => pickAvatar(
                                          setModalState, ImageSource.camera),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: OutlinedButton.icon(
                                      icon: const Icon(
                                          Icons.photo_library_outlined,
                                          size: 15),
                                      label: const Text('Bộ sưu tập',
                                          style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 12)),
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: c.primary,
                                        side: BorderSide(color: c.primary),
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 6,
                                            vertical: AppSpacing.sm),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                              AppTheme.radiusSm),
                                        ),
                                      ),
                                      onPressed: () => pickAvatar(
                                          setModalState, ImageSource.gallery),
                                    ),
                                  ),
                                ],
                              ),
                              if (pickedAvatarFile != null) ...[
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    Icon(Icons.check_circle,
                                        size: 14, color: c.success),
                                    const SizedBox(width: AppSpacing.xs),
                                    Expanded(
                                      child: Text(
                                        'Đã chọn: ${pickedAvatarFile!.name}',
                                        style: TextStyle(
                                            fontSize: 11,
                                            color: c.success,
                                            fontWeight: FontWeight.w500),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    InkWell(
                                      onTap: () => setModalState(() {
                                        pickedAvatarFile = null;
                                        pickedAvatarBytes = null;
                                      }),
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: AppSpacing.xs),
                                        child: Icon(Icons.close,
                                            size: 15, color: c.textMuted),
                                      ),
                                    ),
                                  ],
                                ),
                              ] else ...[
                                const SizedBox(height: 5),
                                Text(
                                  'Chụp trực tiếp hoặc tải từ máy (tối đa 5MB)',
                                  style: TextStyle(
                                      fontSize: 10.5, color: c.textMuted),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.lg),

                    // Mau anh co san
                    Text(
                      'Hoặc chọn ảnh đại diện có sẵn:',
                      style: TextStyle(fontSize: 11, color: c.textMuted),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: AppSpacing.sm,
                      runSpacing: AppSpacing.sm,
                      children: avatarPresets.map((preset) {
                        final isSelected = selectedPresetId == preset.id &&
                            pickedAvatarFile == null;
                        return Tooltip(
                          message: preset.label,
                          child: InkWell(
                            customBorder: const CircleBorder(),
                            onTap: () => setModalState(() {
                              selectedPresetId = preset.id;
                              pickedAvatarFile = null;
                              pickedAvatarBytes = null;
                              avatarCtrl.clear();
                            }),
                            child: Container(
                              padding: const EdgeInsets.all(2),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: isSelected
                                      ? c.primary
                                      : Colors.transparent,
                                  width: 2,
                                ),
                              ),
                              child: ProfileAvatar(
                                  avatarUrl: preset.id, radius: 19),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 12),

                    // Hoac nhap URL
                    TextField(
                      controller: avatarCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Hoặc nhập liên kết (URL) ảnh đại diện',
                        isDense: true,
                      ),
                      onChanged: (_) => setModalState(() {
                        selectedPresetId = null;
                        pickedAvatarFile = null;
                        pickedAvatarBytes = null;
                      }),
                    ),
                    const SizedBox(height: AppSpacing.lg),

                    // Ho va ten
                    TextField(
                      controller: nameCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Họ và tên',
                        isDense: true,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),

                    // So dien thoai
                    TextField(
                      controller: phoneCtrl,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        labelText: 'Số điện thoại',
                        isDense: true,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl),

                    PrimaryButton(
                      label: 'Lưu thông tin',
                      loading: isSaving,
                      onPressed: isSaving
                          ? null
                          : () async {
                              if (nameCtrl.text.trim().isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      content:
                                          Text('Họ tên không được để trống')),
                                );
                                return;
                              }

                              setModalState(() => isSaving = true);

                              String? avatarUrlToSave =
                                  selectedPresetId ?? avatarCtrl.text.trim();

                              // 1. Neu co chon anh tu bo suu tap -> Tai len server
                              if (pickedAvatarFile != null) {
                                final uploadedUrl =
                                    await auth.uploadAvatar(pickedAvatarFile!);
                                if (uploadedUrl == null) {
                                  setModalState(() => isSaving = false);
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(auth.profileUpdateError ??
                                            'Không thể tải ảnh đại diện lên máy chủ'),
                                        backgroundColor: c.danger,
                                      ),
                                    );
                                  }
                                  return;
                                }
                                avatarUrlToSave = uploadedUrl;
                              }

                              // 2. Cap nhat ho so nguoi dung
                              final updated = await auth.updateProfile(
                                fullName: nameCtrl.text,
                                phone: phoneCtrl.text,
                                avatarUrl: avatarUrlToSave,
                              );

                              if (context.mounted) {
                                if (!updated) {
                                  setModalState(() => isSaving = false);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(auth.profileUpdateError ??
                                          'Không thể cập nhật hồ sơ'),
                                      backgroundColor: c.danger,
                                    ),
                                  );
                                  return;
                                }
                                Navigator.pop(ctx);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: const Text(
                                        'Cập nhật thông tin thành công!'),
                                    backgroundColor: c.success,
                                  ),
                                );
                              }
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
    final auth = context.watch<AuthProvider>();
    final orderProv = context.watch<OrderProvider>();
    final wishlist = context.watch<WishlistProvider>();
    final voucherProv = context.watch<VoucherProvider>();
    final user = auth.user;
    final c = AppColors.of(context);

    return Scaffold(
      backgroundColor: c.background,
      appBar: AppBar(
        title: const Text('Tài khoản cá nhân'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. THE THONG TIN NGUOI DUNG & AVATAR
            //
            // The nay to nen ink dam de lam diem neo cho ca man: phan con lai
            // deu la the trang tren nen trang, khong co gi dan mat.
            Container(
              padding: const EdgeInsets.all(AppSpacing.xl),
              decoration: BoxDecoration(
                color: c.inkCard,
                borderRadius: BorderRadius.circular(AppTheme.radiusXl),
                boxShadow: [
                  BoxShadow(
                    color: c.shadow,
                    blurRadius: 18,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      // Avatar (co the click truc tiep de chinh sua)
                      GestureDetector(
                        onTap: auth.isLoggedIn
                            ? () => _showEditProfileModal(context, auth)
                            : null,
                        child: Stack(
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(color: c.onInk, width: 2),
                              ),
                              child: ProfileAvatar(
                                avatarUrl: user?.avatarUrl,
                                radius: 36,
                                fallbackText: user?.fullName ?? 'M',
                              ),
                            ),
                            if (auth.isLoggedIn)
                              Positioned(
                                right: 0,
                                bottom: 0,
                                child: Container(
                                  padding: const EdgeInsets.all(AppSpacing.xs),
                                  decoration: BoxDecoration(
                                    color: c.surface,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(Icons.camera_alt,
                                      size: 13, color: c.textPrimary),
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(width: AppSpacing.lg),
                      // Thong tin ca nhan
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              user?.fullName ?? 'Khách hàng Menly',
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 18,
                                color: c.onInk,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 3),
                            Text(
                              user?.email ?? 'Chưa đăng nhập',
                              style: TextStyle(
                                color: c.onInk.withValues(alpha: 0.72),
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              user?.phone ?? 'Chưa cập nhật SĐT',
                              style: TextStyle(
                                color: c.onInk.withValues(alpha: 0.72),
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.sm,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: c.onInk.withValues(alpha: 0.16),
                                borderRadius:
                                    BorderRadius.circular(AppTheme.radiusPill),
                              ),
                              child: Text(
                                user?.role == 'admin'
                                    ? 'Quản trị viên'
                                    : 'Thành viên Menly VIP',
                                style: TextStyle(
                                  fontSize: 10.5,
                                  color: c.onInk,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  Divider(
                    height: AppSpacing.xxl,
                    color: c.onInk.withValues(alpha: 0.18),
                  ),
                  // Nut doi thong tin & avatar hoac Dang nhap / Dang ky ngay.
                  // Nam tren nen ink nen phai dao mau: nen sang, chu toi.
                  if (!auth.isLoggedIn)
                    PrimaryButton(
                      label: 'Đăng nhập / Đăng ký ngay',
                      height: 48,
                      background: c.onInk,
                      foreground: c.inkCard,
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const LoginPage()),
                      ),
                    )
                  else
                    PrimaryButton(
                      label: 'Chỉnh sửa thông tin & Avatar',
                      height: 48,
                      background: c.onInk,
                      foreground: c.inkCard,
                      onPressed: () => _showEditProfileModal(context, auth),
                    ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            // 2. THANH THONG KE NHANH
            Container(
              padding: const EdgeInsets.symmetric(
                vertical: AppSpacing.lg,
                horizontal: AppSpacing.lg,
              ),
              decoration: BoxDecoration(
                color: c.surface,
                borderRadius: BorderRadius.circular(AppTheme.radiusCard),
                border: Border.all(color: c.border),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  ProfileStatItem(
                    icon: Icons.receipt_long_rounded,
                    label: 'Đơn hàng',
                    value: '${orderProv.allOrders.length}',
                    onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const MyOrdersPage())),
                  ),
                  Container(height: 32, width: 1, color: c.border),
                  ProfileStatItem(
                    icon: Icons.favorite_border_rounded,
                    label: 'Yêu thích',
                    value: '${wishlist.count}',
                    onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const WishlistPage())),
                  ),
                  Container(height: 32, width: 1, color: c.border),
                  ProfileStatItem(
                    icon: Icons.confirmation_number_outlined,
                    label: 'Voucher',
                    value: '${voucherProv.vouchers.length}',
                    onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const VoucherListPage())),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xl),

            // 3. NHOM: QUAN LY DON HANG & MUA SAM
            Text(
              'Đơn hàng & Mua sắm',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15,
                color: c.textPrimary,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Container(
              decoration: BoxDecoration(
                color: c.surface,
                borderRadius: BorderRadius.circular(AppTheme.radiusCard),
                border: Border.all(color: c.border),
              ),
              child: Column(
                children: [
                  ProfileMenuItem(
                    icon: Icons.receipt_long_rounded,
                    title: 'Đơn hàng của tôi',
                    subtitle:
                        'Theo dõi tiến trình giao hàng và lịch sử mua sắm',
                    badge: '${orderProv.allOrders.length}',
                    onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const MyOrdersPage())),
                  ),
                  const Divider(height: 1),
                  ProfileMenuItem(
                    icon: Icons.travel_explore_rounded,
                    title: 'Tra cứu đơn hàng',
                    subtitle:
                        'Nhập mã đơn hoặc số điện thoại để xem tình trạng đơn hàng',
                    badge: 'Mới',
                    onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const OrderTrackPage())),
                  ),
                  const Divider(height: 1),
                  ProfileMenuItem(
                    icon: Icons.notifications_none_rounded,
                    title: 'Thông báo',
                    subtitle: 'Xem khuyến mãi, tin tức và thông báo từ shop',
                    badge: context.watch<NotificationProvider>().unreadCount > 0
                        ? context.watch<NotificationProvider>().unreadCountLabel
                        : null,
                    onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const NotificationsPage())),
                  ),
                  const Divider(height: 1),
                  ProfileMenuItem(
                    icon: Icons.confirmation_number_outlined,
                    title: 'Kho Voucher giảm giá',
                    subtitle: 'Xem các mã khuyến mãi áp dụng khi thanh toán',
                    badge: 'Mới',
                    onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const VoucherListPage())),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xl),

            // 4. NHOM: CAI DAT TAI KHOAN
            Text(
              'Cài đặt tài khoản',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15,
                color: c.textPrimary,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Container(
              decoration: BoxDecoration(
                color: c.surface,
                borderRadius: BorderRadius.circular(AppTheme.radiusCard),
                border: Border.all(color: c.border),
              ),
              child: Column(
                children: [
                  ProfileMenuItem(
                    icon: Icons.location_on_outlined,
                    title: 'Địa chỉ của tôi',
                    subtitle: 'Quản lý danh sách địa chỉ nhận hàng',
                    onTap: () => Navigator.push(context,
                        MaterialPageRoute(builder: (_) => const AddressPage())),
                  ),
                  const Divider(height: 1),
                  ProfileMenuItem(
                    icon: Icons.lock_outline_rounded,
                    title: 'Đổi mật khẩu',
                    subtitle: 'Cập nhật mật khẩu mới bảo mật tài khoản',
                    onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const ChangePasswordPage())),
                  ),
                  const Divider(height: 1),
                  ProfileMenuItem(
                    icon: Icons.palette_outlined,
                    title: 'Giao diện & Hiển thị',
                    subtitle: 'Tùy chỉnh màu chủ đạo và chế độ Sáng / Tối',
                    onTap: () => showDisplaySettings(context),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xl),

            // 5. NHOM: HO TRO & QUAN TRI
            Text(
              'Hỗ trợ & Quản trị',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15,
                color: c.textPrimary,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Container(
              decoration: BoxDecoration(
                color: c.surface,
                borderRadius: BorderRadius.circular(AppTheme.radiusCard),
                border: Border.all(color: c.border),
              ),
              child: Column(
                children: [
                  ProfileMenuItem(
                    icon: Icons.inventory_2_outlined,
                    title: 'Quản lý đơn hàng (Admin/Nhân viên)',
                    subtitle: 'Xem danh sách và cập nhật trạng thái giao hàng',
                    onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const StaffOrderManagementPage())),
                  ),
                  if (user?.role == 'staff' || user?.role == 'admin') ...[
                    const Divider(height: 1),
                    ProfileMenuItem(
                      icon: Icons.forum_outlined,
                      title: 'Hội thoại CSKH',
                      subtitle: 'Trả lời tin nhắn từ khách hàng',
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const StaffSupportInboxPage()),
                      ),
                    ),
                  ],
                  const Divider(height: 1),
                  ProfileMenuItem(
                    icon: Icons.support_agent_rounded,
                    title: 'Chat với nhân viên',
                    subtitle: 'Tư vấn chọn size & phối đồ tức thì 24/7',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const LiveChatPage()),
                    ),
                  ),
                  const Divider(height: 1),
                  ProfileMenuItem(
                    icon: Icons.help_outline_rounded,
                    title: 'Trung tâm trợ giúp & CSKH',
                    subtitle: 'Hotline 1900 6868, giải đáp thắc mắc thường gặp',
                    onTap: () => Navigator.push(context,
                        MaterialPageRoute(builder: (_) => const FAQPage())),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xxl),

            // 6. NUT DANG XUAT / DANG NHAP
            auth.isLoggedIn
                ? SecondaryButton(
                    label: 'Đăng xuất',
                    foreground: c.danger,
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('Xác nhận đăng xuất'),
                          content: const Text(
                              'Bạn có chắc chắn muốn đăng xuất tài khoản?'),
                          actions: [
                            TextButton(
                                onPressed: () => Navigator.pop(ctx),
                                child: const Text('Hủy')),
                            DestructiveButton(
                              label: 'Đăng xuất',
                              expanded: false,
                              height: 40,
                              onPressed: () async {
                                // Xoa luon du lieu trong bo nho, khong chi
                                // phien dang nhap: nguoi vao sau tren cung
                                // mot may khong duoc thay gio hang, dia chi
                                // hay danh sach yeu thich cua nguoi truoc.
                                clearUserDataInMemory(context);
                                await auth.logout();
                                if (ctx.mounted) Navigator.pop(ctx);
                              },
                            ),
                          ],
                        ),
                      );
                    },
                  )
                : PrimaryButton(
                    label: 'Đăng nhập / Đăng ký',
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const LoginPage()),
                    ),
                  ),
            const SizedBox(height: AppSpacing.xxl),
          ],
        ),
      ),
    );
  }
}
