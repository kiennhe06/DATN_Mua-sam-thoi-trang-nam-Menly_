import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../providers/notification_provider.dart';

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
    final filters = [
      _FilterOption(
        id: NotificationProvider.filterAll,
        label: 'Tất cả',
        icon: Icons.dashboard_rounded,
        count: provider.totalCount,
      ),
      _FilterOption(
        id: NotificationProvider.filterOrder,
        label: 'Đơn hàng',
        icon: Icons.local_shipping_rounded,
        count: provider.orderCount,
      ),
      _FilterOption(
        id: NotificationProvider.filterPromo,
        label: 'Khuyến mãi',
        icon: Icons.local_offer_rounded,
        count: provider.promoCount,
      ),
      _FilterOption(
        id: NotificationProvider.filterSystem,
        label: 'Hệ thống',
        icon: Icons.notifications_active_rounded,
        count: provider.systemCount,
      ),
      _FilterOption(
        id: NotificationProvider.filterUnread,
        label: 'Chưa đọc',
        icon: Icons.mark_email_unread_rounded,
        count: provider.unreadCount,
        highlightUnread: true,
      ),
    ];

    return Container(
      height: 52,
      margin: const EdgeInsets.only(bottom: 8),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        itemCount: filters.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final opt = filters[index];
          final isSelected = selectedFilter == opt.id;

          return Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => onFilterSelected(opt.id),
              borderRadius: BorderRadius.circular(20),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppTheme.textPrimary
                      : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected
                        ? AppTheme.textPrimary
                        : Colors.grey.shade300,
                    width: isSelected ? 1.5 : 1,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.12),
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
                      color: isSelected
                          ? Colors.white
                          : (opt.highlightUnread && opt.count > 0
                              ? AppTheme.primaryAccent
                              : Colors.grey.shade700),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      opt.label,
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                        color: isSelected ? Colors.white : AppTheme.textPrimary,
                      ),
                    ),
                    if (opt.count > 0) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? (opt.highlightUnread
                                  ? AppTheme.primaryAccent
                                  : Colors.white.withValues(alpha: 0.25))
                              : (opt.highlightUnread
                                  ? AppTheme.primaryAccent.withValues(alpha: 0.15)
                                  : Colors.grey.shade200),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '${opt.count}',
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.bold,
                            color: isSelected
                                ? Colors.white
                                : (opt.highlightUnread
                                    ? AppTheme.primaryAccent
                                    : Colors.grey.shade800),
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
  final int count;
  final bool highlightUnread;

  const _FilterOption({
    required this.id,
    required this.label,
    required this.icon,
    required this.count,
    this.highlightUnread = false,
  });
}
