import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/format.dart';
import 'package:menly_app/features/order/data/models/order_model.dart';
import '../pages/order_detail_page.dart';
import 'order_cancel_dialog.dart';
import '../providers/order_provider.dart';

class OrderCard extends StatelessWidget {
  final OrderModel order;
  final OrderProvider orderProv;
  final VoidCallback? onCancelled;

  const OrderCard({
    super.key,
    required this.order,
    required this.orderProv,
    this.onCancelled,
  });

  Color _statusColor(OrderStatus status, AppColors c) {
    switch (status) {
      case OrderStatus.pendingPayment:
        return Colors.orange;
      case OrderStatus.paid:
        return Colors.teal;
      case OrderStatus.processing:
        return c.secondary;
      case OrderStatus.shipping:
        return Colors.blue;
      case OrderStatus.delivered:
        return c.success;
      case OrderStatus.canceled:
      case OrderStatus.returned:
      case OrderStatus.expired:
        return c.danger;
      case OrderStatus.completed:
        return c.success;
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final statusColor = _statusColor(order.status, c);

    return InkWell(
      borderRadius: BorderRadius.circular(AppTheme.radiusLg),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => OrderDetailPage(order: order),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: c.surface,
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          border: Border.all(
            color: order.status == OrderStatus.canceled
                ? c.danger.withValues(alpha: 0.3)
                : c.border.withValues(alpha: 0.6),
          ),
          boxShadow: [
            BoxShadow(
              color: c.shadow,
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: Ma don & Trang thai
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  order.code,
                  style: TextStyle(
                    color: c.textPrimary,
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                    border:
                        Border.all(color: statusColor.withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    order.status.label,
                    style: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 11.5,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'Đặt ngày: ${order.createdAt.day}/${order.createdAt.month}/${order.createdAt.year}',
              style: TextStyle(color: c.textMuted, fontSize: 12),
            ),
            Divider(color: c.border.withValues(alpha: 0.6), height: 18),

            // Danh sach san pham tom tat
            for (final item in order.items.take(2))
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${item.productName} (${item.size}, ${item.color})',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: c.textPrimary, fontSize: 13),
                      ),
                    ),
                    Text(
                      'x${item.quantity}',
                      style: TextStyle(color: c.textSecondary, fontSize: 12),
                    ),
                  ],
                ),
              ),
            if (order.items.length > 2)
              Text(
                '+ Thêm ${order.items.length - 2} sản phẩm khác',
                style: TextStyle(
                    color: c.textMuted,
                    fontSize: 11,
                    fontStyle: FontStyle.italic),
              ),
            const SizedBox(height: 10),

            // Footer: Tong tien & Thao tac
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Tổng thanh toán:',
                        style: TextStyle(color: c.textSecondary, fontSize: 11)),
                    Text(
                      formatVnd(order.total),
                      style: TextStyle(
                        color: c.secondary,
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    if (order.canCancel) ...[
                      TextButton(
                        onPressed: () {
                          OrderCancelDialog.show(
                            context: context,
                            order: order,
                            orderProv: orderProv,
                            onCancelled: onCancelled,
                          );
                        },
                        child: Text(
                          'Hủy đơn',
                          style: TextStyle(
                              color: c.danger,
                              fontWeight: FontWeight.bold,
                              fontSize: 12.5),
                        ),
                      ),
                      const SizedBox(width: 4),
                    ],
                    OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 8),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => OrderDetailPage(order: order),
                          ),
                        );
                      },
                      child: const Text('Chi tiết',
                          style: TextStyle(fontSize: 12.5)),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
