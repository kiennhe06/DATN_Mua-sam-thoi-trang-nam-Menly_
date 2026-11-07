import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:menly_app/core/theme/app_theme.dart';
import 'package:menly_app/core/widgets/category_pill.dart';
import 'package:menly_app/core/widgets/product_card.dart';
import 'package:menly_app/features/cart/presentation/providers/cart_provider.dart';
import 'package:menly_app/features/wishlist/presentation/providers/wishlist_provider.dart';
import 'package:menly_app/features/product/presentation/providers/product_provider.dart';
import 'product_detail_page.dart';
import 'search_page.dart';

/// Man hinh danh sach san pham cao cap Menly (AP-SP1: Loc, Tim kiem, Sap xep, Luoi 2 cot chu dong)
class ProductListPage extends StatelessWidget {
  const ProductListPage({super.key});

  void _showFilterModal(BuildContext context, ProductProvider prov) {
    String currentSort = prov.sortBy;
    RangeValues currentRange = RangeValues(prov.minPrice, prov.maxPrice);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setState) {
            return Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Bộ lọc & Sắp xếp',
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold)),
                      TextButton(
                        onPressed: () {
                          prov.resetFilters();
                          Navigator.pop(ctx);
                        },
                        child: const Text('Thiết lập lại',
                            style: TextStyle(color: AppTheme.accentRed)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Sap xep theo
                  const Text('Sắp xếp theo:',
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: [
                      {'key': 'newest', 'label': 'Mới nhất'},
                      {'key': 'best_seller', 'label': 'Bán chạy nhất'},
                      {'key': 'price_asc', 'label': 'Giá tăng dần'},
                      {'key': 'price_desc', 'label': 'Giá giảm dần'},
                    ].map((item) {
                      final isSelected = currentSort == item['key'];
                      return ChoiceChip(
                        label: Text(item['label']!,
                            style: TextStyle(
                                color: isSelected
                                    ? Colors.white
                                    : AppTheme.textPrimary,
                                fontSize: 12)),
                        selected: isSelected,
                        selectedColor: AppTheme.primary,
                        backgroundColor: Colors.grey.shade100,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                        onSelected: (_) =>
                            setState(() => currentSort = item['key']!),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 20),

                  // Khoang gia
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Khoảng giá:',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 14)),
                      Text(
                        '${currentRange.start.toInt()} đ - ${currentRange.end.toInt()} đ',
                        style: const TextStyle(
                            color: AppTheme.accentRed,
                            fontWeight: FontWeight.bold,
                            fontSize: 13),
                      ),
                    ],
                  ),
                  RangeSlider(
                    values: currentRange,
                    min: 0,
                    max: 1000000,
                    divisions: 20,
                    activeColor: AppTheme.primary,
                    inactiveColor: Colors.grey.shade300,
                    labels: RangeLabels('${currentRange.start.toInt()}',
                        '${currentRange.end.toInt()}'),
                    onChanged: (values) =>
                        setState(() => currentRange = values),
                  ),
                  const SizedBox(height: 16),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: () {
                        prov.setSortBy(currentSort);
                        prov.setPriceRange(
                            currentRange.start, currentRange.end);
                        Navigator.pop(ctx);
                      },
                      child: const Text('Áp dụng bộ lọc',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final productProv = context.watch<ProductProvider>();
    final wishlistProv = context.watch<WishlistProvider>();

    return Scaffold(
      backgroundColor: AppTheme.scaffoldBackground,
      appBar: AppBar(
        title: const Text('Sản phẩm Menly'),
        centerTitle: true,
        actions: [
          TextButton(
            child: const Text('Tìm kiếm',
                style: TextStyle(
                    fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
            onPressed: () => Navigator.push(
                context, MaterialPageRoute(builder: (_) => const SearchPage())),
          ),
          TextButton(
            child: const Text('Lọc',
                style: TextStyle(
                    fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
            onPressed: () => _showFilterModal(context, productProv),
          ),
        ],
      ),
      body: Column(
        children: [
          // Thanh danh muc chips cuon ngang (AP-SP1)
          Container(
            height: 48,
            color: Colors.white,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              itemCount: productProv.categories.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (ctx, i) {
                final cat = productProv.categories[i];
                final isSelected = productProv.selectedCategory == cat;
                return CategoryPill(
                  label: cat,
                  selected: isSelected,
                  onTap: () => productProv.setCategory(cat),
                );
              },
            ),
          ),

          if (productProv.searchQuery.isNotEmpty ||
              productProv.minPrice > 0 ||
              productProv.maxPrice < 1000000)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              color: Colors.amber.shade50,
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Đang lọc: ${productProv.searchQuery.isNotEmpty ? '"${productProv.searchQuery}" • ' : ''}${productProv.products.length} kết quả',
                      style: const TextStyle(
                          fontSize: 12, fontWeight: FontWeight.w500),
                    ),
                  ),
                  TextButton(
                    onPressed: () => productProv.resetFilters(),
                    style: TextButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                        padding: EdgeInsets.zero),
                    child: const Text('Bỏ lọc',
                        style:
                            TextStyle(fontSize: 12, color: AppTheme.accentRed)),
                  ),
                ],
              ),
            ),
          const Divider(height: 1),

          // Luoi 2 cot san pham chuan UI/UX
          Expanded(
            child: productProv.isLoading
                ? const Center(child: CircularProgressIndicator())
                : productProv.products.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text('Không tìm thấy sản phẩm phù hợp',
                                style: TextStyle(
                                    fontSize: 16, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 8),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.primary,
                                foregroundColor: Colors.white,
                              ),
                              onPressed: () => productProv.resetFilters(),
                              child: const Text('Xem tất cả sản phẩm'),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: () => productProv.loadProducts(),
                        child: GridView.builder(
                          padding: const EdgeInsets.all(14),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            childAspectRatio: 0.65,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                          ),
                          itemCount: productProv.products.length,
                          itemBuilder: (ctx, i) {
                            final p = productProv.products[i];
                            final isFav = wishlistProv.isFavorite(p.id);

                            return ProductCard(
                              product: p,
                              isFavorite: isFav,
                              badge: p.isNew
                                  ? 'MỚI'
                                  : (p.isBestSeller ? 'HOT' : null),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (_) =>
                                          ProductDetailPage(product: p)),
                                );
                              },
                              onToggleFavorite: () =>
                                  wishlistProv.toggleFavorite(p),
                              onAdd: () async {
                                final cart = context.read<CartProvider>();
                                final messenger =
                                    ScaffoldMessenger.of(context);
                                final detail =
                                    await productProv.fetchProductDetail(p.id);
                                final source = detail ?? p;
                                final availableVariants = source.variants
                                    .where((variant) => variant.stock > 0);
                                if (availableVariants.isEmpty) {
                                  messenger.showSnackBar(const SnackBar(
                                      content: Text(
                                          'Sản phẩm hiện không có hàng')));
                                  return;
                                }
                                final variant = availableVariants.first;
                                final added = await cart.addToCart(source,
                                    size: variant.size, color: variant.color);
                                messenger.showSnackBar(SnackBar(
                                    content: Text(added
                                        ? 'Đã thêm "${p.name}" vào giỏ'
                                        : cart.errorMessage ??
                                            'Không thể thêm sản phẩm vào giỏ')));
                              },
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}
