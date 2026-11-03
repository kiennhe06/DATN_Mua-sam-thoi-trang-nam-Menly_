import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:menly_app/core/theme/app_theme.dart';
import 'package:menly_app/features/wishlist/presentation/providers/wishlist_provider.dart';
import 'package:menly_app/features/product/presentation/providers/product_provider.dart';
import 'product_detail_page.dart';
import 'search_page.dart';

/// Man hinh danh sach san pham cao cap (AP-SP1: Loc, Tim kiem, Sap xep; AP-YT1: Nut trai tim)
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
                      const Text('Bộ lọc & Sắp xếp', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      TextButton(
                        onPressed: () {
                          prov.resetFilters();
                          Navigator.pop(ctx);
                        },
                        child: const Text('Thiết lập lại', style: TextStyle(color: AppTheme.accentRed)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Sap xep theo
                  const Text('Sắp xếp theo:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
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
                            style: TextStyle(color: isSelected ? Colors.white : AppTheme.textPrimary, fontSize: 12)),
                        selected: isSelected,
                        selectedColor: AppTheme.primary,
                        backgroundColor: Colors.grey.shade100,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        onSelected: (_) => setState(() => currentSort = item['key']!),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 20),

                  // Khoang gia
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Khoảng giá:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      Text(
                        '${currentRange.start.toInt()} đ - ${currentRange.end.toInt()} đ',
                        style: const TextStyle(color: AppTheme.accentRed, fontWeight: FontWeight.bold, fontSize: 13),
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
                    labels: RangeLabels('${currentRange.start.toInt()}', '${currentRange.end.toInt()}'),
                    onChanged: (values) => setState(() => currentRange = values),
                  ),
                  const SizedBox(height: 16),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: () {
                        prov.setSortBy(currentSort);
                        prov.setPriceRange(currentRange.start, currentRange.end);
                        Navigator.pop(ctx);
                      },
                      child: const Text('Áp dụng bộ lọc', style: TextStyle(fontWeight: FontWeight.bold)),
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
            child: const Text('Tìm kiếm', style: TextStyle(fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SearchPage())),
          ),
          TextButton(
            child: const Text('Lọc', style: TextStyle(fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
            onPressed: () => _showFilterModal(context, productProv),
          ),
        ],
      ),
      body: Column(
        children: [
          // Thanh danh muc chips cuon ngang (AP-SP1)
          Container(
            height: 50,
            color: Colors.white,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              itemCount: productProv.categories.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (ctx, i) {
                final cat = productProv.categories[i];
                final isSelected = productProv.selectedCategory == cat;
                return ChoiceChip(
                  label: Text(
                    cat,
                    style: TextStyle(
                      color: isSelected ? Colors.white : AppTheme.textPrimary,
                      fontSize: 13,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                  selected: isSelected,
                  selectedColor: AppTheme.primary,
                  backgroundColor: Colors.grey.shade100,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  onSelected: (_) => productProv.setCategory(cat),
                );
              },
            ),
          ),

          if (productProv.searchQuery.isNotEmpty || productProv.minPrice > 0 || productProv.maxPrice < 1000000)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              color: Colors.amber.shade50,
              child: Row(
                children: [

                  Expanded(
                    child: Text(
                      'Đang lọc: ${productProv.searchQuery.isNotEmpty ? '"${productProv.searchQuery}" • ' : ''}${productProv.products.length} kết quả',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                    ),
                  ),
                  TextButton(
                    onPressed: () => productProv.resetFilters(),
                    style: TextButton.styleFrom(visualDensity: VisualDensity.compact, padding: EdgeInsets.zero),
                    child: const Text('Bỏ lọc', style: TextStyle(fontSize: 12, color: AppTheme.accentRed)),
                  ),
                ],
              ),
            ),
          const Divider(height: 1),

          // Luoi san pham (AP-SP1)
          Expanded(
            child: productProv.isLoading
                ? const Center(child: CircularProgressIndicator())
                : productProv.products.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [

                            const Text('Không tìm thấy sản phẩm phù hợp',
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            childAspectRatio: 0.58,
                            crossAxisSpacing: 14,
                            mainAxisSpacing: 14,
                          ),
                          itemCount: productProv.products.length,
                          itemBuilder: (ctx, i) {
                            final p = productProv.products[i];
                            final isFav = wishlistProv.isFavorite(p.id);

                            return InkWell(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (_) => ProductDetailPage(product: p)),
                                );
                              },
                              borderRadius: BorderRadius.circular(14),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(color: AppTheme.border),
                                  boxShadow: AppTheme.softShadow,
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Anh san pham + Heart Icon (AP-YT1)
                                    Stack(
                                      children: [
                                        ClipRRect(
                                          borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
                                          child: Image.network(
                                            p.thumbnailUrl,
                                            height: 180,
                                            width: double.infinity,
                                            fit: BoxFit.cover,
                                            errorBuilder: (_, __, ___) => Container(
                                              height: 180,
                                              color: Colors.grey.shade100,
                                              alignment: Alignment.center, child: const Text("Menly", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.textMuted)),
                                            ),
                                          ),
                                        ),
                                        Positioned(
                                          top: 8,
                                          right: 8,
                                          child: CircleAvatar(
                                            radius: 15,
                                            backgroundColor: Colors.white.withValues(alpha: 0.95),
                                            child: IconButton(
                                              padding: EdgeInsets.zero,
                                              icon: Icon(
                                                isFav ? Icons.favorite : Icons.favorite_border,
                                                color: isFav ? AppTheme.accentRed : AppTheme.textPrimary,
                                                size: 16,
                                              ),
                                              onPressed: () => wishlistProv.toggleFavorite(p),
                                            ),
                                          ),
                                        ),
                                        if (p.isNew)
                                          Positioned(
                                            top: 8,
                                            left: 8,
                                            child: Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: AppTheme.primary,
                                                borderRadius: BorderRadius.circular(4),
                                              ),
                                              child: const Text('MỚI',
                                                  style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
                                            ),
                                          ),
                                      ],
                                    ),

                                    // Thong tin san pham
                                    Padding(
                                      padding: const EdgeInsets.all(10.0),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            p.categoryName.toUpperCase(),
                                            style: const TextStyle(fontSize: 10, color: AppTheme.textMuted, fontWeight: FontWeight.bold),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            p.name,
                                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, height: 1.2),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 6),
                                          Text(
                                            '${p.price} đ',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w900,
                                              color: AppTheme.accentRed,
                                              fontSize: 14,
                                            ),
                                          ),
                                          const SizedBox(height: 6),
                                          Row(
                                            children: [
                                              const Text('★ ', style: TextStyle(color: Colors.amber, fontSize: 12, fontWeight: FontWeight.bold)),
                                              Text(
                                                '${p.ratingAvg}',
                                                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                '(${p.ratingCount})',
                                                style: const TextStyle(fontSize: 11, color: AppTheme.textMuted),
                                              ),
                                            ],
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
                      ),
          ),
        ],
      ),
    );
  }
}
