import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:menly_app/core/utils/format.dart';
import 'package:menly_app/core/theme/app_colors.dart';
import 'package:menly_app/core/theme/app_spacing.dart';
import 'package:menly_app/core/theme/app_theme.dart';
import 'package:menly_app/core/widgets/app_buttons.dart';
import 'package:menly_app/core/widgets/category_tab.dart';
import 'package:menly_app/core/widgets/product_card.dart';
import 'package:menly_app/core/widgets/state_views.dart';
import 'package:menly_app/features/cart/presentation/providers/cart_provider.dart';
import 'package:menly_app/features/wishlist/presentation/providers/wishlist_provider.dart';
import 'package:menly_app/features/product/presentation/providers/product_provider.dart';
import 'product_detail_page.dart';
import 'search_page.dart';

/// Man hinh danh sach san pham cao cap Menly (AP-SP1: Loc, Tim kiem, Sap xep, Luoi 2 cot chu dong)
class ProductListPage extends StatelessWidget {
  const ProductListPage({super.key});

  Widget _buildFilterContainer({
    required AppColors c,
    required String title,
    Widget? trailing,
    required Widget child,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.lg),
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: c.surfaceVariant,
        borderRadius: BorderRadius.circular(AppTheme.radiusCard),
        border: Border.all(color: c.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: c.textPrimary,
                ),
              ),
              if (trailing != null) trailing,
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          child,
        ],
      ),
    );
  }

  Widget _buildFilterBadgeChip({
    required AppColors c,
    required String label,
    required VoidCallback onDeleted,
  }) {
    return Padding(
      padding: const EdgeInsets.only(right: AppSpacing.sm),
      child: Chip(
        label: Text(label,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500)),
        deleteIcon: const Icon(Icons.close, size: 14),
        onDeleted: onDeleted,
        visualDensity: VisualDensity.compact,
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        backgroundColor: c.surface,
        side: BorderSide(color: c.secondary),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusLg)),
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
      ),
    );
  }

  void _showFilterModal(BuildContext context, ProductProvider prov) {
    final c = AppColors.of(context);
    String currentSort = prov.sortBy;
    RangeValues currentRange = RangeValues(prov.minPrice, prov.maxPrice);
    String currentClassification = prov.classification;
    String? currentSize = prov.selectedSize;
    String? currentColor = prov.selectedColor;
    double currentMinRating = prov.minRating;
    bool currentOnlyInStock = prov.onlyInStock;

    // Mau san pham that (den, trang, navy...), khong phai mau giao dien nen
    // giu nguyen ma mau thay vi doi sang token.
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
      backgroundColor: c.surface,
      shape: const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(AppTheme.radiusXl)),
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
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.xl,
                      AppSpacing.lg,
                      AppSpacing.md,
                      AppSpacing.md,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Bộ lọc sản phẩm',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: c.textPrimary,
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
                              child: Text('Thiết lập lại',
                                  style: TextStyle(
                                      color: c.danger,
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
                        horizontal: AppSpacing.lg,
                        vertical: AppSpacing.md,
                      ),
                      children: [
                        // 1. Phan loai san pham
                        _buildFilterContainer(
                          c: c,
                          title: 'Phân loại sản phẩm',
                          child: Wrap(
                            spacing: AppSpacing.sm,
                            runSpacing: AppSpacing.sm,
                            children: classificationOptions.map((item) {
                              final isSelected =
                                  currentClassification == item['key'];
                              return ChoiceChip(
                                label: Text(item['label']!),
                                selected: isSelected,
                                selectedColor: c.primary,
                                checkmarkColor: c.onPrimary,
                                labelStyle: TextStyle(
                                  color:
                                      isSelected ? c.onPrimary : c.textPrimary,
                                  fontWeight: isSelected
                                      ? FontWeight.w600
                                      : FontWeight.w500,
                                  fontSize: 13,
                                ),
                                backgroundColor: c.surface,
                                side: BorderSide(
                                  color: isSelected ? c.primary : c.border,
                                ),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(
                                        AppTheme.radiusSm)),
                                onSelected: (_) => setState(() =>
                                    currentClassification = item['key']!),
                              );
                            }).toList(),
                          ),
                        ),

                        // 2. Kich co (Size)
                        _buildFilterContainer(
                          c: c,
                          title: 'Kích cỡ (Size)',
                          child: Wrap(
                            spacing: AppSpacing.sm,
                            runSpacing: AppSpacing.sm,
                            children: sizeOptions.map((sz) {
                              final isSelected =
                                  (currentSize == null && sz == 'Tất cả') ||
                                      (currentSize != null && currentSize == sz);
                              return ChoiceChip(
                                label: Text(sz),
                                selected: isSelected,
                                selectedColor: c.primary,
                                checkmarkColor: c.onPrimary,
                                labelStyle: TextStyle(
                                  color:
                                      isSelected ? c.onPrimary : c.textPrimary,
                                  fontWeight: isSelected
                                      ? FontWeight.w600
                                      : FontWeight.w500,
                                  fontSize: 13,
                                ),
                                backgroundColor: c.surface,
                                side: BorderSide(
                                  color: isSelected ? c.primary : c.border,
                                ),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(
                                        AppTheme.radiusSm)),
                                onSelected: (_) => setState(() {
                                  currentSize = (sz == 'Tất cả') ? null : sz;
                                }),
                              );
                            }).toList(),
                          ),
                        ),

                        // 3. Mau sac
                        _buildFilterContainer(
                          c: c,
                          title: 'Màu sắc',
                          child: Wrap(
                            spacing: AppSpacing.sm,
                            runSpacing: AppSpacing.sm,
                            children: colorOptions.map((option) {
                              final label = option['label'] as String;
                              final col = option['color'] as Color?;
                              final hasBorder = option['border'] == true;
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
                                                  color: c.border, width: 1)
                                              : null,
                                        ),
                                      )
                                    : null,
                                label: Text(label),
                                selected: isSelected,
                                selectedColor: c.primary,
                                checkmarkColor: c.onPrimary,
                                labelStyle: TextStyle(
                                  color:
                                      isSelected ? c.onPrimary : c.textPrimary,
                                  fontWeight: isSelected
                                      ? FontWeight.w600
                                      : FontWeight.w500,
                                  fontSize: 13,
                                ),
                                backgroundColor: c.surface,
                                side: BorderSide(
                                  color: isSelected ? c.primary : c.border,
                                ),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(
                                        AppTheme.radiusSm)),
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
                          c: c,
                          title: 'Đánh giá sao',
                          child: Wrap(
                            spacing: AppSpacing.sm,
                            runSpacing: AppSpacing.sm,
                            children: ratingOptions.map((r) {
                              final val = r['value'] as double;
                              final label = r['label'] as String;
                              final isSelected = currentMinRating == val;
                              return ChoiceChip(
                                avatar: val > 0
                                    ? Icon(Icons.star_rounded,
                                        size: 16, color: c.secondary)
                                    : null,
                                label: Text(label),
                                selected: isSelected,
                                selectedColor: c.primary,
                                checkmarkColor: c.onPrimary,
                                labelStyle: TextStyle(
                                  color:
                                      isSelected ? c.onPrimary : c.textPrimary,
                                  fontWeight: isSelected
                                      ? FontWeight.w600
                                      : FontWeight.w500,
                                  fontSize: 13,
                                ),
                                backgroundColor: c.surface,
                                side: BorderSide(
                                  color: isSelected ? c.primary : c.border,
                                ),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(
                                        AppTheme.radiusSm)),
                                onSelected: (_) =>
                                    setState(() => currentMinRating = val),
                              );
                            }).toList(),
                          ),
                        ),

                        // 5. Tinh trang hang
                        _buildFilterContainer(
                          c: c,
                          title: 'Tình trạng hàng',
                          child: SwitchListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text('Chỉ hiện sản phẩm còn hàng',
                                style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                    color: c.textPrimary)),
                            subtitle: Text(
                                'Ẩn các sản phẩm và biến thể đã hết hàng',
                                style: TextStyle(
                                    fontSize: 12, color: c.textMuted)),
                            value: currentOnlyInStock,
                            activeThumbColor: c.primary,
                            onChanged: (val) =>
                                setState(() => currentOnlyInStock = val),
                          ),
                        ),

                        // 6. Khoang gia
                        _buildFilterContainer(
                          c: c,
                          title: 'Khoảng giá',
                          trailing: Text(
                            '${formatPrice(currentRange.start)} - ${formatPrice(currentRange.end)}',
                            style: TextStyle(
                                color: c.danger,
                                fontWeight: FontWeight.bold,
                                fontSize: 13),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Wrap(
                                spacing: AppSpacing.sm,
                                runSpacing: AppSpacing.sm,
                                children: quickPrices.map((qp) {
                                  final qpMin = qp['min'] as double;
                                  final qpMax = qp['max'] as double;
                                  final isSelected = currentRange.start == qpMin &&
                                      currentRange.end == qpMax;
                                  return ActionChip(
                                    label: Text(qp['label'] as String),
                                    backgroundColor:
                                        isSelected ? c.primarySoft : c.surface,
                                    labelStyle: TextStyle(
                                      color: isSelected
                                          ? c.primary
                                          : c.textPrimary,
                                      fontWeight: isSelected
                                          ? FontWeight.w600
                                          : FontWeight.normal,
                                      fontSize: 12,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(
                                          AppTheme.radiusSm),
                                      side: BorderSide(
                                        color:
                                            isSelected ? c.primary : c.border,
                                      ),
                                    ),
                                    onPressed: () => setState(() {
                                      currentRange = RangeValues(qpMin, qpMax);
                                    }),
                                  );
                                }).toList(),
                              ),
                              const SizedBox(height: AppSpacing.sm),
                              RangeSlider(
                                values: currentRange,
                                min: 0,
                                max: 1000000,
                                divisions: 20,
                                activeColor: c.primary,
                                inactiveColor: c.border,
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
                          c: c,
                          title: 'Sắp xếp theo',
                          child: Wrap(
                            spacing: AppSpacing.sm,
                            runSpacing: AppSpacing.sm,
                            children: sortOptions.map((item) {
                              final isSelected = currentSort == item['key'];
                              return ChoiceChip(
                                label: Text(item['label']!),
                                selected: isSelected,
                                selectedColor: c.primary,
                                checkmarkColor: c.onPrimary,
                                labelStyle: TextStyle(
                                  color:
                                      isSelected ? c.onPrimary : c.textPrimary,
                                  fontWeight: isSelected
                                      ? FontWeight.w600
                                      : FontWeight.w500,
                                  fontSize: 13,
                                ),
                                backgroundColor: c.surface,
                                side: BorderSide(
                                  color: isSelected ? c.primary : c.border,
                                ),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(
                                        AppTheme.radiusSm)),
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
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    decoration: BoxDecoration(
                      color: c.surface,
                      boxShadow: [
                        BoxShadow(
                          color: c.shadow,
                          blurRadius: 10,
                          offset: const Offset(0, -3),
                        ),
                      ],
                    ),
                    child: SafeArea(
                      top: false,
                      child: PrimaryButton(
                        label: 'Xem $matchCount sản phẩm phù hợp',
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
    final c = AppColors.of(context);
    final productProv = context.watch<ProductProvider>();
    final wishlistProv = context.watch<WishlistProvider>();

    return Scaffold(
      backgroundColor: c.background,
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
            padding: const EdgeInsets.only(right: AppSpacing.sm),
            child: TextButton.icon(
              icon: Badge(
                isLabelVisible: productProv.activeFilterCount > 0,
                label: Text('${productProv.activeFilterCount}',
                    style: const TextStyle(
                        fontSize: 10, fontWeight: FontWeight.bold)),
                backgroundColor: c.danger,
                child: const Icon(Icons.tune_rounded, size: 18),
              ),
              label: Text('Lọc',
                  style: TextStyle(
                      fontWeight: FontWeight.w600, color: c.textPrimary)),
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
            // Cung nen voi AppBar de khong co dai trang cat ngang dau trang.
            color: c.background,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.sm,
              ),
              itemCount: productProv.categories.length,
              separatorBuilder: (_, __) =>
                  const SizedBox(width: AppSpacing.xl),
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
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.sm,
              ),
              // Dai bao loc chay het chieu ngang nen dung mau be dam hon thay
              // vi to accent, cho dong tong voi phan con lai.
              color: c.surfaceVariant,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Bộ lọc đang dùng (${productProv.products.length} sản phẩm):',
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: c.textPrimary),
                      ),
                      GestureDetector(
                        onTap: () => productProv.resetFilters(),
                        child: Text('Xóa tất cả',
                            style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: c.danger)),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        if (productProv.searchQuery.isNotEmpty)
                          _buildFilterBadgeChip(
                            c: c,
                            label: '"${productProv.searchQuery}"',
                            onDeleted: () => productProv.clearSearchQuery(),
                          ),
                        if (productProv.selectedCategory != 'Tất cả')
                          _buildFilterBadgeChip(
                            c: c,
                            label: 'DM: ${productProv.selectedCategory}',
                            onDeleted: () => productProv.clearCategory(),
                          ),
                        if (productProv.classification == 'new')
                          _buildFilterBadgeChip(
                            c: c,
                            label: 'Hàng mới',
                            onDeleted: () =>
                                productProv.clearClassificationFilter(),
                          ),
                        if (productProv.classification == 'best_seller')
                          _buildFilterBadgeChip(
                            c: c,
                            label: 'Bán chạy',
                            onDeleted: () =>
                                productProv.clearClassificationFilter(),
                          ),
                        if (productProv.selectedSize != null)
                          _buildFilterBadgeChip(
                            c: c,
                            label: 'Size: ${productProv.selectedSize}',
                            onDeleted: () => productProv.clearSizeFilter(),
                          ),
                        if (productProv.selectedColor != null)
                          _buildFilterBadgeChip(
                            c: c,
                            label: 'Màu: ${productProv.selectedColor}',
                            onDeleted: () => productProv.clearColorFilter(),
                          ),
                        if (productProv.minRating > 0)
                          _buildFilterBadgeChip(
                            c: c,
                            label:
                                '⭐ ${productProv.minRating.toStringAsFixed(1)}+',
                            onDeleted: () => productProv.clearRatingFilter(),
                          ),
                        if (productProv.onlyInStock)
                          _buildFilterBadgeChip(
                            c: c,
                            label: 'Còn hàng',
                            onDeleted: () => productProv.clearStockFilter(),
                          ),
                        if (productProv.minPrice > 0 ||
                            productProv.maxPrice < 1000000)
                          _buildFilterBadgeChip(
                            c: c,
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
                ? const LoadingView()
                : productProv.products.isEmpty
                    ? StatusView(
                        icon: Icons.search_off_rounded,
                        title: 'Không tìm thấy sản phẩm phù hợp',
                        actionLabel: 'Xem tất cả sản phẩm',
                        onAction: () => productProv.resetFilters(),
                      )
                    : RefreshIndicator(
                        onRefresh: () => productProv.loadProducts(),
                        child: GridView.builder(
                          padding: const EdgeInsets.all(AppSpacing.lg),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            childAspectRatio: 0.5,
                            crossAxisSpacing: AppSpacing.md,
                            mainAxisSpacing: AppSpacing.md,
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
