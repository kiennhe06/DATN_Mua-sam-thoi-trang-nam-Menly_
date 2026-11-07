import 'package:flutter/material.dart';
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
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.amber.shade50,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.amber.shade300),
            ),
            child: Text(
              'Đơn hàng của bạn đã được tạo ở trạng thái "Chờ thanh toán". Bạn có thể thực hiện thanh toán lại hoặc theo dõi tại mục Đơn hàng của tôi.',
              style: TextStyle(
                fontSize: 12.5,
                color: Colors.brown.shade800,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: onRetry,
          child: const Text(
            'Thanh toán lại',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.black87,
            foregroundColor: Colors.white,
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
