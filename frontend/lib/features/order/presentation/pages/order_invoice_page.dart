import 'package:flutter/material.dart';
import 'package:menly_app/core/theme/app_colors.dart';
import 'package:menly_app/core/theme/app_spacing.dart';
import 'package:menly_app/core/theme/app_theme.dart';
import 'package:menly_app/core/utils/format.dart';
import 'package:menly_app/features/order/data/models/order_model.dart';

/// Bien nhan don hang, dung du lieu that cua don.
///
/// Truoc day co nut In nhung no khong in gi, chi hien mot dong nhac nguoi
/// dung tu chup man hinh. Da bo di de khong hua hen sai.
class OrderInvoicePage extends StatelessWidget {
  final OrderModel order;

  const OrderInvoicePage({super.key, required this.order});

  String get _paymentLabel =>
      order.paymentMethod.toLowerCase() == 'vnpay'
          ? 'Thanh toán trực tuyến VNPay'
          : 'Thanh toán khi nhận hàng (COD)';

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);

    return Scaffold(
      backgroundColor: c.background,
      appBar: AppBar(
        title: const Text('Hóa đơn'),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.xxxl),
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.xl),
            decoration: BoxDecoration(
              color: c.surface,
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              border: Border.all(color: c.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'MENLY',
                            style: TextStyle(
                              color: c.textPrimary,
                              fontWeight: FontWeight.w900,
                              fontSize: 22,
                              letterSpacing: 3,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            'Thời trang nam',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: c.textSecondary,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          Text(
                            '12 Nguyễn Trãi, Quận 5, TP. Hồ Chí Minh',
                            style:
                                TextStyle(fontSize: 12, color: c.textSecondary),
                          ),
                          Text(
                            'Hotline: 1900 6868',
                            style:
                                TextStyle(fontSize: 12, color: c.textSecondary),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'HÓA ĐƠN BÁN HÀNG',
                          style: TextStyle(
                            color: c.textPrimary,
                            fontWeight: FontWeight.w800,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          '#${order.code}',
                          style: TextStyle(
                            color: c.textPrimary,
                            fontFamily: 'monospace',
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          _formatDate(order.createdAt),
                          style:
                              TextStyle(fontSize: 11, color: c.textSecondary),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.sm,
                              vertical: AppSpacing.xs),
                          decoration: BoxDecoration(
                            border: Border.all(color: c.border),
                            borderRadius:
                                BorderRadius.circular(AppTheme.radiusXl),
                          ),
                          child: Text(
                            order.nhanTrangThai,
                            style: TextStyle(
                              color: c.textPrimary,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const Divider(height: AppSpacing.xxxl),
                Text(
                  'Người nhận hàng',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: c.textSecondary,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(order.shipName,
                    style: TextStyle(
                        color: c.textPrimary, fontWeight: FontWeight.w700)),
                Text(order.shipPhone,
                    style: TextStyle(color: c.textPrimary, fontSize: 13)),
                Text(order.shipAddress,
                    style: TextStyle(
                        color: c.textPrimary, fontSize: 13, height: 1.4)),
                const SizedBox(height: AppSpacing.md),
                Text('Thanh toán: $_paymentLabel',
                    style: TextStyle(color: c.textPrimary, fontSize: 13)),
                const Divider(height: AppSpacing.xxxl),
                Text(
                  'Chi tiết sản phẩm',
                  style: TextStyle(
                    color: c.textPrimary,
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                if (order.items.isEmpty)
                  Text('Đơn hàng chưa có thông tin mặt hàng.',
                      style: TextStyle(color: c.textSecondary))
                else
                  ...order.items.asMap().entries.map((entry) {
                    final index = entry.key + 1;
                    final item = entry.value;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.md),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                            width: 22,
                            child: Text('$index.',
                                style: TextStyle(
                                    color: c.textPrimary, fontSize: 13)),
                          ),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(item.productName,
                                    style: TextStyle(
                                        color: c.textPrimary,
                                        fontWeight: FontWeight.w600)),
                                Text(
                                  'Size ${item.size} · Màu ${item.color} · SL ${item.quantity}',
                                  style: TextStyle(
                                      fontSize: 12, color: c.textSecondary),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            formatPrice(item.subtotal),
                            style: TextStyle(
                              color: c.textPrimary,
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                const Divider(height: AppSpacing.xxxl),
                _moneyRow(c, 'Tạm tính sản phẩm', formatPrice(order.subtotal)),
                _moneyRow(
                  c,
                  'Phí vận chuyển',
                  order.shippingFee == 0 ? 'Miễn phí' : formatPrice(order.shippingFee),
                ),
                if (order.discountAmount > 0)
                  _moneyRow(c, 'Giảm giá', '-${formatPrice(order.discountAmount)}'),
                const SizedBox(height: AppSpacing.sm),
                _moneyRow(c, 'Tổng thanh toán', formatPrice(order.total), bold: true),
                const SizedBox(height: AppSpacing.xl),
                Center(
                  child: Text(
                    'Cảm ơn quý khách đã mua sắm tại Menly!',
                    style: TextStyle(fontSize: 12, color: c.textSecondary),
                  ),
                ),
                Center(
                  child: Text(
                    'Hóa đơn lập từ dữ liệu đơn hàng #${order.code}.',
                    style: TextStyle(fontSize: 11, color: c.textMuted),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _moneyRow(AppColors c, String label, String value, {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyle(
                  color: c.textPrimary,
                  fontSize: 13,
                  fontWeight: bold ? FontWeight.w800 : FontWeight.w500)),
          Text(value,
              style: TextStyle(
                  color: c.textPrimary,
                  fontSize: 13,
                  fontWeight: bold ? FontWeight.w800 : FontWeight.w600)),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final local = date.toLocal();
    final dd = local.day.toString().padLeft(2, '0');
    final mm = local.month.toString().padLeft(2, '0');
    final hh = local.hour.toString().padLeft(2, '0');
    final min = local.minute.toString().padLeft(2, '0');
    return '$dd/$mm/${local.year} $hh:$min';
  }
}
