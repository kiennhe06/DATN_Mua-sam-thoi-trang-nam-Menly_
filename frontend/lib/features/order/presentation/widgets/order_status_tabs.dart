import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/pressable.dart';
import 'package:menly_app/features/order/data/models/order_model.dart';

class OrderStatusTabs extends StatelessWidget {
  final String selectedFilter;
  final List<OrderModel> allOrders;
  final ValueChanged<String> onFilterChanged;

  const OrderStatusTabs({
    super.key,
    required this.selectedFilter,
    required this.allOrders,
    required this.onFilterChanged,
  });

  int _countFor(String filter) {
    if (filter == 'all') return allOrders.length;
    return allOrders.where((o) => o.status.value == filter).length;
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final tabs = [
      {'key': 'all', 'label': 'Tất cả'},
      {'key': 'pending_payment', 'label': 'Chờ thanh toán'},
      {'key': 'paid', 'label': 'Đã thanh toán'},
      {'key': 'processing', 'label': 'Đang xử lý'},
      {'key': 'shipping', 'label': 'Đang giao'},
      {'key': 'delivered', 'label': 'Đã giao'},
      {'key': 'completed', 'label': 'Hoàn tất'},
      {'key': 'cancelled', 'label': 'Đã hủy'},
      {'key': 'expired', 'label': 'Hết hạn'},
    ];

    return SizedBox(
      height: 44,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        scrollDirection: Axis.horizontal,
        itemCount: tabs.length,
        separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.sm),
        itemBuilder: (context, i) {
          final t = tabs[i];
          final isSelected = t['key'] == selectedFilter;
          final count = _countFor(t['key']!);

          // Cung kieu chip vien thuoc voi CategoryTab: chon thi to nen ink,
          // chua chon thi nen the co vien mong. Rieng o day co them so dem nen
          // khong dung thang CategoryTab duoc.
          return Pressable(
            onTap: () => onFilterChanged(t['key']!),
            scale: 0.95,
            borderRadius: BorderRadius.circular(AppTheme.radiusPill),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOut,
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
              decoration: BoxDecoration(
                color: isSelected ? c.primary : c.surface,
                borderRadius: BorderRadius.circular(AppTheme.radiusPill),
                border: Border.all(color: isSelected ? c.primary : c.border),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    t['label']!,
                    maxLines: 1,
                    style: TextStyle(
                      color: isSelected ? c.onPrimary : c.textSecondary,
                      fontWeight:
                          isSelected ? FontWeight.w700 : FontWeight.w500,
                      fontSize: 13,
                      letterSpacing: 0.2,
                    ),
                  ),
                  if (count > 0) ...[
                    const SizedBox(width: AppSpacing.sm),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.sm, vertical: 2),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? c.onPrimary.withValues(alpha: 0.22)
                            : c.surfaceVariant,
                        borderRadius:
                            BorderRadius.circular(AppTheme.radiusPill),
                      ),
                      child: Text(
                        '$count',
                        style: TextStyle(
                          color: isSelected ? c.onPrimary : c.textSecondary,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
