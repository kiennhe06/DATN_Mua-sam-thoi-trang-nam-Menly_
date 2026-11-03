import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/format.dart';
import '../../../../core/widgets/app_buttons.dart';
import '../../../../models/order_model.dart';
import 'order_detail_page.dart';
import 'my_orders_page.dart';

class OrderSuccessPage extends StatefulWidget {
  final OrderModel? order;
  final String? orderCode;
  final int? total;

  const OrderSuccessPage({
    super.key,
    this.order,
    this.orderCode,
    this.total,
  });

  @override
  State<OrderSuccessPage> createState() => _OrderSuccessPageState();
}

class _OrderSuccessPageState extends State<OrderSuccessPage> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scaleAnim;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 700));
    _scaleAnim = CurvedAnimation(parent: _ctrl, curve: Curves.elasticOut);
    _fadeAnim = CurvedAnimation(parent: _ctrl, curve: Curves.easeIn);
    Future.delayed(const Duration(milliseconds: 150), () => _ctrl.forward());
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final code = widget.order?.code ?? widget.orderCode ?? 'MENLY-ORDER';
    final totalAmount = widget.order?.total ?? widget.total ?? 0;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) Navigator.of(context).popUntil((route) => route.isFirst);
      },
      child: Scaffold(
        backgroundColor: c.background,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Hieu ung vong tron hoan thanh thanh cong
                ScaleTransition(
                  scale: _scaleAnim,
                  child: FadeTransition(
                    opacity: _fadeAnim,
                    child: Center(
                      child: Container(
                        width: 90,
                        height: 90,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: c.success,
                          boxShadow: [
                            BoxShadow(
                              color: c.success.withValues(alpha: 0.35),
                              blurRadius: 24,
                              spreadRadius: 3,
                            ),
                          ],
                        ),
                        child: const Center(
                          child: Text(
                            '✓',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 48,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                FadeTransition(
                  opacity: _fadeAnim,
                  child: Column(
                    children: [
                      Text(
                        'Đặt hàng thành công!',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: c.textPrimary,
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Cảm ơn bạn đã mua sắm tại Menly.\nĐơn hàng của bạn đang được tiếp nhận và sẽ sớm được giao đến bạn.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: c.textSecondary,
                          fontSize: 13.5,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Khung thong tin ma don hang
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: c.surface,
                          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                          border: Border.all(color: c.secondary.withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'MÃ ĐƠN HÀNG',
                                    style: TextStyle(
                                      color: c.textMuted,
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    code,
                                    style: TextStyle(
                                      color: c.textPrimary,
                                      fontSize: 15,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 0.8,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            TextButton(
                              onPressed: () {
                                Clipboard.setData(ClipboardData(text: code));
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Đã sao chép mã đơn hàng')),
                                );
                              },
                              child: const Text('Sao chép'),
                            ),
                          ],
                        ),
                      ),

                      if (totalAmount > 0) ...[
                        const SizedBox(height: 10),
                        Text(
                          'Tổng thanh toán: ${formatVnd(totalAmount)}',
                          style: TextStyle(
                            color: c.secondary,
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // 3 the cam ket thoi trang Menly
                Row(
                  children: [
                    _infoCard(c, 'Giao hàng', '2–3 ngày'),
                    const SizedBox(width: 10),
                    _infoCard(c, 'Hỗ trợ', '1900 6868'),
                    const SizedBox(width: 10),
                    _infoCard(c, 'Chính hãng', '100% Menly'),
                  ],
                ),
                const SizedBox(height: 32),

                // Nut hanh dong
                PrimaryButton(
                  label: 'Tiếp tục mua sắm',
                  onPressed: () => Navigator.of(context).popUntil((route) => route.isFirst),
                ),
                const SizedBox(height: 10),
                if (widget.order != null)
                  SecondaryButton(
                    label: 'Xem chi tiết đơn hàng này',
                    onPressed: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (_) => OrderDetailPage(order: widget.order!),
                        ),
                      );
                    },
                  )
                else
                  SecondaryButton(
                    label: 'Xem đơn hàng của tôi',
                    onPressed: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const MyOrdersPage(),
                        ),
                      );
                    },
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _infoCard(AppColors c, String title, String subtitle) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: c.surface,
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          border: Border.all(color: c.border),
        ),
        child: Column(
          children: [
            Text(
              title,
              style: TextStyle(
                color: c.textPrimary,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: TextStyle(color: c.textSecondary, fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }
}
