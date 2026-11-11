import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/format.dart';
import 'package:menly_app/features/order/data/models/order_model.dart';
import '../pages/order_detail_page.dart';
import '../pages/order_return_request_page.dart';
import 'order_cancel_dialog.dart';
import '../providers/order_provider.dart';

class OrderCard extends StatelessWidget {
  final OrderModel order;
  final OrderProvider orderProv;
  final VoidCallback? onCancelled;

  const OrderCard({
    super.key,
    required this.order,
    required this.orderProv,
    this.onCancelled,
  });

  /// Mau nhan trang thai, gom bon nhom theo bang mau chung: cho (trung tinh),
  /// dang chay (ink), xong (success), that bai (danger). Khong dung c.secondary
  /// lam mau chu vi sac nhan be nhat gan trung voi nen the.
  Color _statusColor(OrderStatus status, AppColors c) {
    switch (status) {
      case OrderStatus.pendingPayment:
        return c.textSecondary;
      case OrderStatus.paid:
        return c.success;
      case OrderStatus.processing:
      case OrderStatus.shipping:
        return c.primary;
      case OrderStatus.delivered:
        return c.success;
      case OrderStatus.canceled:
      case OrderStatus.returned:
      case OrderStatus.expired:
        return c.danger;
      case OrderStatus.completed:
        return c.success;
    }
  }

  /// Nut chi co chu trong the don: vung cham dang vien thuoc cho dong bo voi
  /// cac nut khac.
  ButtonStyle _nutChuVienThuoc() {
    return TextButton.styleFrom(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md, vertical: AppSpacing.md),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusPill),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    // Don da hoan tien khong con la don giao thanh cong nua, nen lay mau
    // canh bao giong don da tra hang thay vi mau xanh cua "Da giao hang".
    final statusColor =
        order.daHoanTien ? c.danger : _statusColor(order.status, c);

    return InkWell(
      borderRadius: BorderRadius.circular(AppTheme.radiusXl),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => OrderDetailPage(order: order),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.lg),
        decoration: BoxDecoration(
          color: c.surface,
          borderRadius: BorderRadius.circular(AppTheme.radiusXl),
          border: Border.all(
            color: order.status == OrderStatus.canceled
                ? c.danger.withValues(alpha: 0.3)
                : c.border.withValues(alpha: 0.6),
          ),
          // Bong rat nhe, the van phang nhung tach khoi nen be.
          boxShadow: [
            BoxShadow(
              color: c.shadow,
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: Ma don & Trang thai
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  order.code,
                  style: TextStyle(
                    color: c.textPrimary,
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                  ),
                ),
                // Chip trang thai dang vien thuoc: nen mo cua chinh mau
                // trang thai, chu dam cung mau.
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md, vertical: AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(AppTheme.radiusPill),
                  ),
                  child: Text(
                    order.nhanTrangThai,
                    style: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.w800,
                      fontSize: 11.5,
                      letterSpacing: 0.2,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Đặt ngày: ${order.createdAt.day}/${order.createdAt.month}/${order.createdAt.year}',
              style: TextStyle(color: c.textMuted, fontSize: 12),
            ),
            Divider(
                color: c.border.withValues(alpha: 0.6), height: AppSpacing.xxl),

            // Danh sach san pham tom tat
            for (final item in order.items.take(2))
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${item.productName} (${item.size}, ${item.color})',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: c.textPrimary, fontSize: 13),
                      ),
                    ),
                    Text(
                      'x${item.quantity}',
                      style: TextStyle(color: c.textSecondary, fontSize: 12),
                    ),
                  ],
                ),
              ),
            if (order.items.length > 2)
              Text(
                '+ Thêm ${order.items.length - 2} sản phẩm khác',
                style: TextStyle(
                    color: c.textMuted,
                    fontSize: 11,
                    fontStyle: FontStyle.italic),
              ),
            const SizedBox(height: AppSpacing.lg),

            // Footer: Tong tien o tren, cac nut o hang rieng ben duoi va luon
            // can phai.
            //
            // Truoc day tong tien va nut nam chung mot hang: don co mot nut thi
            // nut dinh ngay sau so tien, don co ba nut thi nut rot xuong dong
            // moi sat le trai. Ba the lien nhau ra ba kieu xep khac nhau.
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Tổng thanh toán:',
                    style: TextStyle(color: c.textSecondary, fontSize: 11)),
                Text(
                  formatVnd(order.total),
                  style: TextStyle(
                    color: c.secondary,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                // Phai chiem het be ngang thi can phai moi co tac dung: Wrap tu
                // co lai bang dung be rong cac nut, luc do alignment vo nghia.
                SizedBox(
                  width: double.infinity,
                  child: Wrap(
                    alignment: WrapAlignment.end,
                    spacing: AppSpacing.xs,
                    runSpacing: AppSpacing.sm,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                    if (order.canCancel) ...[
                      TextButton(
                        style: _nutChuVienThuoc(),
                        onPressed: () {
                          OrderCancelDialog.show(
                            context: context,
                            order: order,
                            orderProv: orderProv,
                            onCancelled: onCancelled,
                          );
                        },
                        child: Text(
                          'Hủy đơn',
                          style: TextStyle(
                              color: c.danger,
                              fontWeight: FontWeight.bold,
                              fontSize: 12.5),
                        ),
                      ),
                    ],
                    // Truoc day cho nay chi loai tru don da huy, het han va cho
                    // thanh toan, nen tra tien xong la danh gia duoc ngay khi
                    // hang chua giao.
                    if (order.canReview) ...[
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: c.primary,
                          foregroundColor: c.onPrimary,
                          padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.lg,
                              vertical: AppSpacing.md),
                          shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(AppTheme.radiusPill)),
                          elevation: 0,
                        ),
                        icon: const Icon(Icons.star_rate_rounded, size: 15),
                        label: const Text('Đánh giá',
                            style: TextStyle(
                                fontSize: 12, fontWeight: FontWeight.bold)),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => OrderDetailPage(order: order),
                            ),
                          );
                        },
                      ),
                      const SizedBox(width: AppSpacing.sm),
                    ],
                    if (orderProv.canRequestReturn(order)) ...[
                      TextButton(
                        style: _nutChuVienThuoc(),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => OrderReturnRequestPage(order: order),
                            ),
                          );
                        },
                        child: Text(
                          'Trả hàng',
                          style: TextStyle(
                            color: c.primary,
                            fontWeight: FontWeight.bold,
                            fontSize: 12.5,
                          ),
                        ),
                      ),
                    ],
                    OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.lg, vertical: AppSpacing.md),
                        shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(AppTheme.radiusPill)),
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => OrderDetailPage(order: order),
                          ),
                        );
                      },
                      child: const Text('Chi tiết',
                          style: TextStyle(fontSize: 12.5)),
                    ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
