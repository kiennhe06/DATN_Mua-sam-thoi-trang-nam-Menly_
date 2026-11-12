import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_theme.dart';
import '../providers/notification_provider.dart';
import 'notification_detail_sheet.dart';

/// Mau, bieu tuong va ten goi theo tung loai thong bao.
///
/// The thong bao, sheet chi tiet va thanh loc deu doc bang nay nen mot loai
/// luon hien cung mot mau o ca ba cho. Mau lay tu token theo context.
class NotificationTypeStyle {
  final Color color;
  final IconData icon;

  /// Nhan ngan dung tren the va thanh loc.
  final String tag;

  /// Ten day du dung tren sheet chi tiet.
  final String fullName;

  const NotificationTypeStyle({
    required this.color,
    required this.icon,
    required this.tag,
    required this.fullName,
  });

  /// Tra ve kieu hien thi ung voi [type] cua thong bao.
  static NotificationTypeStyle of(AppColors c, String type) {
    switch (type) {
      case 'order':
        return NotificationTypeStyle(
          color: c.primary,
          icon: Icons.local_shipping_rounded,
          tag: 'Đơn hàng',
          fullName: 'Đơn hàng',
        );
      case 'promo':
      case 'voucher':
        return NotificationTypeStyle(
          color: c.secondary,
          icon: Icons.local_offer_rounded,
          tag: 'Khuyến mãi',
          fullName: 'Khuyến mãi & Ưu đãi',
        );
      default:
        return NotificationTypeStyle(
          color: c.success,
          icon: Icons.notifications_active_rounded,
          tag: 'Hệ thống',
          fullName: 'Hệ thống',
        );
    }
  }
}

class NotificationItemCard extends StatelessWidget {
  final NotificationModel item;
  final VoidCallback onTap;
  final VoidCallback onDismiss;

  const NotificationItemCard({
    super.key,
    required this.item,
    required this.onTap,
    required this.onDismiss,
  });

  String _formatRelativeTime(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);

    if (diff.inSeconds < 60) {
      return 'Vừa xong';
    } else if (diff.inMinutes < 60) {
      return '${diff.inMinutes} phút trước';
    } else if (diff.inHours < 24 && dt.day == now.day) {
      final h = dt.hour.toString().padLeft(2, '0');
      final m = dt.minute.toString().padLeft(2, '0');
      return 'Hôm nay $h:$m';
    } else if (diff.inDays < 7) {
      return '${diff.inDays} ngày trước';
    } else {
      final d = dt.day.toString().padLeft(2, '0');
      final m = dt.month.toString().padLeft(2, '0');
      final y = dt.year;
      return '$d/$m/$y';
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final style = NotificationTypeStyle.of(c, item.type);
    // Thong bao da doc lui ve mau trung tinh, chua doc giu mau cua loai.
    final accent = item.isRead ? c.textSecondary : style.color;
    final radius = BorderRadius.circular(AppTheme.radiusCard);

    return Dismissible(
      key: ValueKey(item.id),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.md),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: AppSpacing.xl),
        decoration: BoxDecoration(
          color: c.danger,
          borderRadius: radius,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Icon(Icons.delete_outline, color: c.onInk, size: 22),
            const SizedBox(width: AppSpacing.xs),
            Text(
              'Xóa',
              style: TextStyle(color: c.onInk, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
      onDismissed: (_) => onDismiss(),
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.md),
        decoration: BoxDecoration(
          // Ca hai trang thai deu la the trang. To nen xam cho muc chua doc
          // lam ca danh sach xam xit tren nen trang; phan biet bang vien dam
          // hon, chu dam hon va cham cuoi dong la du.
          color: c.surface,
          borderRadius: radius,
          border: Border.all(
            color: item.isRead ? c.border : c.primary,
            width: item.isRead ? 1 : 1.4,
          ),
          boxShadow: [
            BoxShadow(
              color: c.shadow,
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: radius,
            onTap: () {
              onTap();
              NotificationDetailSheet.show(context, item);
            },
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Icon Avatar
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(style.icon, size: 20, color: accent),
                  ),
                  const SizedBox(width: AppSpacing.md),

                  // Content
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            // Tag
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.sm,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: accent.withValues(alpha: 0.1),
                                borderRadius:
                                    BorderRadius.circular(AppTheme.radiusXs),
                              ),
                              child: Text(
                                style.tag,
                                style: TextStyle(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w700,
                                  color: accent,
                                ),
                              ),
                            ),
                            const Spacer(),
                            // Time
                            Text(
                              _formatRelativeTime(item.createdAt),
                              style: TextStyle(
                                fontSize: 11,
                                color: c.textMuted,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.xs),

                        // Title
                        Text(
                          item.title,
                          style: TextStyle(
                            fontWeight:
                                item.isRead ? FontWeight.w600 : FontWeight.bold,
                            fontSize: 14,
                            color:
                                item.isRead ? c.textSecondary : c.textPrimary,
                            height: 1.25,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xs),

                        // Body
                        Text(
                          item.body,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12.5,
                            color: c.textSecondary,
                            height: 1.35,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Unread indicator dot
                  if (!item.isRead) ...[
                    const SizedBox(width: AppSpacing.sm),
                    Container(
                      width: 8,
                      height: 8,
                      margin: const EdgeInsets.only(top: AppSpacing.xs),
                      decoration: BoxDecoration(
                        color: c.primary,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
