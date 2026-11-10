import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/session/user_session.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_buttons.dart';
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
          DestructiveButton(
            label: 'Đăng xuất',
            expanded: false,
            height: 40,
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
    final c = AppColors.of(context);

    final allStaffOrders = orderProv.staffOrders;
    final pendingOrdersCount = allStaffOrders.where((o) {
      return o.status == OrderStatus.paid ||
          o.status == OrderStatus.processing ||
          o.status == OrderStatus.pendingPayment;
    }).length;

    return Scaffold(
      backgroundColor: c.background,
      appBar: AppBar(
        title: const Text('Cổng Nhân Viên Menly'),
        centerTitle: true,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            tooltip: 'Đăng xuất',
            icon: Icon(Icons.logout_rounded, color: c.danger),
            onPressed: () => _showLogoutDialog(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          children: [
            // Thẻ hồ sơ nhân viên
            Container(
              padding: const EdgeInsets.all(AppSpacing.xl),
              decoration: BoxDecoration(
                color: c.surface,
                borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                border: Border.all(color: c.border),
                boxShadow: [
                  BoxShadow(
                    color: c.shadow,
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
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    user?.fullName ?? 'Nhân viên Menly',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: c.textPrimary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    user?.email ?? '',
                    style: TextStyle(
                      fontSize: 13,
                      color: c.textSecondary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: c.primarySoft,
                      borderRadius: BorderRadius.circular(AppTheme.radiusXl),
                      border: Border.all(color: c.border),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.verified_user_rounded,
                            size: 15, color: c.primary),
                        const SizedBox(width: 6),
                        Text(
                          'NHÂN VIÊN CỬA HÀNG (STAFF)',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: c.primary,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            // Thống kê nhanh công việc
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () => onSwitchTab?.call(0),
                    borderRadius: BorderRadius.circular(AppTheme.radiusCard),
                    child: Container(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      decoration: BoxDecoration(
                        color: c.surface,
                        borderRadius: BorderRadius.circular(AppTheme.radiusCard),
                        border: Border.all(color: c.border),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(AppSpacing.sm),
                                decoration: BoxDecoration(
                                  color: c.surfaceVariant,
                                  borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                                ),
                                child: Icon(Icons.receipt_long_rounded,
                                    size: 20, color: c.primary),
                              ),
                              Text(
                                '$pendingOrdersCount',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: pendingOrdersCount > 0
                                      ? c.danger
                                      : c.textPrimary,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          Text(
                            'Đơn cần xử lý',
                            style: TextStyle(fontSize: 12, color: c.textMuted),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: InkWell(
                    onTap: () => onSwitchTab?.call(1),
                    borderRadius: BorderRadius.circular(AppTheme.radiusCard),
                    child: Container(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      decoration: BoxDecoration(
                        color: c.surface,
                        borderRadius: BorderRadius.circular(AppTheme.radiusCard),
                        border: Border.all(color: c.border),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(AppSpacing.sm),
                                decoration: BoxDecoration(
                                  color: c.surfaceVariant,
                                  borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                                ),
                                child: Icon(
                                    Icons.chat_bubble_outline_rounded,
                                    size: 20,
                                    color: c.primary),
                              ),
                              Icon(Icons.arrow_forward_ios_rounded,
                                  size: 14, color: c.textMuted),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          Text(
                            'Hội thoại CSKH',
                            style: TextStyle(fontSize: 12, color: c.textMuted),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),

            // Thông tin phân quyền & ca trực
            Container(
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                color: c.surface,
                borderRadius: BorderRadius.circular(AppTheme.radiusCard),
                border: Border.all(color: c.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Thông tin phiên làm việc',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: c.textPrimary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _buildInfoRow(
                    context: context,
                    icon: Icons.circle,
                    iconColor: c.success,
                    title: 'Trạng thái ca trực',
                    value: 'Đang trực tuyến',
                  ),
                  const Divider(height: AppSpacing.xl),
                  _buildInfoRow(
                    context: context,
                    icon: Icons.store_rounded,
                    title: 'Khu vực quản lý',
                    value: 'Menly Store - Toàn hệ thống',
                  ),
                  const Divider(height: AppSpacing.xl),
                  _buildInfoRow(
                    context: context,
                    icon: Icons.shield_outlined,
                    title: 'Quyền hạn tài khoản',
                    value: 'Quản lý đơn hàng & CSKH',
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            // Thẻ bảo mật & phân tách
            Container(
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                color: c.surfaceVariant,
                borderRadius: BorderRadius.circular(AppTheme.radiusCard),
                border: Border.all(color: c.border),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline_rounded,
                      color: c.textSecondary, size: 20),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      'Tài khoản nhân viên được bảo mật và phân quyền riêng biệt, tách biệt hoàn toàn với giỏ hàng và danh mục mua sắm của khách.',
                      style: TextStyle(
                        fontSize: 12,
                        color: c.textSecondary,
                        height: 1.35,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            // Các hành động
            Material(
              color: c.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusCard),
                side: BorderSide(color: c.border),
              ),
              child: Column(
                children: [
                  ListTile(
                    leading: Icon(Icons.lock_outline_rounded,
                        color: c.textPrimary),
                    title: Text('Đổi mật khẩu',
                        style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: c.textPrimary)),
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
                    leading: Icon(Icons.logout_rounded, color: c.danger),
                    title: Text('Đăng xuất tài khoản',
                        style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: c.danger)),
                    onTap: () => _showLogoutDialog(context),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xxl),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow({
    required BuildContext context,
    required IconData icon,
    Color? iconColor,
    required String title,
    required String value,
  }) {
    final c = AppColors.of(context);
    return Row(
      children: [
        Icon(icon, size: 16, color: iconColor ?? c.textSecondary),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Text(
            title,
            style: TextStyle(fontSize: 13, color: c.textMuted),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: c.textPrimary,
          ),
        ),
      ],
    );
  }
}
