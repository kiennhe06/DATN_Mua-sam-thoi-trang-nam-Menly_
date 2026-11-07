import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/format.dart';
import 'package:menly_app/features/order/data/models/order_model.dart';

class OrderItemsCard extends StatelessWidget {
  final OrderModel order;

  const OrderItemsCard({super.key, required this.order});

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
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
          const SizedBox(height: 12),
          for (int i = 0; i < order.items.length; i++) ...[
            if (i > 0) Divider(color: c.border.withValues(alpha: 0.5), height: 20),
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
          borderRadius: BorderRadius.circular(10),
          child: SizedBox(
            width: 56,
            height: 56,
            child: item.thumbnailUrl.isNotEmpty
                ? CachedNetworkImage(
                    imageUrl: item.thumbnailUrl,
                    fit: BoxFit.cover,
                    placeholder: (_, __) => Container(color: c.surfaceVariant),
                    errorWidget: (_, __, ___) => Container(
                      color: c.surfaceVariant,
                      alignment: Alignment.center,
                      child: Text('Menly', style: TextStyle(color: c.textMuted, fontSize: 10, fontWeight: FontWeight.bold)),
                    ),
                  )
                : Container(
                    color: c.surfaceVariant,
                    alignment: Alignment.center,
                    child: Text('Menly', style: TextStyle(color: c.textMuted, fontSize: 10, fontWeight: FontWeight.bold)),
                  ),
          ),
        ),
        const SizedBox(width: 12),
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
              const SizedBox(height: 3),
              Text(
                'Size: ${item.size} · Màu: ${item.color}',
                style: TextStyle(color: c.textMuted, fontSize: 12),
              ),
              const SizedBox(height: 4),
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
