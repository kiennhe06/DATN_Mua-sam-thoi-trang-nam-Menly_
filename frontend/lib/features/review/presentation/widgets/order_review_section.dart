import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/app_snackbar.dart';
import '../../../../models/order_model.dart';
import '../pages/review_form_page.dart';
import '../providers/review_provider.dart';
import 'review_image_gallery.dart';
import 'package:menly_app/core/widgets/app_image.dart';
import 'package:menly_app/core/widgets/state_views.dart';

class OrderReviewSection extends StatefulWidget {
  final OrderModel order;

  const OrderReviewSection({super.key, required this.order});

  @override
  State<OrderReviewSection> createState() => _OrderReviewSectionState();
}

class _OrderReviewSectionState extends State<OrderReviewSection>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<ReviewProvider>().loadMine();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Quay lai app thi tai lai danh gia: cua hang co the vua tra loi tren trang
    // quan tri trong luc app nam nen, khong bat nguoi dung phai mo lai app.
    if (state == AppLifecycleState.resumed && mounted) {
      context.read<ReviewProvider>().loadMine();
    }
  }

  Future<void> _openReviewForm(OrderItemModel item) async {
    final submitted = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => ReviewFormPage(
          orderItemId: item.id,
          productName: item.productName,
          thumbnailUrl: item.thumbnailUrl,
        ),
      ),
    );

    if (submitted == true && mounted) {
      AppSnackBar.show(context, message: 'Cảm ơn bạn đã đánh giá sản phẩm!', icon: Icons.check_circle_outline);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.order.status == OrderStatus.canceled ||
        widget.order.status == OrderStatus.expired ||
        widget.order.status == OrderStatus.pendingPayment) {
      return const SizedBox.shrink();
    }

    final c = AppColors.of(context);
    final reviewProv = context.watch<ReviewProvider>();

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(color: c.border.withValues(alpha: 0.6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.rate_review_outlined, size: 18, color: c.secondary),
              const SizedBox(width: AppSpacing.sm),
              Text(
                'Đánh giá sản phẩm',
                style: TextStyle(color: c.textPrimary, fontSize: 15, fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Chia sẻ cảm nhận và ảnh thực tế để giúp người mua sau chọn đúng sản phẩm.',
            style: TextStyle(color: c.textMuted, fontSize: 12, height: 1.4),
          ),
          if (reviewProv.isLoadingMine) ...[
            const SizedBox(height: AppSpacing.lg),
            const LoadingView(),
          ],
          const SizedBox(height: AppSpacing.sm),
          for (int i = 0; i < widget.order.items.length; i++) ...[
            if (i > 0)
              Divider(
                color: c.border.withValues(alpha: 0.5),
                height: AppSpacing.xl,
              ),
            _buildItemRow(widget.order.items[i], c, reviewProv),
          ],
        ],
      ),
    );
  }

  Widget _buildItemRow(OrderItemModel item, AppColors c, ReviewProvider reviewProv) {
    final review = reviewProv.reviewForOrderItem(item.id);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(AppTheme.radiusSm),
          child: SizedBox(
            width: 48,
            height: 48,
            child: AppImage(
              url: item.thumbnailUrl,
              fit: BoxFit.cover,
              placeholder: (_) => Container(color: c.surfaceVariant),
              errorWidget: (_) => Container(color: c.surfaceVariant),
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.productName,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: c.textPrimary, fontSize: 13, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Size: ${item.size} · Màu: ${item.color}',
                style: TextStyle(color: c.textMuted, fontSize: 11.5),
              ),
              if (review != null) ...[
                const SizedBox(height: AppSpacing.xs),
                Row(
                  children: [
                    for (int star = 0; star < 5; star++)
                      Icon(
                        star < review.rating ? Icons.star_rounded : Icons.star_border_rounded,
                        size: 14,
                        color: c.secondary,
                      ),
                  ],
                ),
                if (review.images.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.sm),
                  ReviewImageGallery(
                    images: review.images,
                    size: 40,
                    spacing: AppSpacing.sm,
                  ),
                ],
                if (review.replyComment != null &&
                    review.replyComment!.trim().isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.sm,
                    ),
                    decoration: BoxDecoration(
                      color: c.surfaceVariant,
                      borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                      border: Border(
                        left: BorderSide(color: c.secondary, width: 2),
                      ),
                    ),
                    child: Text(
                      'Phản hồi từ Menly: ${review.replyComment}',
                      style: TextStyle(
                        fontSize: 12,
                        height: 1.4,
                        color: c.textSecondary,
                      ),
                    ),
                  ),
                ],
              ],
            ],
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        if (review != null)
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            decoration: BoxDecoration(
              color: c.success.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppTheme.radiusSm),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.check_circle, size: 14, color: c.success),
                const SizedBox(width: AppSpacing.xs),
                Text(
                  'Đã đánh giá',
                  style: TextStyle(color: c.success, fontSize: 11.5, fontWeight: FontWeight.w700),
                ),
              ],
            ),
          )
        else
          OutlinedButton(
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusSm)),
            ),
            onPressed: () => _openReviewForm(item),
            child: const Text('Đánh giá', style: TextStyle(fontSize: 12)),
          ),
      ],
    );
  }
}
