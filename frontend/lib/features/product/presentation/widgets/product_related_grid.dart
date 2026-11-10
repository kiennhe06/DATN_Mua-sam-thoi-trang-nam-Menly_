import 'package:flutter/material.dart';
import '../../../../core/utils/format.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/product_rating_row.dart';
import '../../../../core/widgets/section_header.dart';
import '../../../wishlist/presentation/providers/wishlist_provider.dart';
import '../../data/models/product_model.dart';
import '../pages/product_detail_page.dart';
import 'package:menly_app/core/widgets/app_image.dart';

class ProductRelatedGrid extends StatelessWidget {
  final ProductModel product;
  final List<ProductModel> relatedProducts;
  final WishlistProvider wishlist;

  const ProductRelatedGrid({
    super.key,
    required this.product,
    required this.relatedProducts,
    required this.wishlist,
  });

  @override
  Widget build(BuildContext context) {
    if (relatedProducts.isEmpty) return const SizedBox.shrink();

    final c = AppColors.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(title: 'Sản phẩm liên quan'),
        const SizedBox(height: AppSpacing.xs),
        Text(
          'Gợi ý cùng danh mục với ${product.categoryName.isNotEmpty ? product.categoryName : 'sản phẩm này'}',
          style: TextStyle(fontSize: 12, color: c.textSecondary),
        ),
        const SizedBox(height: AppSpacing.lg),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: relatedProducts.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 0.5,
            crossAxisSpacing: AppSpacing.md,
            mainAxisSpacing: AppSpacing.md,
          ),
          itemBuilder: (ctx, i) {
            final related = relatedProducts[i];
            final isFav = wishlist.isFavorite(related.id);

            return InkWell(
              onTap: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ProductDetailPage(product: related),
                  ),
                );
              },
              borderRadius: BorderRadius.circular(AppTheme.radiusXl),
              child: Container(
                decoration: BoxDecoration(
                  color: c.surface,
                  // Bo goc manh cho khop voi anh trong ProductCard
                  borderRadius: BorderRadius.circular(AppTheme.radiusXl),
                  border: Border.all(color: c.border),
                  boxShadow: [
                    BoxShadow(
                      color: c.shadow,
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Anh nhan phan chieu cao con lai cua o luoi thay vi cao
                    // co dinh 180: o luoi cao gap doi be rong (ty le 0.5) nen
                    // anh co dinh de lai mot mang trang lon duoi gia.
                    Expanded(
                      child: Stack(
                        children: [
                        ClipRRect(
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(AppTheme.radiusXl),
                          ),
                          child: AppImage(
                            url: related.thumbnailUrl,
                            width: double.infinity,
                            height: double.infinity,
                            fit: BoxFit.cover,
                            placeholder: (_) => Container(
                              width: double.infinity,
                              color: c.surfaceVariant,
                            ),
                            errorWidget: (_) => Container(
                              width: double.infinity,
                              color: c.surfaceVariant,
                              child: Center(
                                child: Text(
                                  'Menly',
                                  style: TextStyle(
                                    color: c.textMuted,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          top: AppSpacing.sm,
                          right: AppSpacing.sm,
                          child: CircleAvatar(
                            radius: 14,
                            backgroundColor: c.surface.withValues(alpha: 0.9),
                            child: IconButton(
                              padding: EdgeInsets.zero,
                              icon: Icon(
                                isFav ? Icons.favorite : Icons.favorite_border,
                                color: isFav ? c.danger : c.textPrimary,
                                size: 16,
                              ),
                              onPressed: () => wishlist.toggleFavorite(related),
                            ),
                          ),
                        ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            related.name,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: c.textPrimary,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          ProductRatingRow(
                            ratingAvg: related.ratingAvg,
                            ratingCount: related.ratingCount,
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          Text(
                            formatPrice(related.price),
                            style: TextStyle(
                              color: c.danger,
                              fontWeight: FontWeight.w900,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

