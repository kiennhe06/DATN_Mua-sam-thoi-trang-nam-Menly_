import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/models/review_model.dart';
import '../providers/review_provider.dart';
import 'review_image_gallery.dart';

class ProductReviewsSection extends StatefulWidget {
  final String productId;

  const ProductReviewsSection({super.key, required this.productId});

  @override
  State<ProductReviewsSection> createState() => _ProductReviewsSectionState();
}

class _ProductReviewsSectionState extends State<ProductReviewsSection> {
  static const int _collapsedCount = 2;

  bool _expanded = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<ReviewProvider>().loadProductReviews(widget.productId);
    });
  }

  @override
  void didUpdateWidget(covariant ProductReviewsSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.productId != widget.productId) {
      _expanded = false;
      context.read<ReviewProvider>().loadProductReviews(widget.productId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final provider = context.watch<ReviewProvider>();
    final reviews = provider.reviewsFor(widget.productId);
    final visibleReviews =
        _expanded ? reviews : reviews.take(_collapsedCount).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.rate_review_outlined, size: 19, color: c.secondary),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                'Đánh giá từ khách hàng',
                style: TextStyle(
                  color: c.textPrimary,
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            if (reviews.isNotEmpty)
              Text(
                '${reviews.length} đánh giá',
                style: TextStyle(color: c.textMuted, fontSize: 12.5),
              ),
          ],
        ),
        const SizedBox(height: 10),
        if (provider.isLoadingProductFor(widget.productId) && reviews.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 20),
            child: Center(
              child: SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 2.2),
              ),
            ),
          )
        else if (reviews.isEmpty)
          _buildEmpty(c)
        else ...[
          _buildSummary(c, reviews),
          const SizedBox(height: 12),
          for (int i = 0; i < visibleReviews.length; i++) ...[
            if (i > 0)
              Divider(color: c.border.withValues(alpha: 0.6), height: 24),
            _buildReview(visibleReviews[i], c),
          ],
          if (reviews.length > _collapsedCount)
            Align(
              alignment: Alignment.center,
              child: TextButton(
                onPressed: () => setState(() => _expanded = !_expanded),
                child: Text(
                  _expanded
                      ? 'Thu gọn'
                      : 'Xem thêm ${reviews.length - _collapsedCount} đánh giá',
                ),
              ),
            ),
        ],
      ],
    );
  }

  Widget _buildEmpty(AppColors c) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 22),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(color: c.border),
      ),
      child: Column(
        children: [
          Icon(Icons.rate_review_outlined, color: c.textMuted, size: 30),
          const SizedBox(height: 8),
          Text(
            'Chưa có đánh giá nào',
            style: TextStyle(color: c.textPrimary, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          Text(
            'Hãy mua sản phẩm và chia sẻ cảm nhận kèm ảnh thực tế của bạn.',
            textAlign: TextAlign.center,
            style: TextStyle(color: c.textMuted, fontSize: 12.5, height: 1.4),
          ),
        ],
      ),
    );
  }

  Widget _buildSummary(AppColors c, List<ReviewModel> reviews) {
    final average = reviews.fold<int>(0, (sum, review) => sum + review.rating) /
        reviews.length;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: c.primarySoft,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      ),
      child: Row(
        children: [
          Text(
            average.toStringAsFixed(1),
            style: TextStyle(
              color: c.textPrimary,
              fontSize: 28,
              fontWeight: FontWeight.w800,
              height: 1,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildStars(average.round(), 16),
                const SizedBox(height: 3),
                Text(
                  'Dựa trên ${reviews.length} đánh giá đã xác thực',
                  style: TextStyle(color: c.textSecondary, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReview(ReviewModel review, AppColors c) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildAvatar(review, c),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      review.userName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: c.textPrimary,
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        _buildStars(review.rating, 14),
                        const SizedBox(width: 8),
                        Text(
                          _formatDate(review.createdAt),
                          style: TextStyle(color: c.textMuted, fontSize: 11.5),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (review.comment.trim().isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              review.comment,
              style: TextStyle(
                  color: c.textSecondary, fontSize: 13.5, height: 1.5),
            ),
          ],
          if (review.images.isNotEmpty) ...[
            const SizedBox(height: 10),
            ReviewImageGallery(images: review.images),
          ],
          if (review.replyComment != null &&
              review.replyComment!.trim().isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: c.surfaceVariant,
                borderRadius: BorderRadius.circular(AppTheme.radiusSm),
              ),
              child: Text(
                'Phản hồi từ Menly: ${review.replyComment}',
                style: TextStyle(
                  color: c.textSecondary,
                  fontSize: 12.5,
                  height: 1.45,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAvatar(ReviewModel review, AppColors c) {
    final name = review.userName.trim();
    final initial = name.isEmpty ? 'M' : name.substring(0, 1).toUpperCase();

    final fallback = Container(
      width: 38,
      height: 38,
      alignment: Alignment.center,
      color: c.surfaceVariant,
      child: Text(
        initial,
        style: TextStyle(color: c.textSecondary, fontWeight: FontWeight.w700),
      ),
    );

    return ClipOval(
      child: SizedBox(
        width: 38,
        height: 38,
        child: review.userAvatar != null && review.userAvatar!.isNotEmpty
            ? Image.network(
                review.userAvatar!,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => fallback,
              )
            : fallback,
      ),
    );
  }

  Widget _buildStars(int rating, double size) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (int i = 0; i < 5; i++)
          Icon(
            i < rating ? Icons.star_rounded : Icons.star_border_rounded,
            size: size,
            color: Colors.amber,
          ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    final difference = DateTime.now().difference(date);
    if (difference.inMinutes < 1) return 'Vừa xong';
    if (difference.inHours < 1) return '${difference.inMinutes} phút trước';
    if (difference.inDays < 1) return '${difference.inHours} giờ trước';
    if (difference.inDays < 7) return '${difference.inDays} ngày trước';

    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    return '$day/$month/${date.year}';
  }
}
