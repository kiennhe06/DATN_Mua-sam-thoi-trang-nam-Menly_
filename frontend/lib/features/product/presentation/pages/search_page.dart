import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:menly_app/core/theme/app_colors.dart';
import 'package:menly_app/core/theme/app_spacing.dart';
import 'package:menly_app/core/theme/app_theme.dart';
import 'package:menly_app/core/utils/format.dart';
import 'package:menly_app/features/product/data/models/product_model.dart';
import 'package:menly_app/features/product/presentation/pages/product_detail_page.dart';
import 'package:menly_app/features/product/presentation/pages/product_list_page.dart';
import '../providers/product_provider.dart';
import 'package:menly_app/core/widgets/app_buttons.dart';
import 'package:menly_app/core/widgets/app_image.dart';
import 'package:menly_app/core/widgets/section_header.dart';
import 'package:menly_app/core/widgets/state_views.dart';

/// Trang tim kiem san pham Menly kem hinh anh, gia, danh muc va lich su
class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  /// O tim kiem dang vien thuoc tren thanh tieu de.
  static const double _searchFieldHeight = 44;

  /// Anh thu nho cua mot dong ket qua tim kiem.
  static const double _resultThumbSize = 64;

  /// Vien thuoc dung chung cho chip lich su va chip tu khoa pho bien.
  static const StadiumBorder _chipShape = StadiumBorder();

  final _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _performSearch(String query) {
    final q = query.trim();
    if (q.isNotEmpty) {
      final productProv = context.read<ProductProvider>();
      productProv.addSearchKeyword(q);
      productProv.setSearchQuery(q);
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const ProductListPage()),
      );
    }
  }

  void _openProductDetail(ProductModel p) {
    final productProv = context.read<ProductProvider>();
    productProv.addSearchKeyword(p.name);
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ProductDetailPage(product: p)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final productProv = context.watch<ProductProvider>();
    final queryText = _searchCtrl.text.trim();
    final matchingProducts = queryText.isNotEmpty
        ? productProv.searchProducts(queryText)
        : <ProductModel>[];

    return Scaffold(
      backgroundColor: c.background,
      appBar: AppBar(
        titleSpacing: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: c.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        // O tim kiem dang vien thuoc, nen the, khong vien day
        title: Container(
          height: _searchFieldHeight,
          margin: const EdgeInsets.only(right: AppSpacing.sm),
          decoration: BoxDecoration(
            color: c.surfaceVariant,
            borderRadius: BorderRadius.circular(AppTheme.radiusPill),
          ),
          child: TextField(
            controller: _searchCtrl,
            autofocus: true,
            style: TextStyle(fontSize: 14, color: c.textPrimary),
            decoration: InputDecoration(
              hintText: 'Tìm áo sơ mi, polo, jeans...',
              hintStyle: TextStyle(color: c.textMuted, fontSize: 13.5),
              prefixIcon: Icon(Icons.search, size: 20, color: c.textMuted),
              border: InputBorder.none,
              contentPadding:
                  const EdgeInsets.symmetric(vertical: AppSpacing.md),
              suffixIcon: _searchCtrl.text.isNotEmpty
                  ? IconButton(
                      icon: Icon(Icons.cancel, size: 18, color: c.textMuted),
                      onPressed: () {
                        _searchCtrl.clear();
                        setState(() {});
                      },
                    )
                  : null,
            ),
            onChanged: (_) => setState(() {}),
            onSubmitted: _performSearch,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: AppSpacing.sm),
            child: TextButton(
              style: TextButton.styleFrom(
                foregroundColor: c.primary,
                padding:
                    const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              ),
              onPressed: () => _performSearch(_searchCtrl.text),
              child: const Text('Tìm',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Neu dang go chu -> Hien thi danh sach san pham khop kem HINH ANH & GIA
            if (queryText.isNotEmpty) ...[
              SectionHeader(
                title: 'Kết quả tìm kiếm (${matchingProducts.length})',
                actionLabel:
                    matchingProducts.isNotEmpty ? 'Xem dạng lưới' : null,
                onAction: () => _performSearch(queryText),
              ),
              const SizedBox(height: AppSpacing.md),

              if (matchingProducts.isEmpty) ...[
                StatusView(
                  icon: Icons.search_off_rounded,
                  title: 'Không tìm thấy sản phẩm khớp với "$queryText"',
                  message:
                      'Thử kiểm tra lỗi chính tả hoặc tìm từ khóa chung hơn như "áo", "quần"...',
                ),
              ] else ...[
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: matchingProducts.length,
                  separatorBuilder: (_, __) =>
                      Divider(height: AppSpacing.md, color: c.border),
                  itemBuilder: (ctx, i) {
                    final p = matchingProducts[i];
                    return _buildProductSearchTile(p, c);
                  },
                ),
                const SizedBox(height: AppSpacing.lg),
                SecondaryButton(
                  icon: Icons.grid_view_rounded,
                  label:
                      'Xem toàn bộ ${matchingProducts.length} sản phẩm (Lưới 2 cột)',
                  onPressed: () => _performSearch(queryText),
                ),
              ],
              const SizedBox(height: AppSpacing.xxl),
            ],

            // Lich su tim kiem gan day
            if (productProv.searchHistory.isNotEmpty) ...[
              SectionHeader(
                title: 'Lịch sử tìm kiếm gần đây',
                actionLabel: 'Xóa tất cả',
                onAction: () => productProv.clearSearchHistory(),
              ),
              const SizedBox(height: AppSpacing.sm),
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: productProv.searchHistory.map((keyword) {
                  return InputChip(
                    label: Text(keyword, style: const TextStyle(fontSize: 12.5)),
                    backgroundColor: c.surface,
                    shape: _chipShape,
                    side: BorderSide(color: c.border),
                    deleteIcon:
                        Icon(Icons.close, size: 14, color: c.textMuted),
                    onDeleted: () => productProv.removeSearchKeyword(keyword),
                    onPressed: () {
                      _searchCtrl.text = keyword;
                      setState(() {});
                      _performSearch(keyword);
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: AppSpacing.xl),
            ],

            // Tu khoa tim kiem pho bien
            const SectionHeader(title: 'Từ khóa phổ biến'),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                'Áo sơ mi trắng',
                'Quần jeans slimfit',
                'Áo polo nam',
                'Quần tây công sở',
                'Áo khoác bomber',
                'Áo thun basic',
              ].map((term) {
                return ActionChip(
                  label: Text(term, style: const TextStyle(fontSize: 12.5)),
                  backgroundColor: c.surface,
                  shape: _chipShape,
                  side: BorderSide(color: c.border),
                  onPressed: () {
                    _searchCtrl.text = term;
                    setState(() {});
                    _performSearch(term);
                  },
                );
              }).toList(),
            ),

            // Neu o tim kiem rong -> Goi y cac san pham noi bat kem HINH ANH
            if (queryText.isEmpty && productProv.allProducts.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.xxl),
              const SectionHeader(title: 'Gợi ý cho bạn hôm nay'),
              const SizedBox(height: AppSpacing.md),
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: productProv.allProducts.take(4).length,
                separatorBuilder: (_, __) =>
                    Divider(height: AppSpacing.md, color: c.border),
                itemBuilder: (ctx, i) {
                  final p = productProv.allProducts[i];
                  return _buildProductSearchTile(p, c);
                },
              ),
            ],
            const SizedBox(height: AppSpacing.xxl),
          ],
        ),
      ),
    );
  }

  Widget _buildProductSearchTile(ProductModel p, AppColors c) {
    return InkWell(
      onTap: () => _openProductDetail(p),
      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      child: Container(
        padding: const EdgeInsets.symmetric(
          vertical: AppSpacing.md,
          horizontal: AppSpacing.xs,
        ),
        child: Row(
          children: [
            // Hinh anh san pham (Thumbnail)
            ClipRRect(
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              child: Container(
                width: _resultThumbSize,
                height: _resultThumbSize,
                color: c.surfaceVariant,
                child: p.thumbnailUrl.isNotEmpty
                    ? AppImage(
                        url: p.thumbnailUrl,
                        fit: BoxFit.cover,
                        placeholder: (_) => Container(color: c.surfaceVariant),
                        errorWidget: (_) => Container(
                          color: c.surfaceVariant,
                          child: Icon(Icons.checkroom,
                              size: 24, color: c.textMuted),
                        ),
                      )
                    : Container(
                        color: c.surfaceVariant,
                        child: Icon(Icons.checkroom,
                            size: 24, color: c.textMuted),
                      ),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            // Thong tin san pham: Ten, Danh muc & Gia
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    p.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13.5,
                      color: c.textPrimary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Row(
                    children: [
                      Text(
                        formatVnd(p.price),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          color: c.danger,
                        ),
                      ),
                      if (p.categoryName.isNotEmpty) ...[
                        const SizedBox(width: AppSpacing.sm),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.sm,
                            vertical: 1.5,
                          ),
                          decoration: BoxDecoration(
                            color: c.surfaceVariant,
                            borderRadius:
                                BorderRadius.circular(AppTheme.radiusPill),
                          ),
                          child: Text(
                            p.categoryName,
                            style: TextStyle(
                              fontSize: 10,
                              color: c.textSecondary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, size: 18, color: c.textMuted),
          ],
        ),
      ),
    );
  }
}
