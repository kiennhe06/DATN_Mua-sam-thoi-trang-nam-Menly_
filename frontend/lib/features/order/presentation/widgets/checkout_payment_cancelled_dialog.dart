import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/models/order_model.dart';
import '../pages/my_orders_page.dart';

class CheckoutPaymentCancelledDialog extends StatelessWidget {
  final OrderModel order;
  final VoidCallback onRetry;

  const CheckoutPaymentCancelledDialog({
    super.key,
    required this.order,
    required this.onRetry,
  });

  static Future<void> show({
    required BuildContext context,
    required OrderModel order,
    required VoidCallback onRetry,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => CheckoutPaymentCancelledDialog(
        order: order,
        onRetry: () {
          Navigator.pop(ctx);
          onRetry();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);

    return AlertDialog(
      title: const Text('Chưa hoàn tất thanh toán'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Giao dịch thanh toán qua VNPay cho đơn hàng ${order.code} chưa hoàn tất hoặc đã bị hủy.',
            style: const TextStyle(fontSize: 14),
          ),
          const SizedBox(height: AppSpacing.md),
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: c.secondary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppTheme.radiusSm),
              border: Border.all(color: c.secondary.withValues(alpha: 0.35)),
            ),
            child: Text(
              'Đơn hàng của bạn đã được tạo ở trạng thái "Chờ thanh toán". Bạn có thể thực hiện thanh toán lại hoặc theo dõi tại mục Đơn hàng của tôi.',
              style: TextStyle(
                fontSize: 12.5,
                color: c.textSecondary,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: onRetry,
          child: Text(
            'Thanh toán lại',
            style: TextStyle(
              color: c.textSecondary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: c.primary,
            foregroundColor: c.onPrimary,
            elevation: 0,
          ),
          onPressed: () {
            Navigator.pop(context);
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (_) => const MyOrdersPage(),
              ),
            );
          },
          child: const Text('Đơn hàng của tôi'),
        ),
      ],
    );
  }
}

