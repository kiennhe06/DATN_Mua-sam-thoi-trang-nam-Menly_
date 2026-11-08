import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:menly_app/core/utils/format.dart';
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

  Color _getStatusColor(OrderStatus status) {
    switch (status) {
      case OrderStatus.pendingPayment:
        return Colors.orange;
      case OrderStatus.paid:
        return Colors.teal;
      case OrderStatus.processing:
        return Colors.blue;
      case OrderStatus.shipping:
        return Colors.purple;
      case OrderStatus.delivered:
        return Colors.green;
      case OrderStatus.canceled:
      case OrderStatus.returned:
      case OrderStatus.expired:
        return Colors.red;
      case OrderStatus.completed:
        return Colors.green;
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final isStaffOrAdmin = auth.isLoggedIn &&
        (auth.user?.role == 'admin' || auth.user?.role == 'staff');

    if (!isStaffOrAdmin) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Quản lý đơn hàng (Nhân viên)'),
          centerTitle: true,
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade50,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.admin_panel_settings_outlined,
                    size: 64,
                    color: Colors.amber.shade800,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  !auth.isLoggedIn
                      ? 'Yêu cầu đăng nhập tài khoản Quản trị'
                      : 'Không có quyền truy cập',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  !auth.isLoggedIn
                      ? 'Tính năng Quản lý đơn hàng nội bộ chỉ dành cho Quản trị viên và Nhân viên cửa hàng.\n\nVui lòng đăng nhập với tài khoản Quản trị để tiếp tục.'
                      : 'Tài khoản hiện tại (${auth.user?.email}) là tài khoản Khách hàng, không thể quản lý đơn hàng.\n\nVui lòng đăng nhập với tài khoản Quản trị viên (admin@gmail.com / 123456).',
                  style: TextStyle(fontSize: 14, color: Colors.grey.shade700, height: 1.4),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 28),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black87,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    icon: const Icon(Icons.login),
                    label: Text(!auth.isLoggedIn ? 'Đăng nhập ngay' : 'Đăng nhập tài khoản Quản trị'),
                    onPressed: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const LoginPage()),
                      );
                      if (!context.mounted) return;
                      final updatedAuth = context.read<AuthProvider>();
                      if (updatedAuth.isLoggedIn &&
                          (updatedAuth.user?.role == 'admin' || updatedAuth.user?.role == 'staff')) {
                        context.read<OrderProvider>().loadStaffOrders();
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final orderProv = context.watch<OrderProvider>();
    final stats = orderProv.staffStatistics;
    final orders = orderProv.staffOrders;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Quản lý đơn hàng'),
        centerTitle: true,
        automaticallyImplyLeading: widget.showBackButton,
      ),
      body: Column(
        children: [
          if (orderProv.errorMessage != null)
            MaterialBanner(
              backgroundColor: Colors.red.shade50,
              leading: const Icon(Icons.info_outline, color: Colors.red),
              content: Text(
                orderProv.errorMessage!,
                style: const TextStyle(color: Colors.red),
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
                    child: const Text('Đăng nhập', style: TextStyle(fontWeight: FontWeight.bold)),
                  )
                else
                  TextButton(
                    onPressed: orderProv.loadStaffOrders,
                    child: const Text('Thử lại', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
              ],
            ),
          // Thong ke nhanh danh cho nhan vien
          Container(
            padding: const EdgeInsets.all(12),
            color: Colors.grey.shade100,
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Column(
                      children: [
                        const Text('Tổng đơn',
                            style: TextStyle(fontSize: 11, color: Colors.grey)),
                        const SizedBox(height: 2),
                        Text('${stats['totalOrders']}',
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 16)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Column(
                      children: [
                        const Text('Chờ xử lý',
                            style: TextStyle(fontSize: 11, color: Colors.blue)),
                        const SizedBox(height: 2),
                        Text('${stats['pendingCount']}',
                            style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: Colors.blue)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Column(
                      children: [
                        const Text('Đang giao',
                            style:
                                TextStyle(fontSize: 11, color: Colors.purple)),
                        const SizedBox(height: 2),
                        Text('${stats['shippingCount']}',
                            style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: Colors.purple)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Thanh tim kiem don theo ma / sdt / ten khach
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
            child: TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                hintText: 'Tìm theo mã đơn, SĐT hoặc tên khách...',
                suffixIcon: _searchCtrl.text.isNotEmpty
                    ? IconButton(
                        icon: const Text('✕',
                            style: TextStyle(
                                color: Colors.grey,
                                fontWeight: FontWeight.bold)),
                        onPressed: () {
                          _searchCtrl.clear();
                          orderProv.setStaffSearchQuery('');
                        },
                      )
                    : null,
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
                isDense: true,
              ),
              onChanged: (val) => orderProv.setStaffSearchQuery(val),
            ),
          ),

          // Chips loc trang thai
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: Row(
              children: [
                _buildFilterChip(orderProv, 'all', 'Tất cả'),
                _buildFilterChip(
                    orderProv, 'processing', 'Chờ duyệt & Đóng gói'),
                _buildFilterChip(orderProv, 'shipping', 'Đang vận chuyển'),
                _buildFilterChip(orderProv, 'delivered', 'Hoàn thành'),
                _buildFilterChip(orderProv, 'canceled', 'Đã hủy'),
              ],
            ),
          ),
          const Divider(height: 12),

          // Danh sach don hang
          Expanded(
            child: orders.isEmpty
                ? const Center(
                    child: Text('Không tìm thấy đơn hàng nào phù hợp'))
                : ListView.separated(
                    padding: const EdgeInsets.all(12),
                    itemCount: orders.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (ctx, i) {
                      final order = orders[i];

                      return Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade200),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.04),
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
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: _getStatusColor(order.status)
                                        .withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    order.status.label,
                                    style: TextStyle(
                                      color: _getStatusColor(order.status),
                                      fontWeight: FontWeight.bold,
                                      fontSize: 11,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),

                            // Thong tin khach hang
                            Text(
                                'Khách hàng: ${order.shipName} • SĐT: ${order.shipPhone}',
                                style: const TextStyle(
                                    fontSize: 13, fontWeight: FontWeight.w500)),
                            Text('Địa chỉ: ${order.shipAddress}',
                                style: TextStyle(
                                    fontSize: 12, color: Colors.grey.shade700)),
                            const SizedBox(height: 6),
                            Text(
                              'Tổng thu: ${formatPrice(order.total)} (${order.paymentMethod.toUpperCase()} • ${order.isPaid ? 'Đã thanh toán' : 'Thu tiền khi giao'})',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: order.isPaid
                                    ? Colors.green
                                    : Colors.deepOrange,
                              ),
                            ),
                            const Divider(height: 16),

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
                                const SizedBox(width: 8),

                                if (order.status == OrderStatus.paid)
                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.teal,
                                      foregroundColor: Colors.white,
                                      visualDensity: VisualDensity.compact,
                                    ),
                                    onPressed: () async {
                                      final updated = await orderProv
                                          .updateOrderStatusByStaff(
                                              order.id, OrderStatus.processing);
                                      if (!context.mounted) return;
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        SnackBar(
                                            content: Text(updated
                                                ? 'Đã xác nhận xử lý đơn ${order.code}'
                                                : orderProv.errorMessage ??
                                                    'Không cập nhật được đơn hàng')),
                                      );
                                    },
                                    child: const Text('Xử lý đơn',
                                        style: TextStyle(fontSize: 12)),
                                  ),

                                // Neu dang cho xu ly -> Chuyen sang giao hang
                                if (order.status == OrderStatus.processing)
                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.blue.shade700,
                                      foregroundColor: Colors.white,
                                      visualDensity: VisualDensity.compact,
                                    ),
                                    child: const Text('Giao hàng',
                                        style: TextStyle(fontSize: 12)),
                                    onPressed: () async {
                                      final updated = await orderProv
                                          .updateOrderStatusByStaff(
                                              order.id, OrderStatus.shipping);
                                      if (!context.mounted) return;
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        SnackBar(
                                            content: Text(updated
                                                ? 'Đã chuyển đơn ${order.code} sang Đang giao'
                                                : orderProv.errorMessage ??
                                                    'Không cập nhật được đơn hàng')),
                                      );
                                    },
                                  ),

                                // Neu dang giao hang -> Xac nhan hoan thanh
                                if (order.status == OrderStatus.shipping)
                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.green,
                                      foregroundColor: Colors.white,
                                      visualDensity: VisualDensity.compact,
                                    ),
                                    child: const Text('Đã giao xong',
                                        style: TextStyle(fontSize: 12)),
                                    onPressed: () async {
                                      final updated = await orderProv
                                          .updateOrderStatusByStaff(
                                              order.id, OrderStatus.delivered);
                                      if (!context.mounted) return;
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        SnackBar(
                                            content: Text(updated
                                                ? 'Đơn ${order.code} đã hoàn thành!'
                                                : orderProv.errorMessage ??
                                                    'Không cập nhật được đơn hàng')),
                                      );
                                    },
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

  Widget _buildFilterChip(OrderProvider prov, String key, String label) {
    final isSelected = prov.staffStatusFilter == key;
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: FilterChip(
        selected: isSelected,
        label: Text(label,
            style: TextStyle(
                fontSize: 12,
                color: isSelected ? Colors.white : Colors.black87)),
        backgroundColor: Colors.grey.shade100,
        selectedColor: Colors.black87,
        onSelected: (_) => prov.setStaffStatusFilter(key),
      ),
    );
  }
}
