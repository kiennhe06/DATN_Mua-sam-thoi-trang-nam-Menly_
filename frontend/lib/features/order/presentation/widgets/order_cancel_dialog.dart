import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_buttons.dart';
import 'package:menly_app/features/order/data/models/order_model.dart';
import '../providers/order_provider.dart';

class OrderCancelDialog {
  static void show({
    required BuildContext context,
    required OrderModel order,
    required OrderProvider orderProv,
    VoidCallback? onCancelled,
  }) {
    final c = AppColors.of(context);
    String selectedReason = 'Đổi ý không muốn mua nữa';
    final reasons = [
      'Đổi ý không muốn mua nữa',
      'Muốn thay đổi size hoặc màu',
      'Muốn đổi phương thức thanh toán',
      'Tìm thấy sản phẩm giá tốt hơn',
      'Thời gian giao hàng quá lâu',
      'Khác',
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: c.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Padding(
              padding: EdgeInsets.fromLTRB(
                24,
                16,
                24,
                MediaQuery.of(context).padding.bottom + 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 44,
                      height: 4,
                      decoration: BoxDecoration(
                        color: c.border,
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    'Hủy đơn hàng ${order.code}',
                    style: TextStyle(
                      color: c.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Vui lòng chọn lý do để Menly cải thiện dịch vụ tốt hơn:',
                    style: TextStyle(color: c.textSecondary, fontSize: 13),
                  ),
                  const SizedBox(height: 14),
                  for (final r in reasons)
                    GestureDetector(
                      onTap: () => setState(() => selectedReason = r),
                      behavior: HitTestBehavior.opaque,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Row(
                          children: [
                            Container(
                              width: 20,
                              height: 20,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: selectedReason == r ? c.danger : c.border,
                                  width: 2,
                                ),
                              ),
                              child: selectedReason == r
                                  ? Center(
                                      child: Container(
                                        width: 10,
                                        height: 10,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: c.danger,
                                        ),
                                      ),
                                    )
                                  : null,
                            ),
                            const SizedBox(width: 10),
                            Text(
                              r,
                              style: TextStyle(
                                color: selectedReason == r ? c.textPrimary : c.textSecondary,
                                fontWeight: selectedReason == r ? FontWeight.w700 : FontWeight.normal,
                                fontSize: 13.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  const SizedBox(height: 20),
                  DestructiveButton(
                    label: 'Xác nhận hủy đơn',
                    onPressed: () async {
                      Navigator.pop(ctx);
                      final success = await orderProv.cancelOrderApi(order.id, reason: selectedReason);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(success ? 'Đã hủy đơn hàng thành công' : 'Không thể hủy đơn hàng này'),
                            backgroundColor: success ? c.primary : c.danger,
                          ),
                        );
                        if (success && onCancelled != null) {
                          onCancelled();
                        }
                      }
                    },
                  ),
                  const SizedBox(height: 10),
                  SecondaryButton(
                    label: 'Đóng',
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
