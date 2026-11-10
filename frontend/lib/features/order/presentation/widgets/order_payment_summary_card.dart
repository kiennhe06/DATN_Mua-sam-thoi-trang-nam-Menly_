import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
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

    // Hai hinh thuc thanh toan phan biet bang hai tong mau doc duoc tren the:
    // VNPay dung ink, COD dung mau chu phu.
    final badgeColor = isVnpay ? c.primary : c.textSecondary;

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
                'Chi tiết thanh toán',
                style: TextStyle(
                  color: c.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
                decoration: BoxDecoration(
                  color: badgeColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppTheme.radiusPill),
                ),
                child: Text(
                  isVnpay ? 'VNPAY' : 'COD (Tiền mặt)',
                  style: TextStyle(
                    color: badgeColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          _summaryRow('Tạm tính:', formatVnd(order.subtotal), c),
          const SizedBox(height: AppSpacing.md),
          _summaryRow('Phí vận chuyển:', formatVnd(order.shippingFee), c),
          if (order.discountAmount > 0) ...[
            const SizedBox(height: AppSpacing.md),
            _summaryRow('Mã giảm giá:', '-${formatVnd(order.discountAmount)}', c, valueColor: c.success),
          ],
          // Duong ke manh ngan cach truoc dong tong
          Divider(color: c.border.withValues(alpha: 0.6), height: AppSpacing.xxl),
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
