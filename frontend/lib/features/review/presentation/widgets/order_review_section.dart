import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/app_snackbar.dart';
import '../../../../models/order_model.dart';
import '../pages/review_form_page.dart';
import '../providers/review_provider.dart';
import 'review_image_gallery.dart';

class OrderReviewSection extends StatefulWidget {
  final OrderModel order;

  const OrderReviewSection({super.key, required this.order});

  @override
  State<OrderReviewSection> createState() => _OrderReviewSectionState();
}

class _OrderReviewSectionState extends State<OrderReviewSection> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<ReviewProvider>().loadMine();
    });
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
      padding: const EdgeInsets.all(16),
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
              const SizedBox(width: 6),
              Text(
                'Đánh giá sản phẩm',
                style: TextStyle(color: c.textPrimary, fontSize: 15, fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Chia sẻ cảm nhận và ảnh thực tế để giúp người mua sau chọn đúng sản phẩm.',
            style: TextStyle(color: c.textMuted, fontSize: 12, height: 1.4),
          ),
          if (reviewProv.isLoadingMine) ...[
            const SizedBox(height: 16),
            const Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))),
          ],
          const SizedBox(height: 8),
          for (int i = 0; i < widget.order.items.length; i++) ...[
            if (i > 0) Divider(color: c.border.withValues(alpha: 0.5), height: 20),
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
          borderRadius: BorderRadius.circular(10),
          child: SizedBox(
            width: 48,
            height: 48,
            child: item.thumbnailUrl.isNotEmpty
                ? Image.network(
                    item.thumbnailUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(color: c.surfaceVariant),
                  )
                : Container(color: c.surfaceVariant),
          ),
        ),
        const SizedBox(width: 10),
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
              const SizedBox(height: 3),
              Text(
                'Size: ${item.size} · Màu: ${item.color}',
                style: TextStyle(color: c.textMuted, fontSize: 11.5),
              ),
              if (review != null) ...[
                const SizedBox(height: 4),
                Row(
                  children: [
                    for (int star = 0; star < 5; star++)
                      Icon(
                        star < review.rating ? Icons.star_rounded : Icons.star_border_rounded,
                        size: 14,
                        color: Colors.amber,
                      ),
                  ],
                ),
                if (review.images.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  ReviewImageGallery(images: review.images, size: 40, spacing: 6),
                ],
              ],
            ],
          ),
        ),
        const SizedBox(width: 8),
        if (review != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: c.success.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.check_circle, size: 14, color: c.success),
                const SizedBox(width: 4),
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
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () => _openReviewForm(item),
            child: const Text('Đánh giá', style: TextStyle(fontSize: 12)),
          ),
      ],
    );
  }
}
