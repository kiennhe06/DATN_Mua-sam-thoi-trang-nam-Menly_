import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/session/user_session.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../auth/presentation/pages/change_password_page.dart';
import '../../../auth/presentation/pages/login_page.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../auth/presentation/widgets/profile_avatar.dart';
import '../../../order/data/models/order_model.dart';
import '../../../order/presentation/providers/order_provider.dart';

class StaffProfilePage extends StatelessWidget {
  final Function(int)? onSwitchTab;
  const StaffProfilePage({super.key, this.onSwitchTab});

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Đăng xuất tài khoản'),
        content: const Text(
          'Bạn có chắc chắn muốn đăng xuất khỏi Cổng Nhân Viên Menly?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.accentRed,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              clearUserDataInMemory(context);
              await context.read<AuthProvider>().logout();
              if (!context.mounted) return;
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const LoginPage()),
                (route) => false,
              );
            },
            child: const Text('Đăng xuất'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final orderProv = context.watch<OrderProvider>();
    final user = auth.user;

    final allStaffOrders = orderProv.staffOrders;
    final pendingOrdersCount = allStaffOrders.where((o) {
      return o.status == OrderStatus.paid ||
          o.status == OrderStatus.processing ||
          o.status == OrderStatus.pendingPayment;
    }).length;

    return Scaffold(
      backgroundColor: AppTheme.scaffoldBackground,
      appBar: AppBar(
        title: const Text('Cổng Nhân Viên Menly'),
        centerTitle: true,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            tooltip: 'Đăng xuất',
            icon: const Icon(Icons.logout_rounded, color: AppTheme.accentRed),
            onPressed: () => _showLogoutDialog(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Thẻ hồ sơ nhân viên
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  ProfileAvatar(
                    avatarUrl: user?.avatarUrl,
                    radius: 36,
                    fallbackText: user?.fullName ?? 'NV',
                  ),
                  const SizedBox(height: 12),
                  Text(
                    user?.fullName ?? 'Nhân viên Menly',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    user?.email ?? '',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF), // Blue 50
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFFBFDBFE)),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.verified_user_rounded,
                            size: 15, color: Color(0xFF1D4ED8)),
                        SizedBox(width: 6),
                        Text(
                          'NHÂN VIÊN CỬA HÀNG (STAFF)',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1D4ED8),
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Thống kê nhanh công việc
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () => onSwitchTab?.call(0),
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.amber.shade50,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(Icons.receipt_long_rounded,
                                    size: 20, color: Colors.amber.shade800),
                              ),
                              Text(
                                '$pendingOrdersCount',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: pendingOrdersCount > 0
                                      ? AppTheme.accentRed
                                      : AppTheme.textPrimary,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          const Text(
                            'Đơn cần xử lý',
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: InkWell(
                    onTap: () => onSwitchTab?.call(1),
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.blue.shade50,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(
                                    Icons.chat_bubble_outline_rounded,
                                    size: 20,
                                    color: Color(0xFF2563EB)),
                              ),
                              const Icon(Icons.arrow_forward_ios_rounded,
                                  size: 14, color: Colors.grey),
                            ],
                          ),
                          const SizedBox(height: 10),
                          const Text(
                            'Hội thoại CSKH',
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Thông tin phân quyền & ca trực
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Thông tin phiên làm việc',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  _buildInfoRow(
                    icon: Icons.circle,
                    iconColor: Colors.green,
                    title: 'Trạng thái ca trực',
                    value: 'Đang trực tuyến',
                  ),
                  const Divider(height: 20),
                  _buildInfoRow(
                    icon: Icons.store_rounded,
                    title: 'Khu vực quản lý',
                    value: 'Menly Store - Toàn hệ thống',
                  ),
                  const Divider(height: 20),
                  _buildInfoRow(
                    icon: Icons.shield_outlined,
                    title: 'Quyền hạn tài khoản',
                    value: 'Quản lý đơn hàng & CSKH',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Thẻ bảo mật & phân tách
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline_rounded,
                      color: Color(0xFF64748B), size: 20),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Tài khoản nhân viên được bảo mật và phân quyền riêng biệt, tách biệt hoàn toàn với giỏ hàng và danh mục mua sắm của khách.',
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFF475569),
                        height: 1.35,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Các hành động
            Material(
              color: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
                side: BorderSide(color: Colors.grey.shade200),
              ),
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.lock_outline_rounded,
                        color: AppTheme.textPrimary),
                    title: const Text('Đổi mật khẩu',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const ChangePasswordPage()),
                      );
                    },
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.logout_rounded,
                        color: AppTheme.accentRed),
                    title: const Text('Đăng xuất tài khoản',
                        style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.accentRed)),
                    onTap: () => _showLogoutDialog(context),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    Color? iconColor,
    required String title,
    required String value,
  }) {
    return Row(
      children: [
        Icon(icon, size: 16, color: iconColor ?? Colors.grey.shade700),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(fontSize: 13, color: Colors.grey),
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimary,
          ),
        ),
      ],
    );
  }
}
