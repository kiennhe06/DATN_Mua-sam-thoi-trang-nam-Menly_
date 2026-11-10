import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/format.dart';
import 'package:menly_app/features/order/data/models/order_model.dart';
import 'package:menly_app/core/widgets/app_image.dart';

class OrderItemsCard extends StatelessWidget {
  final OrderModel order;

  const OrderItemsCard({super.key, required this.order});

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      // Cung kieu the voi cac khoi khac: bo goc manh, vien mong
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusXl),
        border: Border.all(color: c.border.withValues(alpha: 0.6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Sản phẩm (${order.items.length})',
                style: TextStyle(
                  color: c.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                formatVnd(order.subtotal),
                style: TextStyle(
                  color: c.secondary,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          for (int i = 0; i < order.items.length; i++) ...[
            if (i > 0) Divider(color: c.border.withValues(alpha: 0.5), height: AppSpacing.xxl),
            _buildItemRow(order.items[i], c),
          ],
        ],
      ),
    );
  }

  Widget _buildItemRow(OrderItemModel item, AppColors c) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          child: SizedBox(
            width: 64,
            height: 64,
            child: AppImage(
              url: item.thumbnailUrl,
              fit: BoxFit.cover,
              placeholder: (_) => Container(color: c.surfaceVariant),
              errorWidget: (_) => Container(
                color: c.surfaceVariant,
                alignment: Alignment.center,
                child: Text('Menly', style: TextStyle(color: c.textMuted, fontSize: 10, fontWeight: FontWeight.bold)),
              ),
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.lg),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.productName,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: c.textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              if (item.size.trim().isNotEmpty || item.color.trim().isNotEmpty)
                Text(
                  [
                    if (item.size.trim().isNotEmpty) 'Size: ${item.size.trim()}',
                    if (item.color.trim().isNotEmpty) 'Màu: ${item.color.trim()}',
                  ].join(' · '),
                  style: TextStyle(color: c.textMuted, fontSize: 12),
                ),
              const SizedBox(height: AppSpacing.xs),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'x${item.quantity}',
                    style: TextStyle(color: c.textSecondary, fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                  Text(
                    formatVnd(item.subtotal),
                    style: TextStyle(
                      color: c.textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
