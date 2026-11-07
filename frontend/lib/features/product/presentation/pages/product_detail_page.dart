import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:menly_app/core/share/product_share.dart';
import 'package:menly_app/core/theme/app_theme.dart';
import 'package:menly_app/core/utils/format.dart';
import 'package:menly_app/features/cart/data/models/cart_item_model.dart';
import 'package:menly_app/features/product/data/models/product_model.dart';
import 'package:menly_app/features/cart/presentation/providers/cart_provider.dart';
import 'package:menly_app/features/order/presentation/pages/checkout_page.dart';
import 'package:menly_app/features/wishlist/presentation/providers/wishlist_provider.dart';
import 'package:menly_app/features/product/presentation/providers/product_provider.dart';
import 'package:menly_app/features/review/presentation/widgets/product_reviews_section.dart';
import '../widgets/product_perk_item.dart';
import '../widgets/product_related_grid.dart';

/// Trang Chi tiet san pham cao cap Menly (Chon Size & Mau theo dang Dropdown tien loi)
class ProductDetailPage extends StatefulWidget {
  final ProductModel product;

  const ProductDetailPage({super.key, required this.product});

  @override
  State<ProductDetailPage> createState() => _ProductDetailPageState();
}

class _ProductDetailPageState extends State<ProductDetailPage> {
  late ProductModel _product;
  String _selectedSize = '';
  String _selectedColor = '';
  int _quantity = 1;
  int _imageIndex = 0;
  bool _loadingDetail = true;
  List<ProductModel> _relatedProducts = [];

  final PageController _imageController = PageController();

  bool get _isPants {
    final cat = _product.categoryName.toLowerCase();
    final name = _product.name.toLowerCase();
    if (cat.contains('quần') ||
        cat.contains('jean') ||
        cat.contains('kaki') ||
        cat.contains('tây') ||
        cat.contains('short') ||
        cat.contains('trouser')) {
      return true;
    }
    if (name.contains('quần') || name.contains('jean')) {
      return true;
    }
    return _product.variants.any((v) => int.tryParse(v.size) != null);
  }

  List<String> _getAvailableSizes() {
    const order = ['XS', 'S', 'M', 'L', 'XL', 'XXL', '2XL', '3XL'];
    final sizes = _product.variants
        .where((variant) => variant.stock > 0 && variant.size.trim().isNotEmpty)
        .map((variant) => variant.size)
        .toSet()
        .toList();
    sizes.sort((a, b) {
      final aIdx = order.indexOf(a.toUpperCase());
      final bIdx = order.indexOf(b.toUpperCase());
      if (aIdx >= 0 && bIdx >= 0) return aIdx.compareTo(bIdx);
      final aNum = int.tryParse(a);
      final bNum = int.tryParse(b);
      if (aNum != null && bNum != null) return aNum.compareTo(bNum);
      return a.compareTo(b);
    });
    return sizes;
  }

  /// Mau sac duoc loc theo kich co dang chon de chi hien thi to hop that su co hang.
  List<String> _getAvailableColors() {
    final sizes = _getAvailableSizes();
    final hasSelectedSize = sizes.contains(_selectedSize);
    return _product.variants
        .where((variant) =>
            variant.stock > 0 &&
            (!hasSelectedSize || variant.size == _selectedSize))
        .map((variant) => variant.color)
        .toSet()
        .toList();
  }

  ProductVariantModel? get _selectedVariant {
    for (final variant in _product.variants) {
      if (variant.size.toLowerCase() == _selectedSize.toLowerCase() &&
          variant.color.toLowerCase() == _selectedColor.toLowerCase()) {
        return variant;
      }
    }
    return null;
  }

  void _initSelection() {
    final sizes = _getAvailableSizes();
    final colors = _getAvailableColors();
    if (!sizes.contains(_selectedSize) && sizes.isNotEmpty) {
      _selectedSize = sizes.first;
    }
    if (!colors.contains(_selectedColor) && colors.isNotEmpty) {
      _selectedColor = colors.first;
    }
    _clampQuantity();
  }

  void _clampQuantity() {
    final stock = _selectedVariant?.stock ?? 0;
    final max = stock <= 0 ? 1 : (stock > 20 ? 20 : stock);
    if (_quantity > max) _quantity = max;
    if (_quantity < 1) _quantity = 1;
  }

