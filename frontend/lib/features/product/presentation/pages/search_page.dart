import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:menly_app/core/theme/app_theme.dart';
import 'package:menly_app/core/utils/format.dart';
import 'package:menly_app/features/product/data/models/product_model.dart';
import 'package:menly_app/features/product/presentation/pages/product_detail_page.dart';
import 'package:menly_app/features/product/presentation/pages/product_list_page.dart';
import '../providers/product_provider.dart';
import 'package:menly_app/core/widgets/app_image.dart';

/// Trang tim kiem san pham Menly kem hinh anh, gia, danh muc va lich su
class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
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
    final productProv = context.watch<ProductProvider>();
    final queryText = _searchCtrl.text.trim();
    final matchingProducts = queryText.isNotEmpty
        ? productProv.searchProducts(queryText)
        : <ProductModel>[];

    return Scaffold(
      backgroundColor: AppTheme.scaffoldBackground,
      appBar: AppBar(
        titleSpacing: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Container(
          height: 40,
          margin: const EdgeInsets.only(right: 8),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(20),
          ),
          child: TextField(
            controller: _searchCtrl,
            autofocus: true,
            style: const TextStyle(fontSize: 14),
            decoration: InputDecoration(
              hintText: 'Tìm áo sơ mi, polo, jeans...',
              hintStyle: TextStyle(color: Colors.grey.shade500, fontSize: 13.5),
              prefixIcon: const Icon(Icons.search, size: 20, color: Colors.grey),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 10),
              suffixIcon: _searchCtrl.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.cancel, size: 18, color: Colors.grey),
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
            padding: const EdgeInsets.only(right: 8),
            child: TextButton(
              style: TextButton.styleFrom(
                foregroundColor: AppTheme.primary,
                padding: const EdgeInsets.symmetric(horizontal: 12),
              ),
              onPressed: () => _performSearch(_searchCtrl.text),
              child: const Text('Tìm', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Neu dang go chu -> Hien thi danh sach san pham khop kem HINH ANH & GIA
            if (queryText.isNotEmpty) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Kết quả tìm kiếm (${matchingProducts.length})',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                  if (matchingProducts.isNotEmpty)
                    TextButton(
                      style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
                      onPressed: () => _performSearch(queryText),
                      child: const Text('Xem dạng lưới', style: TextStyle(fontSize: 12, color: AppTheme.primary, fontWeight: FontWeight.bold)),
                    ),
                ],
              ),
              const SizedBox(height: 10),

              if (matchingProducts.isEmpty) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 36),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(Icons.search_off_rounded, size: 56, color: Colors.grey.shade400),
                        const SizedBox(height: 12),
                        Text(
                          'Không tìm thấy sản phẩm khớp với "$queryText"',
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Thử kiểm tra lỗi chính tả hoặc tìm từ khóa chung hơn như "áo", "quần"...',
                          style: TextStyle(fontSize: 12.5, color: Colors.grey.shade600),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              ] else ...[
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: matchingProducts.length,
                  separatorBuilder: (_, __) => const Divider(height: 12, color: Color(0xFFF0F0F0)),
                  itemBuilder: (ctx, i) {
                    final p = matchingProducts[i];
                    return _buildProductSearchTile(p);
                  },
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.grid_view_rounded, size: 16),
                    label: Text('Xem toàn bộ ${matchingProducts.length} sản phẩm (Lưới 2 cột)'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.primary,
                      side: const BorderSide(color: AppTheme.primary),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: () => _performSearch(queryText),
                  ),
                ),
              ],
              const SizedBox(height: 24),
            ],

            // Lich su tim kiem gan day
            if (productProv.searchHistory.isNotEmpty) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Lịch sử tìm kiếm gần đây', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  TextButton(
                    onPressed: () => productProv.clearSearchHistory(),
                    child: const Text('Xóa tất cả', style: TextStyle(fontSize: 12, color: Colors.redAccent)),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: productProv.searchHistory.map((keyword) {
                  return InputChip(
                    label: Text(keyword, style: const TextStyle(fontSize: 12.5)),
                    backgroundColor: Colors.white,
                    side: BorderSide(color: Colors.grey.shade300),
                    deleteIcon: const Icon(Icons.close, size: 14, color: Colors.grey),
                    onDeleted: () => productProv.removeSearchKeyword(keyword),
                    onPressed: () {
                      _searchCtrl.text = keyword;
                      setState(() {});
                      _performSearch(keyword);
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),
            ],

            // Tu khoa tim kiem pho bien
            const Text('Từ khóa phổ biến', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
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
                  backgroundColor: Colors.white,
                  side: BorderSide(color: Colors.grey.shade300),
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
              const SizedBox(height: 24),
              const Text('Gợi ý cho bạn hôm nay', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              const SizedBox(height: 10),
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: productProv.allProducts.take(4).length,
                separatorBuilder: (_, __) => const Divider(height: 12, color: Color(0xFFF0F0F0)),
                itemBuilder: (ctx, i) {
                  final p = productProv.allProducts[i];
                  return _buildProductSearchTile(p);
                },
              ),
            ],
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildProductSearchTile(ProductModel p) {
    return InkWell(
      onTap: () => _openProductDetail(p),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
        child: Row(
          children: [
            // Hinh anh san pham (Thumbnail)
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Container(
                width: 58,
                height: 58,
                color: Colors.grey.shade100,
                child: p.thumbnailUrl.isNotEmpty
                    ? AppImage(
                        url: p.thumbnailUrl,
                        fit: BoxFit.cover,
                        placeholder: (_) => Container(color: Colors.grey.shade200),
                        errorWidget: (_) => Container(
                          color: Colors.grey.shade200,
                          child: const Icon(Icons.checkroom, size: 24, color: Colors.grey),
                        ),
                      )
                    : Container(
                        color: Colors.grey.shade200,
                        child: const Icon(Icons.checkroom, size: 24, color: Colors.grey),
                      ),
              ),
            ),
            const SizedBox(width: 12),
            // Thong tin san pham: Ten, Danh muc & Gia
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    p.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        formatVnd(p.price),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          color: AppTheme.accentRed,
                        ),
                      ),
                      if (p.categoryName.isNotEmpty) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            p.categoryName,
                            style: TextStyle(fontSize: 10, color: Colors.grey.shade700, fontWeight: FontWeight.w500),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, size: 18, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}
