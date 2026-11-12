import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_theme.dart';
import '../providers/notification_provider.dart';
import 'notification_item_card.dart';

class NotificationFilterBar extends StatelessWidget {
  final String selectedFilter;
  final Function(String filter) onFilterSelected;
  final NotificationProvider provider;

  const NotificationFilterBar({
    super.key,
    required this.selectedFilter,
    required this.onFilterSelected,
    required this.provider,
  });

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    // Ba bo loc theo loai lay mau va bieu tuong tu cung bang voi the thong bao.
    final orderStyle = NotificationTypeStyle.of(c, 'order');
    final promoStyle = NotificationTypeStyle.of(c, 'promo');
    final systemStyle = NotificationTypeStyle.of(c, 'system');

    final filters = [
      _FilterOption(
        id: NotificationProvider.filterAll,
        label: 'Tất cả',
        icon: Icons.dashboard_rounded,
        tint: c.textSecondary,
        count: provider.totalCount,
      ),
      _FilterOption(
        id: NotificationProvider.filterOrder,
        label: orderStyle.tag,
        icon: orderStyle.icon,
        tint: orderStyle.color,
        count: provider.orderCount,
      ),
      _FilterOption(
        id: NotificationProvider.filterPromo,
        label: promoStyle.tag,
        icon: promoStyle.icon,
        tint: promoStyle.color,
        count: provider.promoCount,
      ),
      _FilterOption(
        id: NotificationProvider.filterSystem,
        label: systemStyle.tag,
        icon: systemStyle.icon,
        tint: systemStyle.color,
        count: provider.systemCount,
      ),
      _FilterOption(
        id: NotificationProvider.filterUnread,
        label: 'Chưa đọc',
        icon: Icons.mark_email_unread_rounded,
        tint: c.primary,
        count: provider.unreadCount,
      ),
    ];

    return Container(
      height: 52,
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.xs,
        ),
        itemCount: filters.length,
        separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.sm),
        itemBuilder: (context, index) {
          final opt = filters[index];
          final isSelected = selectedFilter == opt.id;
          final radius = BorderRadius.circular(AppTheme.radiusPill);

          return Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => onFilterSelected(opt.id),
              borderRadius: radius,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.xs,
                ),
                decoration: BoxDecoration(
                  color: isSelected ? c.primary : c.surface,
                  borderRadius: radius,
                  border: Border.all(
                    color: isSelected ? c.primary : c.border,
                    width: isSelected ? 1.5 : 1,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: c.shadow,
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      opt.icon,
                      size: 15,
                      color: isSelected ? c.onPrimary : opt.tint,
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Text(
                      opt.label,
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight:
                            isSelected ? FontWeight.bold : FontWeight.w600,
                        color: isSelected ? c.onPrimary : c.textPrimary,
                      ),
                    ),
                    if (opt.count > 0) ...[
                      const SizedBox(width: AppSpacing.xs),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.xs,
                          vertical: 1.5,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? c.onPrimary.withValues(alpha: 0.25)
                              : opt.tint.withValues(alpha: 0.15),
                          borderRadius:
                              BorderRadius.circular(AppTheme.radiusPill),
                        ),
                        child: Text(
                          '${opt.count}',
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.bold,
                            color: isSelected ? c.onPrimary : opt.tint,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _FilterOption {
  final String id;
  final String label;
  final IconData icon;

  /// Mau nhan dien cua bo loc khi chua duoc chon.
  final Color tint;
  final int count;

  const _FilterOption({
    required this.id,
    required this.label,
    required this.icon,
    required this.tint,
    required this.count,
  });
}
