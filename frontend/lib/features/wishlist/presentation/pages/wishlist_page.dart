import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_buttons.dart';
import '../../../../core/widgets/product_card.dart';
import '../../../../main.dart';
import '../../../cart/presentation/providers/cart_provider.dart';
import '../../../product/presentation/pages/product_detail_page.dart';
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
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Xác nhận xóa'),
                    content: const Text(
                        'Bạn có chắc muốn xóa tất cả sản phẩm khỏi danh sách yêu thích?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: Text(
                          'Hủy',
                          style: TextStyle(color: c.textSecondary),
                        ),
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: c.danger,
                          foregroundColor: Colors.white,
                          elevation: 0,
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
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: c.surfaceVariant,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Icon(
                          Icons.favorite_border,
                          size: 38,
                          color: c.textMuted,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Chưa có sản phẩm yêu thích',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: c.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Chạm vào biểu tượng trái tim để lưu lại những món đồ bạn yêu thích nhé!',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: c.textSecondary,
                        fontSize: 13.5,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 28),
                    PrimaryButton(
                      label: 'Khám phá sản phẩm',
                      expanded: false,
                      onPressed: () {
                        const TabSwitchNotification(0).dispatch(context);
                      },
                    ),
                  ],
                ),
              ),
            )
          : GridView.builder(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.5,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
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
                    final messenger = ScaffoldMessenger.of(context);
                    // Chi chon bien the con hang, va bao dung ket qua that
                    final availableVariants =
                        p.variants.where((variant) => variant.stock > 0);
                    if (availableVariants.isEmpty) {
                      messenger.showSnackBar(const SnackBar(
                        content: Text('Sản phẩm hiện không có hàng'),
                        duration: Duration(seconds: 2),
                      ));
                      return;
                    }
                    final variant = availableVariants.first;
                    final added = await cart.addToCart(p,
                        size: variant.size, color: variant.color);
                    messenger.showSnackBar(SnackBar(
                      content: Text(added
                          ? 'Đã thêm "${p.name}" vào giỏ hàng'
                          : cart.errorMessage ??
                              'Không thể thêm sản phẩm vào giỏ'),
                      backgroundColor: added ? c.primary : null,
                      duration: const Duration(seconds: 2),
                    ));
                  },
                );
              },
            ),
    );
  }
}
