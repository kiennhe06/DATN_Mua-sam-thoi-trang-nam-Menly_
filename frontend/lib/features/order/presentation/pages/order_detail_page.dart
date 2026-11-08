import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/app_snackbar.dart';
import '../../../../core/widgets/app_buttons.dart';
import 'package:menly_app/features/order/data/models/order_model.dart';
import '../../../review/presentation/widgets/order_review_section.dart';
import '../providers/order_provider.dart';
import '../widgets/order_timeline_card.dart';
import '../widgets/order_recipient_card.dart';
import '../widgets/order_items_card.dart';
import '../widgets/order_payment_summary_card.dart';
import '../widgets/order_cancel_dialog.dart';
import 'order_invoice_page.dart';
import 'order_return_request_page.dart';
import 'vnpay_payment_page.dart';

/// Man hinh Chi tiet don hang & Theo doi hanh trinh (AP-DH2)
class OrderDetailPage extends StatefulWidget {
  final String? orderId;
  final OrderModel? order;

  const OrderDetailPage({
    super.key,
    this.orderId,
    this.order,
  });

  @override
  State<OrderDetailPage> createState() => _OrderDetailPageState();
}

class _OrderDetailPageState extends State<OrderDetailPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final id = widget.order?.id ?? widget.orderId;
      final orderProv = context.read<OrderProvider>();
      if (id != null && id.isNotEmpty) {
        orderProv.fetchOrderById(id);
      }
      orderProv.loadReturnRequests();
    });
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final orderProv = context.watch<OrderProvider>();

    final id = widget.order?.id ?? widget.orderId;
    OrderModel? currentOrder;
    if (id != null && id.isNotEmpty) {
      currentOrder = orderProv.findById(id);
    }
    currentOrder ??= widget.order;

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

          // Khoi danh gia chi hien khi khach da nhan hang, giong quy tac may chu
          if (o.canReview) ...[
            OrderReviewSection(order: o),
            const SizedBox(height: 12),
          ],

          // 4. Bang tong ket thanh toan
          OrderPaymentSummaryCard(order: o),
          const SizedBox(height: 16),

          SecondaryButton(
            label: 'Xem hóa đơn',
            icon: Icons.receipt_long_outlined,
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => OrderInvoicePage(order: o)),
              );
            },
          ),
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

          if (o.canReturn) ...[
            _buildReturnAction(context, c, orderProv, o),
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

  Widget _buildReturnAction(
    BuildContext context,
    AppColors c,
    OrderProvider orderProv,
    OrderModel o,
  ) {
    final existing = orderProv.returnForOrder(o.id);
    if (existing != null && existing.isOpen) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: c.surface,
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          border: Border.all(color: c.border.withValues(alpha: 0.6)),
        ),
        child: Row(
          children: [
            Icon(Icons.assignment_return_rounded, color: c.primary),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Yêu cầu trả hàng',
                    style: TextStyle(
                      color: c.textPrimary,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    existing.statusLabel,
                    style: TextStyle(
                      color: c.textSecondary,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (existing.reason.trim().isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      existing.reason,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: c.textMuted, fontSize: 12),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      );
    }

    return SecondaryButton(
      label: 'Yêu cầu trả hàng',
      icon: Icons.assignment_return_rounded,
      foreground: c.primary,
      onPressed: () async {
        final ok = await Navigator.push<bool>(
          context,
          MaterialPageRoute(builder: (_) => OrderReturnRequestPage(order: o)),
        );
        if (ok == true && context.mounted) {
          AppSnackBar.show(context, message: 'Đã gửi yêu cầu trả hàng');
        }
      },
    );
  }
}
