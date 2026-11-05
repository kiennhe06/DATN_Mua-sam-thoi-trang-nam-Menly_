import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_buttons.dart';
import 'package:menly_app/features/order/data/models/order_model.dart';
import '../providers/order_provider.dart';
import '../widgets/order_timeline_card.dart';
import '../widgets/order_recipient_card.dart';
import '../widgets/order_items_card.dart';
import '../widgets/order_payment_summary_card.dart';
import '../widgets/order_cancel_dialog.dart';
import '../widgets/order_return_request_dialog.dart';
import 'vnpay_payment_page.dart';

/// Man hinh Chi tiet don hang & Theo doi hanh trinh (AP-DH2)
class OrderDetailPage extends StatelessWidget {
  final String? orderId;
  final OrderModel? order;

  const OrderDetailPage({
    super.key,
    this.orderId,
    this.order,
  });

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final orderProv = context.watch<OrderProvider>();

    OrderModel? currentOrder = order;
    if (currentOrder == null && orderId != null) {
      currentOrder = orderProv.findById(orderId!);
    }

    if (currentOrder == null) {
      return Scaffold(
        backgroundColor: c.background,
        appBar: AppBar(title: const Text('Chi tiết đơn hàng')),
        body: const Center(child: Text('Không tìm thấy thông tin đơn hàng')),
      );
    }

    final o = currentOrder;
    final isPendingVnpay = o.status == OrderStatus.pendingPayment && o.paymentMethod == 'vnpay';

    return Scaffold(
      backgroundColor: c.background,
      appBar: AppBar(
        title: Text(
          o.code,
          style: TextStyle(color: c.textPrimary, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 40),
        children: [
          // 1. Tien trinh don hang 5 buoc
          OrderTimelineCard(order: o),
          const SizedBox(height: 12),

          // 2. Thong tin dia chi nhan hang
          OrderRecipientCard(order: o),
          const SizedBox(height: 12),

          // 3. Danh sach san pham
          OrderItemsCard(order: o),
          const SizedBox(height: 12),

          // 4. Bang tong ket thanh toan
          OrderPaymentSummaryCard(order: o),
          const SizedBox(height: 24),

          // 5. Nut thao tac thanh toan VNPay hoac Huy don
          if (isPendingVnpay) ...[
            PrimaryButton(
              label: 'Thanh toán ngay bằng VNPay',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => VNPayPaymentPage(order: o),
                  ),
                );
              },
            ),
            const SizedBox(height: 12),
          ],

          if (o.status == OrderStatus.delivered) ...[
            SecondaryButton(
              label: 'Yêu cầu trả hàng',
              icon: Icons.assignment_return_rounded,
              foreground: c.primary,
              onPressed: () {
                OrderReturnRequestDialog.show(
                  context: context,
                  order: o,
                );
              },
            ),
            const SizedBox(height: 12),
          ],

          if (o.canCancel)
            DestructiveButton(
              label: 'Hủy đơn hàng này',
              onPressed: () {
                OrderCancelDialog.show(
                  context: context,
                  order: o,
                  orderProv: orderProv,
                  onCancelled: () => Navigator.pop(context),
                );
              },
            ),
        ],
      ),
    );
  }
}
