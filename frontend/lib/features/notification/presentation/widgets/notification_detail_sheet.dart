import 'package:flutter/material.dart';
import 'package:menly_app/features/order/presentation/pages/my_orders_page.dart';
import 'package:menly_app/features/voucher/presentation/pages/voucher_list_page.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_buttons.dart';
import '../providers/notification_provider.dart';
import 'notification_item_card.dart';

class NotificationDetailSheet extends StatelessWidget {
  final NotificationModel notification;

  const NotificationDetailSheet({super.key, required this.notification});

  static Future<void> show(BuildContext context, NotificationModel notification) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => NotificationDetailSheet(notification: notification),
    );
  }

  String _formatDateTime(DateTime dt) {
    final d = dt.day.toString().padLeft(2, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final y = dt.year;
    final h = dt.hour.toString().padLeft(2, '0');
    final min = dt.minute.toString().padLeft(2, '0');
    return '$d/$m/$y $h:$min';
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final type = notification.type;
    final isOrder = type == 'order';
    final isPromo = type == 'promo' || type == 'voucher';
    final style = NotificationTypeStyle.of(c, type);

    return Container(
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppTheme.radiusXl),
        ),
      ),
      padding: EdgeInsets.only(
        top: AppSpacing.lg,
        left: AppSpacing.xl,
        right: AppSpacing.xl,
        bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.xxl,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: AppSpacing.xl),
              decoration: BoxDecoration(
                color: c.border,
                borderRadius: BorderRadius.circular(AppTheme.radiusPill),
              ),
            ),
          ),

          // Category Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: style.color.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(style.icon, color: style.color, size: 20),
              ),
              const SizedBox(width: AppSpacing.md),
              Text(
                style.fullName,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: style.color,
                ),
              ),
              const Spacer(),
              Text(
                _formatDateTime(notification.createdAt),
                style: TextStyle(fontSize: 12, color: c.textMuted),
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.lg),

          // Title
          Text(
            notification.title,
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: c.textPrimary,
              height: 1.3,
            ),
          ),

          const SizedBox(height: AppSpacing.md),

          // Body
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              color: c.surfaceVariant,
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              border: Border.all(color: c.border),
            ),
            child: Text(
              notification.body,
              style: TextStyle(
                fontSize: 14,
                color: c.textSecondary,
                height: 1.5,
              ),
            ),
          ),

          const SizedBox(height: AppSpacing.xl),

          // Contextual Action Button
          if (isOrder) ...[
            PrimaryButton(
              label: 'Xem đơn hàng của bạn',
              icon: Icons.receipt_long_rounded,
              height: 48,
              onPressed: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const MyOrdersPage()),
                );
              },
            ),
            const SizedBox(height: AppSpacing.md),
          ] else if (isPromo) ...[
            PrimaryButton(
              label: 'Khám phá kho Voucher ngay',
              icon: Icons.local_offer_rounded,
              height: 48,
              onPressed: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const VoucherListPage()),
                );
              },
            ),
            const SizedBox(height: AppSpacing.md),
          ],

          // Close button
          SecondaryButton(
            label: 'Đóng',
            height: 44,
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }
}
