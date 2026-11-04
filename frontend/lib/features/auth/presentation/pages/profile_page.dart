import 'package:menly_app/core/widgets/display_settings.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:menly_app/core/theme/app_theme.dart';
import 'package:menly_app/features/address/presentation/pages/address_page.dart';
import 'package:menly_app/features/auth/presentation/pages/change_password_page.dart';
import 'package:menly_app/features/auth/presentation/pages/login_page.dart';
import 'package:menly_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:menly_app/features/order/presentation/pages/my_orders_page.dart';
import 'package:menly_app/features/order/presentation/pages/order_track_page.dart';
import 'package:menly_app/features/order/presentation/pages/staff_order_management_page.dart';
import 'package:menly_app/features/order/presentation/providers/order_provider.dart';
import 'package:menly_app/features/support/presentation/pages/faq_page.dart';
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
    final avatarCtrl = TextEditingController(text: user?.avatarUrl ?? '');

    final avatarPresets = [
      'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=300&auto=format&fit=crop&q=80',
      'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=300&auto=format&fit=crop&q=80',
      'https://images.unsplash.com/photo-1492562080023-ab3db95bfbce?w=300&auto=format&fit=crop&q=80',
      'https://images.unsplash.com/photo-1519085360753-af0119f7cbe7?w=300&auto=format&fit=crop&q=80',
    ];

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

                    // Chon Avatar
                    const Text('Ảnh đại diện (Avatar):', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 30,
                          backgroundColor: Colors.grey.shade200,
                          backgroundImage: avatarCtrl.text.isNotEmpty ? NetworkImage(avatarCtrl.text) : null,
                          child: avatarCtrl.text.isEmpty
                              ? const Text('Avatar', style: TextStyle(fontSize: 10, color: Colors.grey))
                              : null,
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Chọn ảnh mẫu có sẵn:', style: TextStyle(fontSize: 11, color: Colors.grey)),
                              const SizedBox(height: 6),
                              Row(
                                children: avatarPresets.map((url) {
                                  final isSelected = avatarCtrl.text == url;
                                  return GestureDetector(
                                    onTap: () {
                                      setModalState(() => avatarCtrl.text = url);
                                    },
                                    child: Container(
                                      margin: const EdgeInsets.only(right: 8),
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: isSelected ? AppTheme.primary : Colors.transparent,
                                          width: 2,
                                        ),
                                      ),
                                      child: CircleAvatar(
                                        radius: 16,
                                        backgroundImage: NetworkImage(url),
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
                        labelText: 'Hoặc dán liên kết URL ảnh đại diện',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                      onChanged: (_) => setModalState(() {}),
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
                        onPressed: () async {
                          if (nameCtrl.text.trim().isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Họ tên không được để trống')),
                            );
                            return;
                          }

                          await auth.updateProfile(
                            fullName: nameCtrl.text,
                            phone: phoneCtrl.text,
                            avatarUrl: avatarCtrl.text.isNotEmpty ? avatarCtrl.text : null,
                          );

                          if (context.mounted) {
                            Navigator.pop(ctx);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Cập nhật thông tin thành công!'),
                                backgroundColor: Colors.green,
                              ),
                            );
                          }
                        },
                        child: const Text('Lưu thông tin', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
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
                        child: CircleAvatar(
                          radius: 36,
                          backgroundColor: Colors.grey.shade100,
                          backgroundImage: (user?.avatarUrl != null && user!.avatarUrl!.isNotEmpty)
                              ? NetworkImage(user.avatarUrl!)
                              : null,
                          child: (user?.avatarUrl == null || user!.avatarUrl!.isEmpty)
                              ? Text(
                                  user?.fullName.isNotEmpty == true ? user!.fullName.substring(0, 1).toUpperCase() : 'M',
                                  style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: AppTheme.primary),
                                )
                              : null,
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
                                color: Colors.blue.shade50,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                user?.role == 'admin' ? 'Quản trị viên' : 'Thành viên Menly VIP',
                                style: TextStyle(fontSize: 10, color: Colors.blue.shade800, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 24),
                  // Nut doi thong tin & avatar
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.primary,
                        side: const BorderSide(color: AppTheme.primary),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
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
                  _buildStatItem(
                    label: 'Đơn hàng',
                    value: '${orderProv.allOrders.length}',
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MyOrdersPage())),
                  ),
                  Container(height: 28, width: 1, color: Colors.grey.shade200),
                  _buildStatItem(
                    label: 'Yêu thích',
                    value: '${wishlist.count}',
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const WishlistPage())),
                  ),
                  Container(height: 28, width: 1, color: Colors.grey.shade200),
                  _buildStatItem(
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
                  _buildMenuItem(
                    title: 'Đơn hàng của tôi',
                    subtitle: 'Theo dõi tiến trình giao hàng và lịch sử mua sắm',
                    badge: '${orderProv.allOrders.length}',
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MyOrdersPage())),
                  ),
                  const Divider(height: 1),
                  _buildMenuItem(
                    title: 'Tra cứu đơn hàng',
                    subtitle: 'Nhập mã đơn hoặc số điện thoại để xem tình trạng đơn hàng',
                    badge: 'Mới',
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const OrderTrackPage())),
                  ),
                  const Divider(height: 1),
                  _buildMenuItem(
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
                  _buildMenuItem(
                    title: 'Địa chỉ của tôi',
                    subtitle: 'Quản lý danh sách địa chỉ nhận hàng',
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AddressPage())),
                  ),
                  const Divider(height: 1),
                  _buildMenuItem(
                    title: 'Đổi mật khẩu',
                    subtitle: 'Cập nhật mật khẩu mới bảo mật tài khoản',
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ChangePasswordPage())),
                  ),
                  const Divider(height: 1),
                  _buildMenuItem(
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
                  _buildMenuItem(
                    title: 'Quản lý đơn hàng (Admin/Nhân viên)',
                    subtitle: 'Xem danh sách và cập nhật trạng thái giao hàng',
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const StaffOrderManagementPage())),
                  ),
                  const Divider(height: 1),
                  _buildMenuItem(
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
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem({required String label, required String value, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        child: Column(
          children: [
            Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 17, color: AppTheme.primary),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItem({
    required String title,
    required String subtitle,
    String? badge,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  const SizedBox(height: 2),
                  Text(subtitle, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                ],
              ),
            ),
            if (badge != null) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppTheme.primary,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(badge, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(width: 8),
            ],
            const Text('>', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 16)),
          ],
        ),
      ),
    );
  }
}
