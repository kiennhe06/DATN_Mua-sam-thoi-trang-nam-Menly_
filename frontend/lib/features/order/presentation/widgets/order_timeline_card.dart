import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import 'package:menly_app/features/order/data/models/order_model.dart';

class OrderTimelineCard extends StatelessWidget {
  final OrderModel order;

  const OrderTimelineCard({super.key, required this.order});

  static int getTimelineStep(OrderStatus status) {
    switch (status) {
      case OrderStatus.pendingPayment:
        return 0; // Chờ thanh toán
      case OrderStatus.paid:
        return 1; // Đã thanh toán
      case OrderStatus.processing:
        return 2; // Đang xử lý / đóng gói
      case OrderStatus.shipping:
        return 3; // Đang vận chuyển
      case OrderStatus.delivered:
        return 4; // Đã giao hàng
      case OrderStatus.canceled:
      case OrderStatus.returned:
      case OrderStatus.expired:
        return -1; // Đã hủy / trả
      case OrderStatus.completed:
        return 4; // Hoàn tất
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final currentStep = getTimelineStep(order.status);
    final isCancelled = order.status == OrderStatus.canceled;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(
          color: isCancelled
              ? c.danger.withValues(alpha: 0.3)
              : c.border.withValues(alpha: 0.6),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: (isCancelled ? c.danger : c.secondary)
                      .withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  isCancelled ? 'ĐÃ HỦY' : 'TIẾN TRÌNH',
                  style: TextStyle(
                    color: isCancelled ? c.danger : c.secondary,
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Hành trình giao hàng',
                  style: TextStyle(
                    color: c.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  order.code,
                  style: TextStyle(
                    color: c.textMuted,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.end,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (isCancelled) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: c.danger.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: c.danger.withValues(alpha: 0.2)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: c.danger,
                      shape: BoxShape.circle,
                    ),
                    child: const Center(
                      child: Text('✕',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Đơn hàng đã hủy',
                          style: TextStyle(
                              color: c.danger,
                              fontWeight: FontWeight.bold,
                              fontSize: 13),
                        ),
                        if (order.cancelReason != null &&
                            order.cancelReason!.isNotEmpty)
                          Text(
                            'Lý do: ${order.cancelReason}',
                            style:
                                TextStyle(color: c.textSecondary, fontSize: 12),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ] else ...[
            _buildTimeline(context, currentStep),
          ],
        ],
      ),
    );
  }

  Widget _buildTimeline(BuildContext context, int currentStep) {
    final c = AppColors.of(context);
    final steps = [
      {'title': 'Đã đặt hàng', 'sub': 'Hệ thống đã ghi nhận đơn'},
      {'title': 'Đã xác nhận', 'sub': 'Kho chuẩn bị hàng'},
      {'title': 'Đang đóng gói', 'sub': 'Kiểm tra chất lượng & tem mác'},
      {'title': 'Đang vận chuyển', 'sub': 'Bàn giao cho đơn vị vận chuyển'},
      {'title': 'Giao thành công', 'sub': 'Khách hàng đã nhận hàng'},
    ];

    return Column(
      children: [
        for (int i = 0; i < steps.length; i++)
          _buildStepRow(
            context,
            index: i,
            title: steps[i]['title']!,
            subtitle: steps[i]['sub']!,
            isDone: i <= currentStep,
            isCurrent: i == currentStep,
            isLast: i == steps.length - 1,
            c: c,
          ),
      ],
    );
  }

  Widget _buildStepRow(
    BuildContext context, {
    required int index,
    required String title,
    required String subtitle,
    required bool isDone,
    required bool isCurrent,
    required bool isLast,
    required AppColors c,
  }) {
    final activeColor =
        isCurrent ? c.secondary : (isDone ? c.success : c.border);
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Dot & vertical line
          Column(
            children: [
              Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  color: isDone ? activeColor : c.surfaceVariant,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isDone ? activeColor : c.border,
                    width: 2,
                  ),
                ),
                child: Center(
                  child: isDone
                      ? Text(
                          '✓',
                          style: TextStyle(
                            color: isCurrent ? c.inkCard : Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        )
                      : Text(
                          '${index + 1}',
                          style: TextStyle(
                            color: c.textMuted,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    color:
                        isDone ? activeColor.withValues(alpha: 0.5) : c.border,
                    margin: const EdgeInsets.symmetric(vertical: 4),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 12),
          // Texts
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: isDone ? c.textPrimary : c.textMuted,
                      fontWeight: isCurrent
                          ? FontWeight.w800
                          : (isDone ? FontWeight.w600 : FontWeight.normal),
                      fontSize: 13.5,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: isDone ? c.textSecondary : c.textMuted,
                      fontSize: 11.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