  void _onSizeChanged(String? size) {
    if (size == null) return;
    setState(() {
      _selectedSize = size;
      final colors = _getAvailableColors();
      if (!colors.contains(_selectedColor) && colors.isNotEmpty) {
        _selectedColor = colors.first;
      }
      _clampQuantity();
    });
  }

  void _onColorChanged(String? color) {
    if (color == null) return;
    setState(() {
      _selectedColor = color;
      _clampQuantity();
    });
  }

  @override
  void initState() {
    super.initState();
    _product = widget.product;
    _initSelection();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final productProv = context.read<ProductProvider>();
      productProv.addToRecentlyViewed(_product);
      setState(() {
        _relatedProducts = productProv.relatedProductsFor(_product);
      });

      final detail = await productProv.fetchProductDetail(_product.id);
      if (!mounted) return;
      setState(() {
        if (detail != null) {
          _product = detail;
          _initSelection();
        }
        _loadingDetail = false;
      });

      final related = await productProv.fetchRelatedProducts(_product);
      if (mounted) {
        setState(() => _relatedProducts = related);
      }
    });
  }

  @override
  void dispose() {
    _imageController.dispose();
    super.dispose();
  }

  String _getSizeHint(String size) {
    switch (size.toUpperCase()) {
      case 'S':
        return '(48 - 58 kg)';
      case 'M':
        return '(59 - 68 kg)';
      case 'L':
        return '(69 - 76 kg)';
      case 'XL':
        return '(77 - 84 kg)';
      case '2XL':
      case 'XXL':
        return '(85 - 94 kg)';
      case '29':
        return '(50 - 56 kg)';
      case '30':
        return '(56 - 62 kg)';
      case '31':
        return '(62 - 68 kg)';
      case '32':
        return '(68 - 75 kg)';
      case '33':
        return '(75 - 80 kg)';
      case '34':
        return '(80 - 88 kg)';
      default:
        return '';
    }
  }

  Color? _getColorForName(String name) {
    final lower = name.toLowerCase().trim();
    if (lower.contains('đen')) return const Color(0xFF1E293B);
    if (lower.contains('trắng')) return Colors.white;
    if (lower.contains('xám') || lower.contains('ghi')) {
      return const Color(0xFF64748B);
    }
    if (lower.contains('xanh navy') ||
        lower.contains('navy') ||
        lower.contains('chàm')) {
      return const Color(0xFF1E3A8A);
    }
    if (lower.contains('xanh đậm')) return const Color(0xFF1E40AF);
    if (lower.contains('xanh nhạt')) return const Color(0xFF93C5FD);
    if (lower.contains('rêu')) return const Color(0xFF3F6212);
    if (lower.contains('be')) return const Color(0xFFD4B996);
    if (lower.contains('nâu')) return const Color(0xFF78350F);
    if (lower.contains('đỏ')) return const Color(0xFFDC2626);
    if (lower.contains('vàng')) return const Color(0xFFEAB308);
    return null;
  }

  void _applyGuideSize(String size, BuildContext sheetContext) {
    final availableSizes = _getAvailableSizes();
    Navigator.pop(sheetContext);
    if (!availableSizes.contains(size)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Kích cỡ $size hiện chưa có hàng'),
          duration: const Duration(seconds: 1),
        ),
      );
      return;
    }
    _onSizeChanged(size);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Đã chọn kích cỡ $size theo bảng quy đổi'),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  void _showSizeGuideModal(BuildContext context) {
    int activeTab = _isPants ? 1 : 0;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (sheetContext, setModalState) {
            final isTopsTab = activeTab == 0;
            final currentTableSizes = isTopsTab
                ? const [
                    ['S', '1m55 - 1m64', '48 - 58 kg', '86 - 90 cm'],
                    ['M', '1m65 - 1m72', '59 - 68 kg', '91 - 95 cm'],
                    ['L', '1m72 - 1m78', '69 - 76 kg', '96 - 100 cm'],
                    ['XL', '1m78 - 1m84', '77 - 84 kg', '101 - 105 cm'],
                    ['2XL', '1m82 - 1m90', '85 - 94 kg', '106 - 110 cm'],
                  ]
                : const [
                    ['29', '1m60 - 1m66', '50 - 56 kg', '74 - 76 cm'],
                    ['30', '1m65 - 1m70', '56 - 62 kg', '77 - 79 cm'],
                    ['31', '1m68 - 1m74', '62 - 68 kg', '80 - 82 cm'],
                    ['32', '1m70 - 1m76', '68 - 75 kg', '83 - 85 cm'],
                    ['33', '1m74 - 1m80', '75 - 80 kg', '86 - 88 cm'],
                    ['34', '1m76 - 1m85', '80 - 88 kg', '89 - 92 cm'],
                  ];

            return DraggableScrollableSheet(
              initialChildSize: 0.72,
              minChildSize: 0.45,
              maxChildSize: 0.92,
              expand: false,
              builder: (_, scrollController) {
                return SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade300,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Bảng quy đổi kích cỡ chuẩn Menly',
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          TextButton(
                            style: TextButton.styleFrom(
                              visualDensity: VisualDensity.compact,
                              padding: EdgeInsets.zero,
                            ),
                            onPressed: () => Navigator.pop(ctx),
                            child: const Text('Đóng',
                                style: TextStyle(
                                    color: Colors.grey,
                                    fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Chạm vào dòng kích cỡ để áp dụng nhanh cho sản phẩm',
                        style: TextStyle(
                            fontSize: 12, color: Colors.grey.shade600),
                      ),
                      const SizedBox(height: 16),

                      // Tabs Chuyen doi Ao / Quan
                      Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () => setModalState(() => activeTab = 0),
                              child: Container(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 10),
                                decoration: BoxDecoration(
                                  color: isTopsTab
                                      ? AppTheme.primary
                                      : Colors.grey.shade100,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  'Áo nam (S - 2XL)',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                    color: isTopsTab
                                        ? Colors.white
                                        : AppTheme.textPrimary,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: GestureDetector(
                              onTap: () => setModalState(() => activeTab = 1),
                              child: Container(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 10),
                                decoration: BoxDecoration(
                                  color: !isTopsTab
                                      ? AppTheme.primary
                                      : Colors.grey.shade100,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  'Quần nam (29 - 34)',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                    color: !isTopsTab
                                        ? Colors.white
                                        : AppTheme.textPrimary,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Bang quy doi
                      Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: AppTheme.border),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: Table(
                          border: const TableBorder.symmetric(
                              inside: BorderSide(
                                  color: AppTheme.border, width: 0.5)),
                          columnWidths: const {
                            0: FlexColumnWidth(1.2),
                            1: FlexColumnWidth(2.0),
                            2: FlexColumnWidth(1.8),
                            3: FlexColumnWidth(1.8),
                          },
                          children: [
                            TableRow(
                              decoration:
                                  const BoxDecoration(color: Color(0xFFF1F5F9)),
                              children: [
                                const Padding(
                                    padding: EdgeInsets.all(10),
                                    child: Text('Size',
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 13))),
                                const Padding(
                                    padding: EdgeInsets.all(10),
                                    child: Text('Chiều cao',
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 13))),
                                const Padding(
                                    padding: EdgeInsets.all(10),
                                    child: Text('Cân nặng',
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 13))),
                                Padding(
                                    padding: const EdgeInsets.all(10),
                                    child: Text(isTopsTab ? 'Ngực' : 'Bụng',
                                        style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 13))),
                              ],
                            ),
                            ...currentTableSizes.map((row) {
                              final rowSize = row[0];
                              final isSelected = _selectedSize == rowSize;
                              return TableRow(
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? AppTheme.primary.withValues(alpha: 0.1)
                                      : Colors.transparent,
                                ),
                                children: [
                                  InkWell(
                                    onTap: () => _applyGuideSize(rowSize, ctx),
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 10, vertical: 12),
                                      child: Text(
                                        rowSize,
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: isSelected
                                              ? AppTheme.primary
                                              : AppTheme.textPrimary,
                                        ),
                                      ),
                                    ),
                                  ),
                                  InkWell(
                                    onTap: () => _applyGuideSize(rowSize, ctx),
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 10, vertical: 12),
                                      child: Text(row[1],
                                          style: const TextStyle(fontSize: 12)),
                                    ),
                                  ),
                                  InkWell(
                                    onTap: () => _applyGuideSize(rowSize, ctx),
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 10, vertical: 12),
                                      child: Text(row[2],
                                          style: const TextStyle(fontSize: 12)),
                                    ),
                                  ),
                                  InkWell(
                                    onTap: () => _applyGuideSize(rowSize, ctx),
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 10, vertical: 12),
                                      child: Text(row[3],
                                          style: const TextStyle(fontSize: 12)),
                                    ),
                                  ),
                                ],
                              );
                            }),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),

                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.amber.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.amber.shade200),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '• Nếu phân vân giữa 2 kích cỡ, bạn nên chọn kích cỡ lớn hơn để mặc thoải mái.',
                              style: TextStyle(
                                  color: Colors.amber.shade900,
                                  fontSize: 12,
                                  height: 1.4),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '• Menly hỗ trợ đổi size miễn phí tận nơi trong 30 ngày.',
                              style: TextStyle(
                                  color: Colors.amber.shade900,
                                  fontSize: 12,
                                  height: 1.4),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  String _resolveVariantId(ProductModel p) {
    final variant = _selectedVariant;
    if (variant != null &&
        variant.id.isNotEmpty &&
        variant.stock >= _quantity) {
      return variant.id;
    }
    return '';
  }

  /// Gallery anh that lay tu product_images cua backend.
  Widget _buildGallery(ProductModel p) {
    final images = p.galleryImages;
    if (images.isEmpty) {
      return Container(
        width: double.infinity,
        height: 400,
        color: Colors.grey.shade100,
        alignment: Alignment.center,
        child: const Text('Menly',
            style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppTheme.textMuted)),
      );
    }

    final activeIndex = _imageIndex.clamp(0, images.length - 1);

    return Column(
      children: [
        SizedBox(
          height: 400,
          child: Stack(
            children: [
              PageView.builder(
                controller: _imageController,
                itemCount: images.length,
                onPageChanged: (index) => setState(() => _imageIndex = index),
                itemBuilder: (_, index) => CachedNetworkImage(
                  imageUrl: images[index],
                  width: double.infinity,
                  fit: BoxFit.cover,
                  placeholder: (_, __) =>
                      Container(color: Colors.grey.shade100),
                  errorWidget: (_, __, ___) => Container(
                    color: Colors.grey.shade100,
                    alignment: Alignment.center,
                    child: const Text('Menly',
                        style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textMuted)),
                  ),
                ),
              ),
              if (images.length > 1)
                Positioned(
                  right: 12,
                  bottom: 12,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.55),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${activeIndex + 1}/${images.length}',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
            ],
          ),
        ),
        if (images.length > 1)
          SizedBox(
            height: 76,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              scrollDirection: Axis.horizontal,
              itemCount: images.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (_, index) {
                final isActive = index == activeIndex;
                return GestureDetector(
                  onTap: () {
                    _imageController.animateToPage(
                      index,
                      duration: const Duration(milliseconds: 250),
                      curve: Curves.easeOut,
                    );
                    setState(() => _imageIndex = index);
                  },
                  child: Container(
                    width: 56,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isActive ? AppTheme.primary : AppTheme.border,
                        width: isActive ? 2 : 1,
                      ),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: CachedNetworkImage(
                      imageUrl: images[index],
                      fit: BoxFit.cover,
                      placeholder: (_, __) =>
                          Container(color: Colors.grey.shade100),
                      errorWidget: (_, __, ___) =>
                          Container(color: Colors.grey.shade100),
                    ),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }

  void _showShareSheet() {
    final link = ProductShare.productUri(_product).toString();

    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(20, 0, 20, 8),
                child: Text(
                  'Chia sẻ sản phẩm',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  link,
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
                ),
              ),
              const SizedBox(height: 8),
              ListTile(
                leading: const Icon(Icons.share_outlined),
                title: const Text('Chia sẻ qua ứng dụng khác'),
                onTap: () async {
                  Navigator.pop(sheetContext);
                  try {
                    await ProductShare.share(_product);
                  } catch (_) {
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Không thể mở ứng dụng chia sẻ')),
                    );
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.link),
                title: const Text('Sao chép liên kết'),
                onTap: () async {
                  final messenger = ScaffoldMessenger.of(context);
                  final navigator = Navigator.of(sheetContext);
                  await ProductShare.copyLink(_product);
                  navigator.pop();
                  messenger.showSnackBar(
                    const SnackBar(content: Text('Đã sao chép liên kết sản phẩm')),
                  );
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = _product;
    final wishlist = context.watch<WishlistProvider>();
    final cart = context.read<CartProvider>();
    final isFav = wishlist.isFavorite(p.id);

    final availableSizes = _getAvailableSizes();
    final availableColors = _getAvailableColors();
    final canPurchase = _resolveVariantId(p).isNotEmpty;
    final selectedVariant = _selectedVariant;
    final maxQuantity = selectedVariant == null
        ? 1
        : (selectedVariant.stock > 20 ? 20 : selectedVariant.stock);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(p.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined),
            tooltip: 'Chia sẻ sản phẩm',
            onPressed: _showShareSheet,
          ),
          IconButton(
            icon: Icon(
              isFav ? Icons.favorite : Icons.favorite_border,
              color: isFav ? AppTheme.accentRed : AppTheme.textPrimary,
            ),
            onPressed: () async {
              final added = await wishlist.toggleFavorite(p);
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(added
                      ? 'Đã lưu "${p.name}" vào danh sách yêu thích'
                      : 'Đã xóa khỏi danh sách yêu thích'),
                  duration: const Duration(seconds: 2),
                ),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. ANH SAN PHAM (gallery tu product_images that)
            _buildGallery(p),

            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Danh muc, danh gia
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppTheme.primary.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          p.categoryName.toUpperCase(),
                          style: const TextStyle(
                              fontSize: 11,
                              color: AppTheme.primary,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                      Row(
                        children: [
                          const Text('★ ',
                              style: TextStyle(
                                  color: Colors.amber,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16)),
                          Text('${p.ratingAvg}',
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 14)),
                          Text(' (${p.ratingCount} đánh giá)',
                              style: const TextStyle(
                                  color: AppTheme.textSecondary, fontSize: 13)),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Ten san pham
                  Text(
                    p.name,
                    style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        letterSpacing: -0.3,
                        height: 1.3),
                  ),
                  const SizedBox(height: 8),

                  // Gia tien (du lieu that tu backend)
                  Text(
                    formatVnd(p.price),
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      color: AppTheme.accentRed,
                    ),
                  ),
                  const Divider(height: 28),

                  // 2. CHON KICH CO & MAU SAC THEO DANG DROPDOWN
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Chọn phân loại sản phẩm',
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: AppTheme.textPrimary),
                      ),
                      TextButton(
                        style: TextButton.styleFrom(
                            visualDensity: VisualDensity.compact,
                            padding: EdgeInsets.zero),
                        onPressed: () => _showSizeGuideModal(context),
                        child: const Text('Bảng quy đổi size',
                            style: TextStyle(
                                fontSize: 12,
                                color: AppTheme.primaryAccent,
                                fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // DROPDOWN KICH CO
                  Container(
                    width: double.infinity,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppTheme.border),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: availableSizes.contains(_selectedSize)
                            ? _selectedSize
                            : null,
                        isExpanded: true,
                        icon: const Text('▾',
                            style: TextStyle(
                                fontSize: 16, color: AppTheme.textMuted)),
                        hint: const Text('Chọn kích cỡ',
                            style: TextStyle(
                                fontSize: 13, color: AppTheme.textMuted)),
                        items: availableSizes.map((size) {
                          final hint = _getSizeHint(size);
                          return DropdownMenuItem<String>(
                            value: size,
                            child: Row(
                              children: [
                                Text(
                                  'Kích cỡ: $size',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14,
                                      color: AppTheme.textPrimary),
                                ),
                                if (hint.isNotEmpty) ...[
                                  const SizedBox(width: 8),
                                  Text(
                                    hint,
                                    style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey.shade500),
                                  ),
                                ],
                              ],
                            ),
                          );
                        }).toList(),
                        onChanged: _onSizeChanged,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // DROPDOWN MAU SAC
                  if (_loadingDetail && p.variants.isEmpty)
                    const Padding(
                      padding: EdgeInsets.only(bottom: 12),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                          SizedBox(width: 8),
                          Text('Đang tải phân loại sản phẩm...',
                              style: TextStyle(
                                  fontSize: 12, color: AppTheme.textMuted)),
                        ],
                      ),
                    )
                  else if (p.variants.isEmpty || availableSizes.isEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Text(
                        p.variants.isEmpty
                            ? 'Sản phẩm chưa có biến thể hàng hóa.'
                            : 'Sản phẩm hiện đã hết hàng.',
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                  Container(
                    width: double.infinity,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppTheme.border),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: availableColors.contains(_selectedColor)
                            ? _selectedColor
                            : null,
                        isExpanded: true,
                        icon: const Text('▾',
                            style: TextStyle(
                                fontSize: 16, color: AppTheme.textMuted)),
                        hint: const Text('Chọn màu sắc',
                            style: TextStyle(
                                fontSize: 13, color: AppTheme.textMuted)),
                        items: availableColors.map((color) {
                          final colorDot = _getColorForName(color);
                          return DropdownMenuItem<String>(
                            value: color,
                            child: Row(
                              children: [
                                if (colorDot != null) ...[
                                  Container(
                                    width: 16,
                                    height: 16,
                                    decoration: BoxDecoration(
                                      color: colorDot,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: colorDot == Colors.white
                                            ? Colors.grey.shade400
                                            : Colors.transparent,
                                        width: 1,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                ],
                                Text(
                                  'Màu sắc: $color',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14,
                                      color: AppTheme.textPrimary),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                        onChanged: _onColorChanged,
                      ),
                    ),
                  ),
                  if (selectedVariant != null && selectedVariant.stock > 0)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        'Còn ${selectedVariant.stock} sản phẩm cho phân loại này',
                        style: const TextStyle(
                            fontSize: 12, color: AppTheme.textSecondary),
                      ),
                    ),
                  const SizedBox(height: 20),

                  // 3. CHON SO LUONG
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Số lượng:',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 14)),
                      Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: AppTheme.border),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            IconButton(
                              icon: const Text('-',
                                  style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold)),
                              onPressed: () {
                                if (_quantity > 1) {
                                  setState(() => _quantity--);
                                }
                              },
                            ),
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 12),
                              child: Text('$_quantity',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15)),
                            ),
                            IconButton(
                              icon: const Text('+',
                                  style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold)),
                              onPressed: _quantity < maxQuantity
                                  ? () => setState(() => _quantity++)
                                  : null,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 36),

                  // 4. CHINH SACH THOI TRANG MENLY
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppTheme.scaffoldBackground,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppTheme.border),
                    ),
                    child: const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ProductPerkItem(
                            title: 'Đổi trả 30 ngày',
                            subtitle: 'Miễn phí đổi size/màu tận nhà'),
                        Divider(height: 16),
                        ProductPerkItem(
                            title: 'Giao nhanh 24h',
                            subtitle: 'Nội thành nhận ngay trong ngày'),
                        Divider(height: 16),
                        ProductPerkItem(
                            title: 'Chất lượng cam kết',
                            subtitle:
                                '100% Cotton chải kỹ, thoáng mát, bền form'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // 5. MO TA CHI TIET
                  const Text('Mô tả sản phẩm',
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
                  const SizedBox(height: 8),
                  Text(
                    p.description.trim().isEmpty
                        ? 'Sản phẩm chưa có mô tả chi tiết.'
                        : p.description,
                    style: const TextStyle(
                        fontSize: 14,
                        height: 1.6,
                        color: AppTheme.textSecondary),
                  ),
                  const SizedBox(height: 30),
                  ProductReviewsSection(productId: p.id),
                  const SizedBox(height: 26),
                  ProductRelatedGrid(
                    product: _product,
                    relatedProducts: _relatedProducts,
                    wishlist: wishlist,
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ],
        ),
      ),

      // Thanh thao tac duoi cung: Nut Them vao gio & Nut Mua ngay
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.primary,
                    side: const BorderSide(color: AppTheme.primary, width: 1.5),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: canPurchase
                      ? () async {
                          final added = await cart.addToCart(
                            p,
                            size: _selectedSize,
                            color: _selectedColor,
                            quantity: _quantity,
                          );
                          if (!context.mounted) return;

                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(added
                                  ? 'Đã thêm $_quantity x "${p.name}" (Size: $_selectedSize, Màu: $_selectedColor) vào giỏ hàng'
                                  : cart.errorMessage ??
                                      'Không thể thêm sản phẩm vào giỏ'),
                              backgroundColor:
                                  added ? AppTheme.primary : Colors.red,
                              duration: const Duration(seconds: 2),
                            ),
                          );
                        }
                      : null,
                  child: const Text('Thêm vào giỏ',
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: canPurchase
                      ? () {
                          final variantId = _resolveVariantId(p);
                          final directItem = CartItemModel(
                            id: 'buy-now-${DateTime.now().millisecondsSinceEpoch}',
                            product: p,
                            variantId: variantId,
                            size: _selectedSize,
                            color: _selectedColor,
                            quantity: _quantity,
                            isSelected: true,
                          );

                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  CheckoutPage(customItems: [directItem]),
                            ),
                          );
                        }
                      : null,
                  child: const Text('Mua ngay',
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
