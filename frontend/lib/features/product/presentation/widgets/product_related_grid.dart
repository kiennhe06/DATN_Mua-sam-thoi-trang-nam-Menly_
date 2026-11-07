import 'package:flutter/material.dart';
import '../../../../core/utils/format.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/product_rating_row.dart';
import '../../../wishlist/presentation/providers/wishlist_provider.dart';
import '../../data/models/product_model.dart';
import '../pages/product_detail_page.dart';

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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Sản phẩm liên quan',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
        ),
        const SizedBox(height: 4),
        Text(
          'Gợi ý cùng danh mục với ${product.categoryName.isNotEmpty ? product.categoryName : 'sản phẩm này'}',
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
        ),
        const SizedBox(height: 14),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: relatedProducts.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 0.65,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
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
              borderRadius: BorderRadius.circular(12),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Stack(
                      children: [
                        ClipRRect(
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(12),
                          ),
                          child: Image.network(
                            related.thumbnailUrl,
                            width: double.infinity,
                            height: 180,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              width: double.infinity,
                              height: 180,
                              color: Colors.grey.shade200,
                              child: const Center(
                                child: Text(
                                  'Menly',
                                  style: TextStyle(
                                    color: Colors.grey,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          top: 8,
                          right: 8,
                          child: CircleAvatar(
                            radius: 14,
                            backgroundColor:
                                Colors.white.withValues(alpha: 0.9),
                            child: IconButton(
                              padding: EdgeInsets.zero,
                              icon: Icon(
                                isFav ? Icons.favorite : Icons.favorite_border,
                                color: isFav
                                    ? AppTheme.accentRed
                                    : AppTheme.textPrimary,
                                size: 16,
                              ),
                              onPressed: () => wishlist.toggleFavorite(related),
                            ),
                          ),
                        ),
                      ],
                    ),
                    Padding(
                      padding: const EdgeInsets.all(10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            related.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          ProductRatingRow(
                            ratingAvg: related.ratingAvg,
                            ratingCount: related.ratingCount,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            formatPrice(related.price),
                            style: const TextStyle(
                              color: AppTheme.accentRed,
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

