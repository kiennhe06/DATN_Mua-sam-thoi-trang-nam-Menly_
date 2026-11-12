import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_buttons.dart';
import '../../../../core/widgets/state_views.dart';
import '../../../voucher/data/models/voucher_model.dart';
import '../../../voucher/presentation/pages/voucher_list_page.dart';
import '../../../voucher/presentation/providers/voucher_provider.dart';
import '../providers/notification_provider.dart';
import '../widgets/notification_filter_bar.dart';
import '../widgets/notification_item_card.dart';

/// Màn hình danh sách và lọc thông báo của Menly (AP-TB1)
/// Hỗ trợ lọc theo loại: Tất cả, Đơn hàng, Khuyến mãi, Hệ thống, Chưa đọc
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
    final c = AppColors.of(context);
    final notifProv = context.watch<NotificationProvider>();
    final voucherProv = context.watch<VoucherProvider>();
    final filteredItems = notifProv.filteredNotifications;
    final vouchers = voucherProv.vouchers;
    final currentFilter = notifProv.selectedFilter;

    final showVoucherBanner = (currentFilter == NotificationProvider.filterAll ||
            currentFilter == NotificationProvider.filterPromo) &&
        vouchers.isNotEmpty;

    return Scaffold(
      backgroundColor: c.background,
      appBar: AppBar(
        title: Text(
          notifProv.unreadCount > 0
              ? 'Thông báo (${notifProv.unreadCountLabel})'
              : 'Thông báo',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          if (notifProv.unreadCount > 0)
            TextButton(
              onPressed: () => notifProv.markAllRead(),
              child: Text(
                'Đã đọc tất cả',
                style: TextStyle(
                  color: c.primary,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert_rounded),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            ),
            onSelected: (val) {
              if (val == 'mark_all_read') {
                notifProv.markAllRead();
              } else if (val == 'clear_read') {
                notifProv.clearReadNotifications();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Đã dọn dẹp các thông báo đã đọc')),
                );
              } else if (val == 'refresh') {
                notifProv.loadNotifications();
                voucherProv.loadVouchers();
              }
            },
            itemBuilder: (_) => [
              const PopupMenuItem(
                value: 'mark_all_read',
                child: Row(
                  children: [
                    Icon(Icons.done_all_rounded, size: 18),
                    SizedBox(width: AppSpacing.sm),
                    Text('Đánh dấu tất cả đã đọc'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'clear_read',
                child: Row(
                  children: [
                    Icon(Icons.cleaning_services_outlined, size: 18),
                    SizedBox(width: AppSpacing.sm),
                    Text('Xóa thông báo đã đọc'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'refresh',
                child: Row(
                  children: [
                    Icon(Icons.refresh_rounded, size: 18),
                    SizedBox(width: AppSpacing.sm),
                    Text('Làm mới danh sách'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Thanh lọc thông báo theo danh mục
          NotificationFilterBar(
            selectedFilter: currentFilter,
            onFilterSelected: (f) => notifProv.setFilter(f),
            provider: notifProv,
          ),

          // Nội dung danh sách thông báo
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                await Future.wait([
                  notifProv.loadNotifications(),
                  voucherProv.loadVouchers(),
                ]);
              },
              child: notifProv.isLoading && notifProv.notifications.isEmpty
                  ? const LoadingView()
                  : ListView(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.lg,
                        vertical: AppSpacing.sm,
                      ),
                      children: [
                        // Banner Ưu đãi voucher (khi xem Tất cả hoặc Khuyến mãi)
                        if (showVoucherBanner) ...[
                          _VoucherPromoBanner(vouchers: vouchers),
                          const SizedBox(height: AppSpacing.lg),
                        ],

                        // Danh sách thông báo
                        if (filteredItems.isEmpty)
                          _EmptyFilteredView(filter: currentFilter)
                        else ...[
                          Row(
                            children: [
                              Text(
                                _getFilterSectionTitle(currentFilter),
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                  color: c.textPrimary,
                                ),
                              ),
                              const SizedBox(width: AppSpacing.sm),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: AppSpacing.sm,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: c.surfaceVariant,
                                  borderRadius: BorderRadius.circular(
                                    AppTheme.radiusSm,
                                  ),
                                ),
                                child: Text(
                                  '${filteredItems.length}',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: c.textSecondary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.md),
                          ...filteredItems.map(
                            (item) => NotificationItemCard(
                              item: item,
                              onTap: () => notifProv.markRead(item.id),
                              onDismiss: () {
                                notifProv.deleteNotification(item.id);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: const Text('Đã xóa thông báo'),
                                    duration: const Duration(seconds: 2),
                                    action: SnackBarAction(
                                      label: 'Hoàn tác',
                                      onPressed: () {
                                        notifProv.addNotification(
                                          title: item.title,
                                          body: item.body,
                                          type: item.type,
                                          data: item.data,
                                        );
                                      },
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                        const SizedBox(height: AppSpacing.xxl),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }

  String _getFilterSectionTitle(String filter) {
    switch (filter) {
      case NotificationProvider.filterOrder:
        return 'Thông báo đơn hàng';
      case NotificationProvider.filterPromo:
        return 'Khuyến mãi & Ưu đãi';
      case NotificationProvider.filterSystem:
        return 'Thông báo hệ thống';
      case NotificationProvider.filterUnread:
        return 'Thông báo chưa đọc';
      case NotificationProvider.filterAll:
      default:
        return 'Tất cả thông báo';
    }
  }
}

/// Banner khuyến mãi voucher dành riêng cho khách hàng
class _VoucherPromoBanner extends StatelessWidget {
  final List<VoucherModel> vouchers;

  const _VoucherPromoBanner({required this.vouchers});

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: c.inkCard,
        borderRadius: BorderRadius.circular(AppTheme.radiusXl),
      ),
      // Nut nam o dong rieng ben duoi chu khong chen cung hang voi chu: de
      // cung hang thi hai dong chu deu bi bop xuong hai dong.
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: c.onInk.withValues(alpha: 0.14),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.local_offer_rounded,
                  color: c.onInk,
                  size: 26,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Ưu đãi dành riêng cho bạn',
                      style: TextStyle(
                        color: c.onInk,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      '${vouchers.length} voucher đang sẵn sàng áp dụng',
                      style: TextStyle(
                        color: c.onInk.withValues(alpha: 0.75),
                        fontSize: 12.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          PrimaryButton(
            label: 'Xem ngay',
            expanded: false,
            height: 40,
            background: c.onInk,
            foreground: c.inkCard,
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const VoucherListPage()),
            ),
          ),
        ],
      ),
    );
  }
}

/// Trạng thái trống tương ứng với từng bộ lọc
class _EmptyFilteredView extends StatelessWidget {
  final String filter;

  const _EmptyFilteredView({required this.filter});

  @override
  Widget build(BuildContext context) {
    IconData icon;
    String title;
    String subtitle;

    switch (filter) {
      case NotificationProvider.filterOrder:
        icon = Icons.local_shipping_outlined;
        title = 'Chưa có thông báo đơn hàng';
        subtitle = 'Thông tin cập nhật đơn hàng sẽ xuất hiện khi bạn đặt mua sản phẩm.';
        break;
      case NotificationProvider.filterPromo:
        icon = Icons.local_offer_outlined;
        title = 'Chưa có khuyến mãi mới';
        subtitle = 'Các chương trình ưu đãi và voucher hấp dẫn sẽ sớm được gửi đến bạn!';
        break;
      case NotificationProvider.filterSystem:
        icon = Icons.notifications_none_rounded;
        title = 'Chưa có thông báo hệ thống';
        subtitle = 'Thông tin cập nhật tính năng mới và bảo trì sẽ hiển thị tại đây.';
        break;
      case NotificationProvider.filterUnread:
        icon = Icons.mark_email_read_outlined;
        title = 'Tuyệt vời!';
        subtitle = 'Bạn đã đọc toàn bộ các thông báo. Không có thông báo mới nào chưa đọc.';
        break;
      case NotificationProvider.filterAll:
      default:
        icon = Icons.notifications_none_rounded;
        title = 'Chưa có thông báo';
        subtitle = 'Tất cả các thông báo của bạn sẽ được lưu giữ tại đây.';
        break;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxxl),
      child: StatusView(icon: icon, title: title, message: subtitle),
    );
  }
}
