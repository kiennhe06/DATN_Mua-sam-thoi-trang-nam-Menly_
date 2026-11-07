import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:menly_app/core/utils/format.dart';
import 'package:menly_app/features/order/data/models/order_model.dart';

/// Hoa don don gian in tu du lieu don hang that
class OrderInvoicePage extends StatelessWidget {
  final OrderModel order;

  const OrderInvoicePage({super.key, required this.order});

  String get _paymentLabel =>
      order.paymentMethod.toLowerCase() == 'vnpay'
          ? 'Thanh toán trực tuyến VNPay'
          : 'Thanh toán khi nhận hàng (COD)';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      appBar: AppBar(
        title: const Text('Hóa đơn'),
        centerTitle: true,
        actions: [
          IconButton(
            tooltip: 'In hóa đơn',
            icon: const Icon(Icons.print_outlined),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    kIsWeb
                        ? 'Dùng hộp thoại in của trình duyệt (Ctrl+P).'
                        : 'Chụp màn hình hoặc chia sẻ hóa đơn này để in.',
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'MENLY',
                            style: TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 22,
                              letterSpacing: 3,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Thời trang nam',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.black54,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            '12 Nguyễn Trãi, Quận 5, TP. Hồ Chí Minh',
                            style: TextStyle(fontSize: 12, color: Colors.black54),
                          ),
                          Text(
                            'Hotline: 1900 6868',
                            style: TextStyle(fontSize: 12, color: Colors.black54),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text(
                          'HÓA ĐƠN BÁN HÀNG',
                          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '#${order.code}',
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          _formatDate(order.createdAt),
                          style: const TextStyle(fontSize: 11, color: Colors.black54),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade400),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            order.status.label,
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const Divider(height: 32),
                const Text(
                  'Người nhận hàng',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.black54),
                ),
                const SizedBox(height: 6),
                Text(order.shipName, style: const TextStyle(fontWeight: FontWeight.w700)),
                Text(order.shipPhone, style: const TextStyle(fontSize: 13)),
                Text(order.shipAddress, style: const TextStyle(fontSize: 13, height: 1.4)),
                const SizedBox(height: 12),
                Text('Thanh toán: $_paymentLabel', style: const TextStyle(fontSize: 13)),
                const Divider(height: 32),
                const Text(
                  'Chi tiết sản phẩm',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
                ),
                const SizedBox(height: 8),
                if (order.items.isEmpty)
                  const Text('Đơn hàng chưa có thông tin mặt hàng.')
                else
                  ...order.items.asMap().entries.map((entry) {
                    final index = entry.key + 1;
                    final item = entry.value;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                            width: 22,
                            child: Text('$index.', style: const TextStyle(fontSize: 13)),
                          ),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(item.productName, style: const TextStyle(fontWeight: FontWeight.w600)),
                                Text(
                                  'Size ${item.size} · Màu ${item.color} · SL ${item.quantity}',
                                  style: const TextStyle(fontSize: 12, color: Colors.black54),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            formatPrice(item.subtotal),
                            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                          ),
                        ],
                      ),
                    );
                  }),
                const Divider(height: 28),
                _moneyRow('Tạm tính sản phẩm', formatPrice(order.subtotal)),
                _moneyRow(
                  'Phí vận chuyển',
                  order.shippingFee == 0 ? 'Miễn phí' : formatPrice(order.shippingFee),
                ),
                if (order.discountAmount > 0)
                  _moneyRow('Giảm giá', '-${formatPrice(order.discountAmount)}'),
                const SizedBox(height: 8),
                _moneyRow('Tổng thanh toán', formatPrice(order.total), bold: true),
                const SizedBox(height: 20),
                const Center(
                  child: Text(
                    'Cảm ơn quý khách đã mua sắm tại Menly!',
                    style: TextStyle(fontSize: 12, color: Colors.black54),
                  ),
                ),
                Center(
                  child: Text(
                    'Hóa đơn lập từ dữ liệu đơn hàng #${order.code}.',
                    style: const TextStyle(fontSize: 11, color: Colors.black45),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _moneyRow(String label, String value, {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 13, fontWeight: bold ? FontWeight.w800 : FontWeight.w500)),
          Text(value, style: TextStyle(fontSize: 13, fontWeight: bold ? FontWeight.w800 : FontWeight.w600)),
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
