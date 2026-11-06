import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/format.dart';
import 'package:menly_app/features/order/data/models/order_model.dart';

class OrderPaymentSummaryCard extends StatelessWidget {
  final OrderModel order;

  const OrderPaymentSummaryCard({super.key, required this.order});

  Widget _summaryRow(String label, String value, AppColors c, {Color? valueColor, bool isBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: c.textSecondary,
            fontSize: 13,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: valueColor ?? c.textPrimary,
            fontSize: 13,
            fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final isVnpay = order.paymentMethod.toLowerCase() == 'vnpay';

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
                'Chi tiết thanh toán',
                style: TextStyle(
                  color: c.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: isVnpay ? Colors.blue.withValues(alpha: 0.12) : Colors.orange.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  isVnpay ? 'VNPAY' : 'COD (Tiền mặt)',
                  style: TextStyle(
                    color: isVnpay ? Colors.blue.shade700 : Colors.orange.shade800,
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _summaryRow('Tạm tính:', formatVnd(order.subtotal), c),
          const SizedBox(height: 8),
          _summaryRow('Phí vận chuyển:', formatVnd(order.shippingFee), c),
          if (order.discountAmount > 0) ...[
            const SizedBox(height: 8),
            _summaryRow('Mã giảm giá:', '-${formatVnd(order.discountAmount)}', c, valueColor: c.success),
          ],
          Divider(color: c.border.withValues(alpha: 0.6), height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Tổng thanh toán:',
                style: TextStyle(
                  color: c.textPrimary,
                  fontSize: 14.5,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                formatVnd(order.total),
                style: TextStyle(
                  color: c.secondary,
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
