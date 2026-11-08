import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:menly_app/core/utils/format.dart';
import 'package:menly_app/core/theme/app_theme.dart';
import 'package:menly_app/core/widgets/category_tab.dart';
import 'package:menly_app/core/widgets/product_card.dart';
import 'package:menly_app/features/cart/presentation/providers/cart_provider.dart';
import 'package:menly_app/features/wishlist/presentation/providers/wishlist_provider.dart';
import 'package:menly_app/features/product/presentation/providers/product_provider.dart';
import 'product_detail_page.dart';
import 'search_page.dart';

/// Man hinh danh sach san pham cao cap Menly (AP-SP1: Loc, Tim kiem, Sap xep, Luoi 2 cot chu dong)
class ProductListPage extends StatelessWidget {
  const ProductListPage({super.key});

  Widget _buildFilterContainer({
    required String title,
    Widget? trailing,
    required Widget child,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: AppTheme.textPrimary,
                ),
              ),
              if (trailing != null) trailing,
            ],
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }

  Widget _buildFilterBadgeChip({
    required String label,
    required VoidCallback onDeleted,
  }) {
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: Chip(
        label: Text(label,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500)),
        deleteIcon: const Icon(Icons.close, size: 14),
        onDeleted: onDeleted,
        visualDensity: VisualDensity.compact,
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        backgroundColor: Colors.white,
        side: BorderSide(color: Colors.amber.shade300),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        padding: const EdgeInsets.symmetric(horizontal: 4),
      ),
    );
  }

  void _showFilterModal(BuildContext context, ProductProvider prov) {
    String currentSort = prov.sortBy;
    RangeValues currentRange = RangeValues(prov.minPrice, prov.maxPrice);
    String currentClassification = prov.classification;
    String? currentSize = prov.selectedSize;
    String? currentColor = prov.selectedColor;
    double currentMinRating = prov.minRating;
    bool currentOnlyInStock = prov.onlyInStock;

    final colorOptions = [
      {'label': 'Tất cả', 'color': null},
      {'label': 'Đen', 'color': const Color(0xFF1E293B)},
      {'label': 'Trắng', 'color': const Color(0xFFFFFFFF), 'border': true},
      {'label': 'Xanh / Navy', 'color': const Color(0xFF1E3A8A)},
      {'label': 'Xám', 'color': const Color(0xFF6B7280)},
      {'label': 'Be / Nâu', 'color': const Color(0xFF8D6E63)},
      {'label': 'Xanh rêu', 'color': const Color(0xFF4B6F44)},
      {'label': 'Khác', 'color': const Color(0xFFE11D48)},
    ];

    final sizeOptions = ['Tất cả', 'S', 'M', 'L', 'XL', 'XXL'];

    final ratingOptions = [
      {'value': 0.0, 'label': 'Tất cả'},
      {'value': 4.0, 'label': '4.0★ trở lên'},
      {'value': 4.5, 'label': '4.5★ trở lên'},
      {'value': 5.0, 'label': '5.0★'},
    ];

    final classificationOptions = [
      {'key': 'all', 'label': 'Tất cả'},
      {'key': 'new', 'label': 'Hàng mới (NEW)'},
      {'key': 'best_seller', 'label': 'Bán chạy (HOT)'},
    ];

    final sortOptions = [
      {'key': 'newest', 'label': 'Mới nhất'},
      {'key': 'best_seller', 'label': 'Bán chạy nhất'},
      {'key': 'rating_desc', 'label': 'Đánh giá cao nhất'},
      {'key': 'price_asc', 'label': 'Giá tăng dần'},
      {'key': 'price_desc', 'label': 'Giá giảm dần'},
    ];

    final quickPrices = [
      {'label': 'Dưới 200k', 'min': 0.0, 'max': 200000.0},
      {'label': '200k - 350k', 'min': 200000.0, 'max': 350000.0},
      {'label': '350k - 500k', 'min': 350000.0, 'max': 500000.0},
      {'label': 'Trên 500k', 'min': 500000.0, 'max': 1000000.0},
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setState) {
            final matchCount = prov.countFilteredProducts(
              sort: currentSort,
              minPrice: currentRange.start,
              maxPrice: currentRange.end,
              classification: currentClassification,
              size: currentSize,
              color: currentColor,
              minRating: currentMinRating,
              onlyInStock: currentOnlyInStock,
            );

            return SizedBox(
              height: MediaQuery.of(context).size.height * 0.85,
              child: Column(
                children: [
                  // Header
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 12, 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Bộ lọc sản phẩm',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        Row(
                          children: [
                            TextButton(
                              onPressed: () {
                                setState(() {
                                  currentSort = 'newest';
                                  currentRange = const RangeValues(0, 1000000);
                                  currentClassification = 'all';
                                  currentSize = null;
                                  currentColor = null;
                                  currentMinRating = 0.0;
                                  currentOnlyInStock = false;
                                });
                              },
                              child: const Text('Thiết lập lại',
                                  style: TextStyle(
                                      color: AppTheme.accentRed,
                                      fontWeight: FontWeight.w600)),
                            ),
                            IconButton(
                              icon: const Icon(Icons.close_rounded),
                              onPressed: () => Navigator.pop(ctx),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),

                  // Scrollable filter contents
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      children: [
                        // 1. Phan loai san pham
                        _buildFilterContainer(
                          title: 'Phân loại sản phẩm',
                          child: Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: classificationOptions.map((item) {
                              final isSelected =
                                  currentClassification == item['key'];
                              return ChoiceChip(
                                label: Text(item['label']!),
                                selected: isSelected,
                                selectedColor: AppTheme.primary,
                                checkmarkColor: Colors.white,
                                labelStyle: TextStyle(
                                  color: isSelected
                                      ? Colors.white
                                      : AppTheme.textPrimary,
                                  fontWeight: isSelected
                                      ? FontWeight.w600
                                      : FontWeight.w500,
                                  fontSize: 13,
                                ),
                                backgroundColor: Colors.white,
                                side: BorderSide(
                                  color: isSelected
                                      ? AppTheme.primary
                                      : const Color(0xFFE5E7EB),
                                ),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10)),
                                onSelected: (_) => setState(() =>
                                    currentClassification = item['key']!),
                              );
                            }).toList(),
                          ),
                        ),

                        // 2. Kich co (Size)
                        _buildFilterContainer(
                          title: 'Kích cỡ (Size)',
                          child: Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: sizeOptions.map((sz) {
                              final isSelected =
                                  (currentSize == null && sz == 'Tất cả') ||
                                      (currentSize != null && currentSize == sz);
                              return ChoiceChip(
                                label: Text(sz),
                                selected: isSelected,
                                selectedColor: AppTheme.primary,
                                checkmarkColor: Colors.white,
                                labelStyle: TextStyle(
                                  color: isSelected
                                      ? Colors.white
                                      : AppTheme.textPrimary,
                                  fontWeight: isSelected
                                      ? FontWeight.w600
                                      : FontWeight.w500,
                                  fontSize: 13,
                                ),
                                backgroundColor: Colors.white,
                                side: BorderSide(
                                  color: isSelected
                                      ? AppTheme.primary
                                      : const Color(0xFFE5E7EB),
                                ),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10)),
                                onSelected: (_) => setState(() {
                                  currentSize = (sz == 'Tất cả') ? null : sz;
                                }),
                              );
                            }).toList(),
                          ),
                        ),

                        // 3. Mau sac
                        _buildFilterContainer(
                          title: 'Màu sắc',
                          child: Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: colorOptions.map((c) {
                              final label = c['label'] as String;
                              final col = c['color'] as Color?;
                              final hasBorder = c['border'] == true;
                              final isSelected =
                                  (currentColor == null && label == 'Tất cả') ||
                                      (currentColor != null &&
                                          currentColor == label);

                              return ChoiceChip(
                                avatar: col != null
                                    ? Container(
                                        width: 16,
                                        height: 16,
                                        decoration: BoxDecoration(
                                          color: col,
                                          shape: BoxShape.circle,
                                          border: hasBorder
                                              ? Border.all(
                                                  color: Colors.grey.shade400,
                                                  width: 1)
                                              : null,
                                        ),
                                      )
                                    : null,
                                label: Text(label),
                                selected: isSelected,
                                selectedColor: AppTheme.primary,
                                checkmarkColor: Colors.white,
                                labelStyle: TextStyle(
                                  color: isSelected
                                      ? Colors.white
                                      : AppTheme.textPrimary,
                                  fontWeight: isSelected
                                      ? FontWeight.w600
                                      : FontWeight.w500,
                                  fontSize: 13,
                                ),
                                backgroundColor: Colors.white,
                                side: BorderSide(
                                  color: isSelected
                                      ? AppTheme.primary
                                      : const Color(0xFFE5E7EB),
                                ),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10)),
                                onSelected: (_) => setState(() {
                                  currentColor =
                                      (label == 'Tất cả') ? null : label;
                                }),
                              );
                            }).toList(),
                          ),
                        ),

                        // 4. Danh gia sao
                        _buildFilterContainer(
                          title: 'Đánh giá sao',
                          child: Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: ratingOptions.map((r) {
                              final val = r['value'] as double;
                              final label = r['label'] as String;
                              final isSelected = currentMinRating == val;
                              return ChoiceChip(
                                avatar: val > 0
                                    ? const Icon(Icons.star_rounded,
                                        size: 16, color: Colors.amber)
                                    : null,
                                label: Text(label),
                                selected: isSelected,
                                selectedColor: AppTheme.primary,
                                checkmarkColor: Colors.white,
                                labelStyle: TextStyle(
                                  color: isSelected
                                      ? Colors.white
                                      : AppTheme.textPrimary,
                                  fontWeight: isSelected
                                      ? FontWeight.w600
                                      : FontWeight.w500,
                                  fontSize: 13,
                                ),
                                backgroundColor: Colors.white,
                                side: BorderSide(
                                  color: isSelected
                                      ? AppTheme.primary
                                      : const Color(0xFFE5E7EB),
                                ),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10)),
                                onSelected: (_) =>
                                    setState(() => currentMinRating = val),
                              );
                            }).toList(),
                          ),
                        ),

                        // 5. Tinh trang hang
                        _buildFilterContainer(
                          title: 'Tình trạng hàng',
                          child: SwitchListTile(
                            contentPadding: EdgeInsets.zero,
                            title: const Text('Chỉ hiện sản phẩm còn hàng',
                                style: TextStyle(
                                    fontWeight: FontWeight.w600, fontSize: 14)),
                            subtitle: const Text(
                                'Ẩn các sản phẩm và biến thể đã hết hàng',
                                style: TextStyle(
                                    fontSize: 12, color: Colors.grey)),
                            value: currentOnlyInStock,
                            activeThumbColor: AppTheme.primary,
                            onChanged: (val) =>
                                setState(() => currentOnlyInStock = val),
                          ),
                        ),

                        // 6. Khoang gia
                        _buildFilterContainer(
                          title: 'Khoảng giá',
                          trailing: Text(
                            '${formatPrice(currentRange.start)} - ${formatPrice(currentRange.end)}',
                            style: const TextStyle(
                                color: AppTheme.accentRed,
                                fontWeight: FontWeight.bold,
                                fontSize: 13),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: quickPrices.map((qp) {
                                  final qpMin = qp['min'] as double;
                                  final qpMax = qp['max'] as double;
                                  final isSelected = currentRange.start == qpMin &&
                                      currentRange.end == qpMax;
                                  return ActionChip(
                                    label: Text(qp['label'] as String),
                                    backgroundColor: isSelected
                                        ? AppTheme.primary.withValues(alpha: 0.12)
                                        : Colors.white,
                                    labelStyle: TextStyle(
                                      color: isSelected
                                          ? AppTheme.primary
                                          : AppTheme.textPrimary,
                                      fontWeight: isSelected
                                          ? FontWeight.w600
                                          : FontWeight.normal,
                                      fontSize: 12,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      side: BorderSide(
                                        color: isSelected
                                            ? AppTheme.primary
                                            : const Color(0xFFE5E7EB),
                                      ),
                                    ),
                                    onPressed: () => setState(() {
                                      currentRange = RangeValues(qpMin, qpMax);
                                    }),
                                  );
                                }).toList(),
                              ),
                              const SizedBox(height: 8),
                              RangeSlider(
                                values: currentRange,
                                min: 0,
                                max: 1000000,
                                divisions: 20,
                                activeColor: AppTheme.primary,
                                inactiveColor: Colors.grey.shade300,
                                labels: RangeLabels(
                                  formatPrice(currentRange.start),
                                  formatPrice(currentRange.end),
                                ),
                                onChanged: (values) =>
                                    setState(() => currentRange = values),
                              ),
                            ],
                          ),
                        ),

                        // 7. Sap xep theo
                        _buildFilterContainer(
                          title: 'Sắp xếp theo',
                          child: Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: sortOptions.map((item) {
                              final isSelected = currentSort == item['key'];
                              return ChoiceChip(
                                label: Text(item['label']!),
                                selected: isSelected,
                                selectedColor: AppTheme.primary,
                                checkmarkColor: Colors.white,
                                labelStyle: TextStyle(
                                  color: isSelected
                                      ? Colors.white
                                      : AppTheme.textPrimary,
                                  fontWeight: isSelected
                                      ? FontWeight.w600
                                      : FontWeight.w500,
                                  fontSize: 13,
                                ),
                                backgroundColor: Colors.white,
                                side: BorderSide(
                                  color: isSelected
                                      ? AppTheme.primary
                                      : const Color(0xFFE5E7EB),
                                ),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10)),
                                onSelected: (_) =>
                                    setState(() => currentSort = item['key']!),
                              );
                            }).toList(),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Bottom action bar
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.06),
                          blurRadius: 10,
                          offset: const Offset(0, -3),
                        ),
                      ],
                    ),
                    child: SafeArea(
                      top: false,
                      child: SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                          onPressed: () {
                            prov.applyAdvancedFilters(
                              sort: currentSort,
                              minPrice: currentRange.start,
                              maxPrice: currentRange.end,
                              classification: currentClassification,
                              size: currentSize,
                              color: currentColor,
                              minRating: currentMinRating,
                              onlyInStock: currentOnlyInStock,
                            );
                            Navigator.pop(ctx);
                          },
                          child: Text(
                            'Xem $matchCount sản phẩm phù hợp',
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 15),
                          ),
                        ),
                      ),
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
          IconButton(
            tooltip: 'Tìm kiếm',
            icon: const Icon(Icons.search_rounded),
            onPressed: () => Navigator.push(
                context, MaterialPageRoute(builder: (_) => const SearchPage())),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: TextButton.icon(
              icon: Badge(
                isLabelVisible: productProv.activeFilterCount > 0,
                label: Text('${productProv.activeFilterCount}',
                    style: const TextStyle(
                        fontSize: 10, fontWeight: FontWeight.bold)),
                backgroundColor: AppTheme.accentRed,
                child: const Icon(Icons.tune_rounded, size: 18),
              ),
              label: const Text('Lọc',
                  style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary)),
              onPressed: () => _showFilterModal(context, productProv),
            ),
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
              separatorBuilder: (_, __) => const SizedBox(width: 20),
              itemBuilder: (ctx, i) {
                final cat = productProv.categories[i];
                final isSelected = productProv.selectedCategory == cat;
                return CategoryTab(
                  label: cat,
                  selected: isSelected,
                  onTap: () => productProv.setCategory(cat),
                );
              },
            ),
          ),

          if (productProv.activeFilterCount > 0 ||
              productProv.searchQuery.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              color: Colors.amber.shade50,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Bộ lọc đang dùng (${productProv.products.length} sản phẩm):',
                        style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textPrimary),
                      ),
                      GestureDetector(
                        onTap: () => productProv.resetFilters(),
                        child: const Text('Xóa tất cả',
                            style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.accentRed)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        if (productProv.searchQuery.isNotEmpty)
                          _buildFilterBadgeChip(
                            label: '"${productProv.searchQuery}"',
                            onDeleted: () => productProv.clearSearchQuery(),
                          ),
                        if (productProv.selectedCategory != 'Tất cả')
                          _buildFilterBadgeChip(
                            label: 'DM: ${productProv.selectedCategory}',
                            onDeleted: () => productProv.clearCategory(),
                          ),
                        if (productProv.classification == 'new')
                          _buildFilterBadgeChip(
                            label: 'Hàng mới',
                            onDeleted: () =>
                                productProv.clearClassificationFilter(),
                          ),
                        if (productProv.classification == 'best_seller')
                          _buildFilterBadgeChip(
                            label: 'Bán chạy',
                            onDeleted: () =>
                                productProv.clearClassificationFilter(),
                          ),
                        if (productProv.selectedSize != null)
                          _buildFilterBadgeChip(
                            label: 'Size: ${productProv.selectedSize}',
                            onDeleted: () => productProv.clearSizeFilter(),
                          ),
                        if (productProv.selectedColor != null)
                          _buildFilterBadgeChip(
                            label: 'Màu: ${productProv.selectedColor}',
                            onDeleted: () => productProv.clearColorFilter(),
                          ),
                        if (productProv.minRating > 0)
                          _buildFilterBadgeChip(
                            label:
                                '⭐ ${productProv.minRating.toStringAsFixed(1)}+',
                            onDeleted: () => productProv.clearRatingFilter(),
                          ),
                        if (productProv.onlyInStock)
                          _buildFilterBadgeChip(
                            label: 'Còn hàng',
                            onDeleted: () => productProv.clearStockFilter(),
                          ),
                        if (productProv.minPrice > 0 ||
                            productProv.maxPrice < 1000000)
                          _buildFilterBadgeChip(
                            label:
                                '${formatPrice(productProv.minPrice)} - ${formatPrice(productProv.maxPrice)}',
                            onDeleted: () => productProv.clearPriceFilter(),
                          ),
                      ],
                    ),
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
                            childAspectRatio: 0.5,
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
