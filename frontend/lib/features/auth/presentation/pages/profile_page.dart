import '../widgets/profile_menu_item.dart';
import '../widgets/profile_stat_item.dart';
import 'package:menly_app/core/widgets/display_settings.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:menly_app/core/theme/app_theme.dart';
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

/// Trang Ca nhan (Profile) quan ly toan bo thong tin tai khoan, don hang, dia chi va tien ich
class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  void _showEditProfileModal(BuildContext context, AuthProvider auth) {
    final user = auth.user;
    final nameCtrl = TextEditingController(text: user?.fullName ?? '');
    final phoneCtrl = TextEditingController(text: user?.phone ?? '');
    final selectedPreset = AvatarPreset.find(user?.avatarUrl);
    final avatarCtrl = TextEditingController(
      text: selectedPreset == null ? user?.avatarUrl ?? '' : '',
    );
    String? selectedPresetId = selectedPreset?.id;
    var isSaving = false;

    const avatarPresets = AvatarPreset.presets;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                top: 20,
                left: 20,
                right: 20,
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
                        const Text(
                          'Chỉnh sửa thông tin cá nhân',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(ctx),
                          child: const Text('Đóng', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    const Text('Chọn ảnh đại diện:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        ProfileAvatar(
                          avatarUrl: selectedPresetId ??
                              (avatarCtrl.text.trim().isEmpty ? null : avatarCtrl.text.trim()),
                          radius: 30,
                          fallbackText: user?.fullName ?? 'M',
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Ảnh có sẵn, sử dụng không cần mạng:', style: TextStyle(fontSize: 11, color: Colors.grey)),
                              const SizedBox(height: 6),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: avatarPresets.map((preset) {
                                  final isSelected = selectedPresetId == preset.id;
                                  return Tooltip(
                                    message: preset.label,
                                    child: InkWell(
                                      customBorder: const CircleBorder(),
                                      onTap: () => setModalState(() {
                                        selectedPresetId = preset.id;
                                        avatarCtrl.clear();
                                      }),
                                      child: Container(
                                        padding: const EdgeInsets.all(2),
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: isSelected ? AppTheme.primary : Colors.transparent,
                                            width: 2,
                                          ),
                                        ),
                                        child: ProfileAvatar(avatarUrl: preset.id, radius: 19),
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: avatarCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Hoặc nhập URL ảnh đại diện',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                      onChanged: (_) => setModalState(() {
                        selectedPresetId = null;
                      }),
                    ),
                    const SizedBox(height: 16),

                    // Ho va ten
                    TextField(
                      controller: nameCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Họ và tên',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                    ),
                    const SizedBox(height: 14),

                    // So dien thoai
                    TextField(
                      controller: phoneCtrl,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        labelText: 'Số điện thoại',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                    ),
                    const SizedBox(height: 20),

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.black87,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: isSaving ? null : () async {
                          if (nameCtrl.text.trim().isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Họ tên không được để trống')),
                            );
                            return;
                          }

                          setModalState(() => isSaving = true);
                          final updated = await auth.updateProfile(
                            fullName: nameCtrl.text,
                            phone: phoneCtrl.text,
                            avatarUrl: selectedPresetId ?? avatarCtrl.text.trim(),
                          );

                          if (context.mounted) {
                            if (!updated) {
                              setModalState(() => isSaving = false);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(auth.profileUpdateError ?? 'Không thể cập nhật hồ sơ'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                              return;
                            }
                            Navigator.pop(ctx);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Cập nhật thông tin thành công!'),
                                backgroundColor: Colors.green,
                              ),
                            );
                          }
                        },
                        child: isSaving
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : const Text('Lưu thông tin', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
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
    final auth = context.watch<AuthProvider>();
    final orderProv = context.watch<OrderProvider>();
    final wishlist = context.watch<WishlistProvider>();
    final voucherProv = context.watch<VoucherProvider>();
    final user = auth.user;

    return Scaffold(
      backgroundColor: AppTheme.scaffoldBackground,
      appBar: AppBar(
        title: const Text('Tài khoản cá nhân'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. THE THONG TIN NGUOI DUNG & AVATAR
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.border),
                boxShadow: AppTheme.softShadow,
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      // Avatar
                      Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: AppTheme.primary, width: 2),
                        ),
                        child: ProfileAvatar(
                          avatarUrl: user?.avatarUrl,
                          radius: 36,
                          fallbackText: user?.fullName ?? 'M',
                        ),
                      ),
                      const SizedBox(width: 16),
                      // Thong tin ca nhan
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              user?.fullName ?? 'Khách hàng Menly',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 3),
                            Text(
                              user?.email ?? 'Chưa đăng nhập',
                              style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              user?.phone ?? 'Chưa cập nhật SĐT',
                              style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                            ),
                            const SizedBox(height: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF0E4D4),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                user?.role == 'admin' ? 'Quản trị viên' : 'Thành viên Menly VIP',
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: Color(0xFF8A6234),
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 24),
                  // Nut doi thong tin & avatar hoac Dang nhap / Dang ky ngay
                  if (!auth.isLoggedIn)
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          elevation: 0,
                        ),
                        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LoginPage())),
                        child: const Text('Đăng nhập / Đăng ký ngay', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      ),
                    )
                  else
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppTheme.primary,
                          side: const BorderSide(color: AppTheme.primary),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                        ),
                        onPressed: () => _showEditProfileModal(context, auth),
                        child: const Text('Chỉnh sửa thông tin & Avatar', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // 2. THANH THONG KE NHANH
            Container(
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppTheme.border),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  ProfileStatItem(
                    label: 'Đơn hàng',
                    value: '${orderProv.allOrders.length}',
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MyOrdersPage())),
                  ),
                  Container(height: 28, width: 1, color: Colors.grey.shade200),
                  ProfileStatItem(
                    label: 'Yêu thích',
                    value: '${wishlist.count}',
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const WishlistPage())),
                  ),
                  Container(height: 28, width: 1, color: Colors.grey.shade200),
                  ProfileStatItem(
                    label: 'Voucher',
                    value: '${voucherProv.vouchers.length}',
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const VoucherListPage())),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // 3. NHOM: QUAN LY DON HANG & MUA SAM
            const Text('Đơn hàng & Mua sắm', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppTheme.border),
              ),
              child: Column(
                children: [
                  ProfileMenuItem(
                    title: 'Đơn hàng của tôi',
                    subtitle: 'Theo dõi tiến trình giao hàng và lịch sử mua sắm',
                    badge: '${orderProv.allOrders.length}',
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MyOrdersPage())),
                  ),
                  const Divider(height: 1),
                  ProfileMenuItem(
                    title: 'Tra cứu đơn hàng',
                    subtitle: 'Nhập mã đơn hoặc số điện thoại để xem tình trạng đơn hàng',
                    badge: 'Mới',
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const OrderTrackPage())),
                  ),
                  const Divider(height: 1),
                  ProfileMenuItem(
                    title: 'Thông báo',
                    subtitle: 'Xem khuyến mãi, tin tức và thông báo từ shop',
                    badge: context.watch<NotificationProvider>().unreadCount > 0
                        ? context.watch<NotificationProvider>().unreadCountLabel
                        : null,
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationsPage())),
                  ),
                  const Divider(height: 1),
                  ProfileMenuItem(
                    title: 'Kho Voucher giảm giá',
                    subtitle: 'Xem các mã khuyến mãi áp dụng khi thanh toán',
                    badge: 'Mới',
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const VoucherListPage())),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // 4. NHOM: CAI DAT TAI KHOAN
            const Text('Cài đặt tài khoản', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppTheme.border),
              ),
              child: Column(
                children: [
                  ProfileMenuItem(
                    title: 'Địa chỉ của tôi',
                    subtitle: 'Quản lý danh sách địa chỉ nhận hàng',
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AddressPage())),
                  ),
                  const Divider(height: 1),
                  ProfileMenuItem(
                    title: 'Đổi mật khẩu',
                    subtitle: 'Cập nhật mật khẩu mới bảo mật tài khoản',
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ChangePasswordPage())),
                  ),
                  const Divider(height: 1),
                  ProfileMenuItem(
                    title: 'Giao diện & Hiển thị',
                    subtitle: 'Tùy chỉnh màu chủ đạo và chế độ Sáng / Tối',
                    onTap: () => showDisplaySettings(context),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // 5. NHOM: HO TRO & QUAN TRI
            const Text('Hỗ trợ & Quản trị', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppTheme.border),
              ),
              child: Column(
                children: [
                  ProfileMenuItem(
                    title: 'Quản lý đơn hàng (Admin/Nhân viên)',
                    subtitle: 'Xem danh sách và cập nhật trạng thái giao hàng',
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const StaffOrderManagementPage())),
                  ),
                  if (user?.role == 'staff' || user?.role == 'admin') ...[
                    const Divider(height: 1),
                    ProfileMenuItem(
                      title: 'Hội thoại CSKH',
                      subtitle: 'Trả lời tin nhắn từ khách hàng',
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const StaffSupportInboxPage()),
                      ),
                    ),
                  ],
                  const Divider(height: 1),
                  ProfileMenuItem(
                    title: 'Chat với nhân viên',
                    subtitle: 'Tư vấn chọn size & phối đồ tức thì 24/7',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const LiveChatPage()),
                    ),
                  ),
                  const Divider(height: 1),
                  ProfileMenuItem(
                    title: 'Trung tâm trợ giúp & CSKH',
                    subtitle: 'Hotline 1900 6868, giải đáp thắc mắc thường gặp',
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const FAQPage())),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // 6. NUT DANG XUAT / DANG NHAP
            SizedBox(
              width: double.infinity,
              child: auth.isLoggedIn
                  ? OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: const BorderSide(color: Colors.red),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: const Text('Xác nhận đăng xuất'),
                            content: const Text('Bạn có chắc chắn muốn đăng xuất tài khoản?'),
                            actions: [
                              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Hủy')),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
                                onPressed: () async {
                                  await auth.logout();
                                  if (ctx.mounted) Navigator.pop(ctx);
                                },
                                child: const Text('Đăng xuất'),
                              ),
                            ],
                          ),
                        );
                      },
                      child: const Text('Đăng xuất', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    )
                  : ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black87,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LoginPage())),
                      child: const Text('Đăng nhập / Đăng ký', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
