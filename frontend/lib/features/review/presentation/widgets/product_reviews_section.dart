import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/app_snackbar.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../auth/presentation/pages/login_page.dart';
import '../../data/models/review_model.dart';
import '../pages/review_form_page.dart';
import '../providers/review_provider.dart';
import 'review_image_gallery.dart';
import 'package:menly_app/core/widgets/app_image.dart';
import 'package:menly_app/core/widgets/state_views.dart';

class ProductReviewsSection extends StatefulWidget {
  final String productId;
  final String? productName;
  final String? thumbnailUrl;

  const ProductReviewsSection({
    super.key,
    required this.productId,
    this.productName,
    this.thumbnailUrl,
  });

  @override
  State<ProductReviewsSection> createState() => _ProductReviewsSectionState();
}

class _ProductReviewsSectionState extends State<ProductReviewsSection>
    with WidgetsBindingObserver {
  static const int _collapsedCount = 2;

  bool _expanded = false;

  /// Chi nguoi da nhan duoc hang moi thay nut viet danh gia.
  bool _canReview = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _refreshCanReview();
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

  Future<void> _openReviewForm(BuildContext context) async {
    final auth = context.read<AuthProvider>();
    if (!auth.isLoggedIn) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng đăng nhập để viết đánh giá sản phẩm.')),
      );
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const LoginPage()),
      );
      return;
    }

    final submitted = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => ReviewFormPage(
          productId: widget.productId,
          productName: widget.productName ?? 'Sản phẩm',
          thumbnailUrl: widget.thumbnailUrl ?? '',
        ),
      ),
    );

    if (submitted == true && context.mounted) {
      context.read<ReviewProvider>().loadProductReviews(widget.productId);
      AppSnackBar.show(
        context,
        message: 'Cảm ơn bạn đã gửi đánh giá sản phẩm!',
        icon: Icons.check_circle_outline,
      );
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Cua hang co the vua tra loi danh gia tren trang quan tri; quay lai app la
    // tai lai ngay, khong phai mo lai app.
    if (state == AppLifecycleState.resumed && mounted) {
      context.read<ReviewProvider>().loadProductReviews(widget.productId);
      _refreshCanReview();
    }
  }

  /// Hoi lai may chu xem co duoc danh gia khong.
  ///
  /// Nguoi chua dang nhap hoac chua mua san pham thi khong hien nut, tranh
  /// truong hop bam vao roi bi may chu tu choi.
  Future<void> _refreshCanReview() async {
    final isLoggedIn = context.read<AuthProvider>().user != null;
    if (!isLoggedIn) {
      if (mounted && _canReview) setState(() => _canReview = false);
      return;
    }
    final allowed =
        await context.read<ReviewProvider>().checkCanReview(widget.productId);
    if (mounted && allowed != _canReview) {
      setState(() => _canReview = allowed);
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
            const SizedBox(width: AppSpacing.sm),
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
            if (_canReview)
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.sm,
                  ),
                  visualDensity: VisualDensity.compact,
                  side: BorderSide(color: c.secondary),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppTheme.radiusSm)),
                ),
                icon:
                    Icon(Icons.rate_review_rounded, size: 15, color: c.secondary),
                label: Text(
                  'Viết đánh giá',
                  style: TextStyle(
                      color: c.secondary,
                      fontSize: 12,
                      fontWeight: FontWeight.bold),
                ),
                onPressed: () => _openReviewForm(context),
              ),
          ],
        ),
        if (reviews.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.xs),
          Text(
            '${reviews.length} đánh giá đã xác thực',
            style: TextStyle(color: c.textMuted, fontSize: 12.5),
          ),
        ],
        const SizedBox(height: AppSpacing.md),
        if (provider.isLoadingProductFor(widget.productId) && reviews.isEmpty)
          const LoadingView()
        else if (reviews.isEmpty)
          _buildEmpty(c)
        else ...[
          _buildSummary(c, reviews),
          const SizedBox(height: AppSpacing.md),
          for (int i = 0; i < visibleReviews.length; i++) ...[
            if (i > 0)
              Divider(
                color: c.border.withValues(alpha: 0.6),
                height: AppSpacing.xxl,
              ),
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
    return const StatusView(
      icon: Icons.rate_review_outlined,
      title: 'Chưa có đánh giá nào',
      message: 'Hãy mua sản phẩm và chia sẻ cảm nhận kèm ảnh thực tế của bạn.',
    );
  }

  Widget _buildSummary(AppColors c, List<ReviewModel> reviews) {
    final average = reviews.fold<int>(0, (sum, review) => sum + review.rating) /
        reviews.length;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
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
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildStars(average.round(), 16),
                const SizedBox(height: AppSpacing.xs),
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
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildAvatar(review, c),
              const SizedBox(width: AppSpacing.md),
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
                    const SizedBox(height: AppSpacing.xs),
                    Row(
                      children: [
                        _buildStars(review.rating, 14),
                        const SizedBox(width: AppSpacing.sm),
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
            const SizedBox(height: AppSpacing.sm),
            Text(
              review.comment,
              style: TextStyle(
                  color: c.textSecondary, fontSize: 13.5, height: 1.5),
            ),
          ],
          if (review.images.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            ReviewImageGallery(images: review.images),
          ],
          if (review.replyComment != null &&
              review.replyComment!.trim().isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.md),
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
        child: AppImage(
          url: review.userAvatar ?? '',
          fit: BoxFit.cover,
          placeholder: (_) => fallback,
          errorWidget: (_) => fallback,
        ),
      ),
    );
  }

  Widget _buildStars(int rating, double size) {
    final c = AppColors.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (int i = 0; i < 5; i++)
          Icon(
            i < rating ? Icons.star_rounded : Icons.star_border_rounded,
            size: size,
            color: c.secondary,
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
