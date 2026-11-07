import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../voucher/data/models/voucher_model.dart';
import '../../../voucher/presentation/pages/voucher_list_page.dart';
import '../../../voucher/presentation/providers/voucher_provider.dart';
import '../providers/notification_provider.dart';

String _formatDate(DateTime dt) {
  final d = dt.day.toString().padLeft(2, '0');
  final m = dt.month.toString().padLeft(2, '0');
  final y = dt.year;
  final h = dt.hour.toString().padLeft(2, '0');
  final min = dt.minute.toString().padLeft(2, '0');
  return '$d/$m/$y $h:$min';
}

/// Màn hình danh sách thông báo của Menly
class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<NotificationProvider>().loadNotifications();
    });
  }

  @override
  Widget build(BuildContext context) {
    final notifProv = context.watch<NotificationProvider>();
    final voucherProv = context.watch<VoucherProvider>();
    final items = notifProv.notifications;
    final vouchers = voucherProv.vouchers;

    return Scaffold(
      backgroundColor: AppTheme.scaffoldBackground,
      appBar: AppBar(
        title: Text(
          notifProv.unreadCount > 0
              ? 'Thông báo (${notifProv.unreadCountLabel})'
              : 'Thông báo',
        ),
        centerTitle: true,
        actions: [
          if (items.isNotEmpty && notifProv.unreadCount > 0)
            TextButton(
              onPressed: () => notifProv.markAllRead(),
              child: const Text(
                'Đã đọc tất cả',
                style: TextStyle(
                  color: AppTheme.accentOrange,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await Future.wait([
            notifProv.loadNotifications(),
            voucherProv.loadVouchers(),
          ]);
        },
        child: notifProv.isLoading && items.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  if (vouchers.isNotEmpty) ...[
                    Container(
                      margin: const EdgeInsets.only(bottom: 18),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFFF8A3D), Color(0xFFFFB15C)],
                        ),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.local_offer_rounded,
                            color: Colors.white,
                            size: 30,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Ưu đãi dành riêng cho bạn',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  '${vouchers.length} voucher đang chờ bạn sử dụng',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      'Ưu đãi và voucher',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: AppTheme.textPrimary,
                          ),
                    ),
                    const SizedBox(height: 12),
                    ...vouchers.map((voucher) => _VoucherOfferCard(voucher: voucher)),
                    const SizedBox(height: 8),
                  ],
                  if (items.isEmpty)
                    if (vouchers.isEmpty)
                      const _EmptyNotifications()
                    else
                      const Text(
                        'Bạn chưa có thông báo đơn hàng nào.',
                        style: TextStyle(color: AppTheme.textSecondary),
                      )
                  else ...[
                    Text(
                      'Thông báo của bạn',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: AppTheme.textPrimary,
                          ),
                    ),
                    const SizedBox(height: 12),
                    ...items.map(
                      (item) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Dismissible(
                          key: ValueKey(item.id),
                          direction: DismissDirection.endToStart,
                          background: Container(
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.only(right: 20),
                            decoration: BoxDecoration(
                              color: AppTheme.accentRed,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.delete_outline, color: Colors.white),
                          ),
                          onDismissed: (_) => notifProv.deleteNotification(item.id),
                          child: InkWell(
                            onTap: () => notifProv.markRead(item.id),
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: item.isRead
                                    ? Colors.white
                                    : Colors.blue.shade50.withValues(alpha: 0.4),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: item.isRead ? AppTheme.border : Colors.blue.shade200,
                                ),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: item.isRead ? Colors.grey.shade100 : Colors.blue.shade100,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      item.type == 'order'
                                          ? Icons.local_shipping_outlined
                                          : item.type == 'voucher'
                                              ? Icons.discount_outlined
                                              : Icons.notifications_none_rounded,
                                      size: 18,
                                      color: item.isRead ? Colors.grey.shade700 : Colors.blue.shade800,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          item.title,
                                          style: TextStyle(
                                            fontWeight: item.isRead ? FontWeight.w600 : FontWeight.bold,
                                            fontSize: 14,
                                            color: AppTheme.textPrimary,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          item.body,
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey.shade700,
                                            height: 1.3,
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          _formatDate(item.createdAt),
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: Colors.grey.shade500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (!item.isRead)
                                    Container(
                                      width: 8,
                                      height: 8,
                                      margin: const EdgeInsets.only(top: 4, left: 4),
                                      decoration: const BoxDecoration(
                                        color: Colors.blue,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
      ),
    );
  }
}

class _VoucherOfferCard extends StatelessWidget {
  final VoucherModel voucher;

  const _VoucherOfferCard({required this.voucher});

  @override
  Widget build(BuildContext context) {
    final isPercentage = voucher.discountType == 'percentage';
    final discount = isPercentage
        ? 'Giảm ${voucher.discountValue}%'
        : 'Giảm ${_formatCurrency(voucher.discountValue)}đ';

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      color: Colors.white,
      child: ListTile(
        leading: const CircleAvatar(
          backgroundColor: Color(0xFFFFF1E9),
          child: Icon(Icons.local_offer_rounded, color: AppTheme.accentOrange),
        ),
        title: Text(voucher.title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Text(
            '$discount • Mã ${voucher.code}\n'
            'Đơn tối thiểu ${_formatCurrency(voucher.minOrderValue)}đ • '
            'Hạn dùng ${_formatDate(voucher.endDate)}',
          ),
        ),
        isThreeLine: true,
        trailing: const Icon(Icons.chevron_right_rounded),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const VoucherListPage()),
        ),
      ),
    );
  }
}

class _EmptyNotifications extends StatelessWidget {
  const _EmptyNotifications();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 64),
      child: Column(
        children: [
          Icon(Icons.notifications_none_rounded, size: 52, color: Colors.grey.shade500),
          const SizedBox(height: 18),
          const Text(
            'Chưa có thông báo mới',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Các cập nhật trạng thái đơn hàng của bạn sẽ xuất hiện tại đây.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: Colors.grey.shade600, height: 1.4),
          ),
        ],
      ),
    );
  }
}

String _formatCurrency(int value) => value.toString().replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (match) => ',',
    );
