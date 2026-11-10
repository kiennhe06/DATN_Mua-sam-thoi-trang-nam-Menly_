import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../features/auth/presentation/providers/auth_provider.dart';
import '../../features/order/presentation/pages/staff_order_management_page.dart';
import '../../features/staff/presentation/pages/staff_profile_page.dart';
import '../../features/support/presentation/pages/staff_support_inbox_page.dart';
import 'main_navigation_shell.dart';

/// Khung điều hướng tách biệt hoàn toàn dành riêng cho Nhân viên Menly (Staff Portal).
/// Nhân viên chỉ truy cập các tính năng nghiệp vụ (Đơn hàng, CSKH, Hồ sơ nhân viên),
/// không truy cập giao diện mua sắm, giỏ hàng hay sản phẩm của khách hàng.
class StaffNavigationShell extends StatefulWidget {
  const StaffNavigationShell({super.key});

  @override
  State<StaffNavigationShell> createState() => _StaffNavigationShellState();
}

class _StaffNavigationShellState extends State<StaffNavigationShell> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final auth = context.watch<AuthProvider>();

    // Bảo vệ nghiêm ngặt: nếu không phải staff/admin thì chuyển về MainNavigationShell
    if (!auth.isLoggedIn ||
        (auth.user?.role != 'staff' && auth.user?.role != 'admin')) {
      return const MainNavigationShell();
    }

    final pages = [
      const StaffOrderManagementPage(showBackButton: false),
      const StaffSupportInboxPage(showBackButton: false),
      StaffProfilePage(
        onSwitchTab: (idx) => setState(() => _currentIndex = idx),
      ),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: pages,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (idx) => setState(() => _currentIndex = idx),
        indicatorColor: c.primarySoft,
        backgroundColor: c.surface,
        elevation: 3,
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.receipt_long_outlined),
            selectedIcon: Icon(Icons.receipt_long, color: c.primary),
            label: 'Đơn hàng',
          ),
          NavigationDestination(
            icon: const Icon(Icons.chat_bubble_outline_rounded),
            selectedIcon: Icon(Icons.chat_bubble_rounded, color: c.primary),
            label: 'CSKH',
          ),
          NavigationDestination(
            icon: const Icon(Icons.badge_outlined),
            selectedIcon: Icon(Icons.badge, color: c.primary),
            label: 'Nhân viên',
          ),
        ],
      ),
    );
  }
}
