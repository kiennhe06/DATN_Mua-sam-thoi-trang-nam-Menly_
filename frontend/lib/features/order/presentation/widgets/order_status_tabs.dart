import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
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
      {'key': 'processing', 'label': 'Đang xử lý'},
      {'key': 'shipping', 'label': 'Đang giao'},
      {'key': 'delivered', 'label': 'Đã giao'},
      {'key': 'canceled', 'label': 'Đã hủy'},
    ];

    return SizedBox(
      height: 42,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: tabs.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final t = tabs[i];
          final isSelected = t['key'] == selectedFilter;
          final count = _countFor(t['key']!);

          return GestureDetector(
            onTap: () => onFilterChanged(t['key']!),
            behavior: HitTestBehavior.opaque,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? c.primary : c.surfaceVariant,
                borderRadius: BorderRadius.circular(AppTheme.radiusPill),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    t['label']!,
                    style: TextStyle(
                      color: isSelected ? c.onPrimary : c.textSecondary,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                  if (count > 0) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: isSelected ? c.secondary : c.border,
                        borderRadius: BorderRadius.circular(AppTheme.radiusPill),
                      ),
                      child: Text(
                        '$count',
                        style: TextStyle(
                          color: isSelected ? c.inkCard : c.textSecondary,
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
