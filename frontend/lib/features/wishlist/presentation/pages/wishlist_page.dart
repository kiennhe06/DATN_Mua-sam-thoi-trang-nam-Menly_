import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/product_card.dart';
import '../../../../core/widgets/state_views.dart';
import '../../../../core/navigation/main_navigation_shell.dart';
import '../../../cart/presentation/providers/cart_provider.dart';
import '../../../product/presentation/pages/product_detail_page.dart';
import '../../../product/presentation/providers/product_provider.dart';
import '../providers/wishlist_provider.dart';

/// Man hinh San pham Yeu thich cao cap (AP-YT1)
class WishlistPage extends StatelessWidget {
  const WishlistPage({super.key});

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final wishlist = context.watch<WishlistProvider>();

    return Scaffold(
      backgroundColor: c.background,
      appBar: AppBar(
        title: Text(
          'Sản phẩm yêu thích (${wishlist.count})',
          style: TextStyle(
            color: c.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        actions: [
          if (wishlist.favorites.isNotEmpty)
            TextButton(
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.sm,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusPill),
                ),
              ),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(AppTheme.radiusXl),
                    ),
                    title: const Text('Xác nhận xóa'),
                    content: const Text(
                        'Bạn có chắc muốn xóa tất cả sản phẩm khỏi danh sách yêu thích?'),
                    actions: [
                      TextButton(
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.lg,
                            vertical: AppSpacing.md,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(AppTheme.radiusPill),
                          ),
                        ),
                        onPressed: () => Navigator.pop(ctx),
                        child: Text(
                          'Hủy',
                          style: TextStyle(color: c.textSecondary),
                        ),
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: c.danger,
                          foregroundColor: c.onPrimary,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.xl,
                            vertical: AppSpacing.md,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(AppTheme.radiusPill),
                          ),
                        ),
                        onPressed: () {
                          wishlist.clearAll();
                          Navigator.pop(ctx);
                        },
                        child: const Text('Xóa hết'),
                      ),
                    ],
                  ),
                );
              },
              child: Text(
                'Xóa tất cả',
                style: TextStyle(
                  color: c.danger,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ),
        ],
      ),
      body: wishlist.favorites.isEmpty
          ? StatusView(
              icon: Icons.favorite_border,
              title: 'Chưa có sản phẩm yêu thích',
              message:
                  'Chạm vào biểu tượng trái tim để lưu lại những món đồ bạn yêu thích nhé!',
              actionLabel: 'Khám phá sản phẩm',
              onAction: () {
                const TabSwitchNotification(0).dispatch(context);
              },
            )
          : GridView.builder(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.lg,
                AppSpacing.lg,
                AppSpacing.xxxl,
              ),
              // Nhieu khoang trang giua cac the, giong luoi o trang chu.
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.5,
                crossAxisSpacing: AppSpacing.lg,
                mainAxisSpacing: AppSpacing.xl,
              ),
              itemCount: wishlist.favorites.length,
              itemBuilder: (ctx, i) {
                final p = wishlist.favorites[i];
                return ProductCard(
                  product: p,
                  isFavorite: true,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ProductDetailPage(product: p),
                      ),
                    );
                  },
                  onToggleFavorite: () {
                    wishlist.removeFavorite(p.id);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                            'Đã bỏ "${p.name}" khỏi danh sách yêu thích'),
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  },
                  onAdd: () async {
                    final cart = context.read<CartProvider>();
                    final productProv = context.read<ProductProvider>();
                    final messenger = ScaffoldMessenger.of(context);
                    // Chi chon bien the con hang tu chi tiet that, khong dung bien the bia
                    final detail = await productProv.fetchProductDetail(p.id);
                    final source = detail ?? p;
                    final availableVariants =
                        source.variants.where((variant) => variant.stock > 0);
                    if (availableVariants.isEmpty) {
                      messenger.showSnackBar(const SnackBar(
                        content: Text('Sản phẩm hiện không có hàng'),
                        duration: Duration(seconds: 2),
                      ));
                      return;
                    }
                    final variant = availableVariants.first;
                    final added = await cart.addToCart(source,
                        size: variant.size, color: variant.color);
                    messenger.showSnackBar(
                      SnackBar(
                        content: Text(added
                            ? 'Đã thêm "${p.name}" vào giỏ hàng'
                            : cart.errorMessage ??
                                'Không thể thêm sản phẩm vào giỏ'),
                        backgroundColor: added ? c.primary : c.danger,
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  },
                );
              },
            ),
    );
  }
}
