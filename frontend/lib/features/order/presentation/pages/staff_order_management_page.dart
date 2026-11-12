import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:menly_app/core/theme/app_colors.dart';
import 'package:menly_app/core/theme/app_spacing.dart';
import 'package:menly_app/core/theme/app_theme.dart';
import 'package:menly_app/core/utils/format.dart';
import 'package:menly_app/core/widgets/state_views.dart';
import 'package:menly_app/features/order/data/models/order_model.dart';
import 'package:menly_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:menly_app/features/auth/presentation/pages/login_page.dart';
import '../providers/order_provider.dart';
import 'order_detail_page.dart';
import 'order_invoice_page.dart';

/// Man quan ly don hang cho nhan vien tren app (AP-QT9)
class StaffOrderManagementPage extends StatefulWidget {
  final bool showBackButton;
  const StaffOrderManagementPage({super.key, this.showBackButton = true});

  @override
  State<StaffOrderManagementPage> createState() =>
      _StaffOrderManagementPageState();
}

class _StaffOrderManagementPageState extends State<StaffOrderManagementPage> {
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = context.read<AuthProvider>();
      final isStaffOrAdmin = auth.isLoggedIn &&
          (auth.user?.role == 'admin' || auth.user?.role == 'staff');
      if (isStaffOrAdmin) {
        context.read<OrderProvider>().loadStaffOrders();
      }
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }


  /// Mau nhan trang thai, gom bon nhom theo bang mau chung: cho (trung tinh),
  /// dang chay (ink), xong (success), that bai (danger). Khong dung c.secondary
  /// lam mau chu vi sac nhan be nhat gan trung voi nen the.
  Color _getStatusColor(OrderStatus status, AppColors c) {
    switch (status) {
      case OrderStatus.pendingPayment:
        return c.textSecondary;
      case OrderStatus.paid:
        return c.success;
      case OrderStatus.processing:
      case OrderStatus.shipping:
        return c.primary;
      case OrderStatus.delivered:
        return c.success;
      case OrderStatus.canceled:
      case OrderStatus.returned:
      case OrderStatus.expired:
        return c.danger;
      case OrderStatus.completed:
        return c.success;
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final auth = context.watch<AuthProvider>();
    final isStaffOrAdmin = auth.isLoggedIn &&
        (auth.user?.role == 'admin' || auth.user?.role == 'staff');

    if (!isStaffOrAdmin) {
      return Scaffold(
        backgroundColor: c.background,
        appBar: AppBar(
          title: const Text('Quản lý đơn hàng (Nhân viên)'),
          centerTitle: true,
        ),
        body: StatusView(
          icon: Icons.admin_panel_settings_outlined,
          title: !auth.isLoggedIn
              ? 'Yêu cầu đăng nhập tài khoản Quản trị'
              : 'Không có quyền truy cập',
          message: !auth.isLoggedIn
              ? 'Tính năng Quản lý đơn hàng nội bộ chỉ dành cho Quản trị viên và Nhân viên cửa hàng.\n\nVui lòng đăng nhập với tài khoản Quản trị để tiếp tục.'
              : 'Tài khoản hiện tại (${auth.user?.email}) là tài khoản Khách hàng, không thể quản lý đơn hàng.\n\nVui lòng đăng nhập với tài khoản Quản trị viên (admin@gmail.com / 123456).',
          actionLabel:
              !auth.isLoggedIn ? 'Đăng nhập ngay' : 'Đăng nhập tài khoản Quản trị',
          onAction: () async {
            await Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const LoginPage()),
            );
            if (!context.mounted) return;
            final updatedAuth = context.read<AuthProvider>();
            if (updatedAuth.isLoggedIn &&
                (updatedAuth.user?.role == 'admin' ||
                    updatedAuth.user?.role == 'staff')) {
              context.read<OrderProvider>().loadStaffOrders();
            }
          },
        ),
      );
    }

    final orderProv = context.watch<OrderProvider>();
    final stats = orderProv.staffStatistics;
    final orders = orderProv.staffOrders;

    return Scaffold(
      backgroundColor: c.background,
      appBar: AppBar(
        title: const Text('Quản lý đơn hàng'),
        centerTitle: true,
        automaticallyImplyLeading: widget.showBackButton,
      ),
      body: Column(
        children: [
          if (orderProv.errorMessage != null)
            MaterialBanner(
              backgroundColor: c.danger.withValues(alpha: 0.1),
              leading: Icon(Icons.info_outline, color: c.danger),
              content: Text(
                orderProv.errorMessage!,
                style: TextStyle(color: c.danger),
              ),
              actions: [
                if (orderProv.isUnauthorized)
                  TextButton(
                    onPressed: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const LoginPage()),
                      );
                      if (context.mounted) {
                        orderProv.loadStaffOrders();
                      }
                    },
                    child: const Text('Đăng nhập',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                  )
                else
                  TextButton(
                    onPressed: orderProv.loadStaffOrders,
                    child: const Text('Thử lại',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
              ],
            ),
          // Thong ke nhanh danh cho nhan vien
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            color: c.surfaceVariant,
            child: Row(
              children: [
                _buildStatTile(c, 'Tổng đơn', '${stats['totalOrders']}',
                    c.textPrimary),
                const SizedBox(width: AppSpacing.sm),
                _buildStatTile(
                    c, 'Chờ xử lý', '${stats['pendingCount']}', c.primary),
                const SizedBox(width: AppSpacing.sm),
                _buildStatTile(
                    c, 'Đang giao', '${stats['shippingCount']}', c.success),
              ],
            ),
          ),

          // Thanh tim kiem don theo ma / sdt / ten khach
          Padding(
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.md, AppSpacing.md, AppSpacing.md, AppSpacing.sm),
            child: TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                hintText: 'Tìm theo mã đơn, SĐT hoặc tên khách...',
                suffixIcon: _searchCtrl.text.isNotEmpty
                    ? IconButton(
                        icon: Text('✕',
                            style: TextStyle(
                                color: c.textMuted,
                                fontWeight: FontWeight.bold)),
                        onPressed: () {
                          _searchCtrl.clear();
                          orderProv.setStaffSearchQuery('');
                        },
                      )
                    : null,
                contentPadding:
                    const EdgeInsets.symmetric(vertical: AppSpacing.md),
                isDense: true,
              ),
              onChanged: (val) => orderProv.setStaffSearchQuery(val),
            ),
          ),

          // Chips loc trang thai
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md, vertical: AppSpacing.xs),
            child: Row(
              children: [
                _buildFilterChip(c, orderProv, 'all', 'Tất cả'),
                _buildFilterChip(
                    c, orderProv, 'processing', 'Chờ duyệt & Đóng gói'),
                _buildFilterChip(c, orderProv, 'shipping', 'Đang vận chuyển'),
                _buildFilterChip(c, orderProv, 'delivered', 'Hoàn thành'),
                _buildFilterChip(c, orderProv, 'canceled', 'Đã hủy'),
              ],
            ),
          ),
          const Divider(height: AppSpacing.md),

          // Danh sach don hang
          Expanded(
            child: orders.isEmpty
                ? const StatusView(
                    icon: Icons.receipt_long_outlined,
                    title: 'Không tìm thấy đơn hàng nào phù hợp',
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    itemCount: orders.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(height: AppSpacing.md),
                    itemBuilder: (ctx, i) {
                      final order = orders[i];
                      final statusColor = _getStatusColor(order.status, c);

                      return Container(
                        padding: const EdgeInsets.all(AppSpacing.lg),
                        decoration: BoxDecoration(
                          color: c.surface,
                          borderRadius:
                              BorderRadius.circular(AppTheme.radiusMd),
                          border: Border.all(color: c.border),
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
                            // Header don hang
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  order.code,
                                  style: TextStyle(
                                      color: c.textPrimary,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: AppSpacing.sm,
                                      vertical: AppSpacing.xs),
                                  decoration: BoxDecoration(
                                    color:
                                        statusColor.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(
                                        AppTheme.radiusXs),
                                  ),
                                  child: Text(
                                    order.nhanTrangThai,
                                    style: TextStyle(
                                      color: statusColor,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 11,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: AppSpacing.sm),

                            // Thong tin khach hang
                            Text(
                                'Khách hàng: ${order.shipName} • SĐT: ${order.shipPhone}',
                                style: TextStyle(
                                    color: c.textPrimary,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500)),
                            Text('Địa chỉ: ${order.shipAddress}',
                                style: TextStyle(
                                    fontSize: 12, color: c.textSecondary)),
                            const SizedBox(height: AppSpacing.sm),
                            Text(
                              'Tổng thu: ${formatPrice(order.total)} (${order.paymentMethod.toUpperCase()} • ${order.isPaid ? 'Đã thanh toán' : 'Thu tiền khi giao'})',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: order.isPaid ? c.success : c.primary,
                              ),
                            ),
                            const Divider(height: AppSpacing.lg),

                            // Nut thao tac cua nhan vien (AP-QT9)
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                TextButton(
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                          builder: (_) => OrderDetailPage(
                                              orderId: order.id)),
                                    );
                                  },
                                  child: const Text('Xem đơn',
                                      style: TextStyle(fontSize: 12)),
                                ),
                                TextButton(
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) =>
                                            OrderInvoicePage(order: order),
                                      ),
                                    );
                                  },
                                  child: const Text('Hóa đơn',
                                      style: TextStyle(fontSize: 12)),
                                ),
                                const SizedBox(width: AppSpacing.sm),

                                if (order.status == OrderStatus.paid)
                                  _buildStaffActionButton(
                                    label: 'Xử lý đơn',
                                    onPressed: () => _updateStatus(
                                      orderProv,
                                      order,
                                      OrderStatus.processing,
                                      'Đã xác nhận xử lý đơn ${order.code}',
                                    ),
                                  ),

                                // Neu dang cho xu ly -> Chuyen sang giao hang
                                if (order.status == OrderStatus.processing)
                                  _buildStaffActionButton(
                                    label: 'Giao hàng',
                                    onPressed: () => _updateStatus(
                                      orderProv,
                                      order,
                                      OrderStatus.shipping,
                                      'Đã chuyển đơn ${order.code} sang Đang giao',
                                    ),
                                  ),

                                // Neu dang giao hang -> Xac nhan hoan thanh
                                if (order.status == OrderStatus.shipping)
                                  _buildStaffActionButton(
                                    label: 'Đã giao xong',
                                    onPressed: () => _updateStatus(
                                      orderProv,
                                      order,
                                      OrderStatus.delivered,
                                      'Đơn ${order.code} đã hoàn thành!',
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  /// Doi trang thai don roi bao ket qua cho nhan vien.
  Future<void> _updateStatus(
    OrderProvider orderProv,
    OrderModel order,
    OrderStatus nextStatus,
    String successMessage,
  ) async {
    final updated =
        await orderProv.updateOrderStatusByStaff(order.id, nextStatus);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(updated
            ? successMessage
            : orderProv.errorMessage ?? 'Không cập nhật được đơn hàng'),
      ),
    );
  }

  /// Nut thao tac nho nam trong hang nut cua the don, dung mau nut chinh cua
  /// theme nen khong can to mau rieng.
  Widget _buildStaffActionButton({
    required String label,
    required VoidCallback onPressed,
  }) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        visualDensity: VisualDensity.compact,
      ),
      onPressed: onPressed,
      child: Text(label, style: const TextStyle(fontSize: 12)),
    );
  }

  /// Mot o thong ke trong hang tom tat dau man.
  Widget _buildStatTile(
      AppColors c, String label, String value, Color valueColor) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: c.surface,
          borderRadius: BorderRadius.circular(AppTheme.radiusSm),
          border: Border.all(color: c.border),
        ),
        child: Column(
          children: [
            Text(label, style: TextStyle(fontSize: 11, color: c.textMuted)),
            const SizedBox(height: AppSpacing.xs),
            Text(value,
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: valueColor)),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(
      AppColors c, OrderProvider prov, String key, String label) {
    final isSelected = prov.staffStatusFilter == key;
    return Padding(
      padding: const EdgeInsets.only(right: AppSpacing.sm),
      child: FilterChip(
        selected: isSelected,
        label: Text(label,
            style: TextStyle(
                fontSize: 12,
                color: isSelected ? c.onPrimary : c.textPrimary)),
        backgroundColor: c.surfaceVariant,
        selectedColor: c.primary,
        onSelected: (_) => prov.setStaffStatusFilter(key),
      ),
    );
  }
}
