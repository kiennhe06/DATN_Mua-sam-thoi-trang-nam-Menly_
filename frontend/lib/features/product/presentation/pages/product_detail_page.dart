import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:menly_app/core/utils/format.dart';
import 'package:menly_app/core/theme/app_colors.dart';
import 'package:menly_app/core/theme/app_spacing.dart';
import 'package:menly_app/core/theme/app_theme.dart';
import 'package:menly_app/core/widgets/app_buttons.dart';
import 'package:menly_app/core/widgets/section_header.dart';
import 'package:menly_app/features/cart/data/models/cart_item_model.dart';
import 'package:menly_app/features/product/data/models/product_model.dart';
import 'package:menly_app/features/cart/presentation/pages/cart_page.dart';
import 'package:menly_app/features/cart/presentation/providers/cart_provider.dart';
import 'package:menly_app/features/order/presentation/pages/checkout_page.dart';
import 'package:menly_app/features/wishlist/presentation/providers/wishlist_provider.dart';
import 'package:menly_app/features/product/presentation/providers/product_provider.dart';
import 'package:menly_app/features/review/presentation/widgets/product_reviews_section.dart';
import '../widgets/product_perk_item.dart';
import '../widgets/product_related_grid.dart';
import 'package:menly_app/core/widgets/app_image.dart';

/// Trang Chi tiet san pham cao cap Menly (Chon Size & Mau theo dang Dropdown tien loi)
class ProductDetailPage extends StatefulWidget {
  final ProductModel product;

  const ProductDetailPage({super.key, required this.product});

  @override
  State<ProductDetailPage> createState() => _ProductDetailPageState();
}

class _ProductDetailPageState extends State<ProductDetailPage> {
  /// Le hai ben cua dai anh lon, de goc bo tron cua anh hien ro tren nen.
  static const EdgeInsets _galleryPadding =
      EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.sm, AppSpacing.xl, 0);

  // O chon kich co: o vuong bo tron, rong toi thieu 48 va cao 44.
  /// He so suy ra gia gach ngang lam moc neo tam ly.
  ///
  /// Doi mot cho nay la doi toan bo man chi tiet. Thay bang gia goc that ngay
  /// khi du lieu san pham co cot do.
  static const double _heSoGiaNeo = 1.25;

  static const double _sizeBoxHeight = 44;
  static const double _sizeBoxMinWidth = 48;

  // Cham chon mau: vong ring bao ngoai 44, o chua ca ten mau rong 76.
  static const double _colorSwatchRingSize = 44;
  static const double _colorSwatchSlotWidth = 76;

  /// Nut thao tac o thanh duoi cung: cao hon mac dinh cho de bam.
  static const double _actionButtonHeight = 56;

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

  /// Doi ten mau sang ma mau that cua san pham (den, trang, navy...).
  /// Day la mau hang hoa chu khong phai mau giao dien nen khong dung token.
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
    final c = AppColors.of(context);
    int activeTab = _isPants ? 1 : 0;

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
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.xl,
                    AppSpacing.md,
                    AppSpacing.xl,
                    AppSpacing.xxl,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: c.border,
                            borderRadius:
                                BorderRadius.circular(AppTheme.radiusPill),
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Bảng quy đổi kích cỡ chuẩn Menly',
                            style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: c.textPrimary),
                          ),
                          TextButton(
                            style: TextButton.styleFrom(
                              visualDensity: VisualDensity.compact,
                              padding: EdgeInsets.zero,
                            ),
                            onPressed: () => Navigator.pop(ctx),
                            child: Text('Đóng',
                                style: TextStyle(
                                    color: c.textMuted,
                                    fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        'Chạm vào dòng kích cỡ để áp dụng nhanh cho sản phẩm',
                        style: TextStyle(fontSize: 12, color: c.textSecondary),
                      ),
                      const SizedBox(height: AppSpacing.lg),

                      // Tabs Chuyen doi Ao / Quan
                      Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () => setModalState(() => activeTab = 0),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    vertical: AppSpacing.md),
                                decoration: BoxDecoration(
                                  color: isTopsTab
                                      ? c.primary
                                      : c.surfaceVariant,
                                  borderRadius: BorderRadius.circular(
                                      AppTheme.radiusPill),
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  'Áo nam (S - 2XL)',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                    color: isTopsTab
                                        ? c.onPrimary
                                        : c.textPrimary,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: GestureDetector(
                              onTap: () => setModalState(() => activeTab = 1),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    vertical: AppSpacing.md),
                                decoration: BoxDecoration(
                                  color: !isTopsTab
                                      ? c.primary
                                      : c.surfaceVariant,
                                  borderRadius: BorderRadius.circular(
                                      AppTheme.radiusPill),
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  'Quần nam (29 - 34)',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                    color: !isTopsTab
                                        ? c.onPrimary
                                        : c.textPrimary,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.lg),

                      // Bang quy doi
                      Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: c.border),
                          borderRadius:
                              BorderRadius.circular(AppTheme.radiusSm),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: Table(
                          border: TableBorder.symmetric(
                              inside:
                                  BorderSide(color: c.border, width: 0.5)),
                          columnWidths: const {
                            0: FlexColumnWidth(1.2),
                            1: FlexColumnWidth(2.0),
                            2: FlexColumnWidth(1.8),
                            3: FlexColumnWidth(1.8),
                          },
                          children: [
                            TableRow(
                              decoration:
                                  BoxDecoration(color: c.surfaceVariant),
                              children: [
                                Padding(
                                    padding:
                                        const EdgeInsets.all(AppSpacing.md),
                                    child: Text('Size',
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 13,
                                            color: c.textPrimary))),
                                Padding(
                                    padding:
                                        const EdgeInsets.all(AppSpacing.md),
                                    child: Text('Chiều cao',
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 13,
                                            color: c.textPrimary))),
                                Padding(
                                    padding:
                                        const EdgeInsets.all(AppSpacing.md),
                                    child: Text('Cân nặng',
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 13,
                                            color: c.textPrimary))),
                                Padding(
                                    padding:
                                        const EdgeInsets.all(AppSpacing.md),
                                    child: Text(isTopsTab ? 'Ngực' : 'Bụng',
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 13,
                                            color: c.textPrimary))),
                              ],
                            ),
                            ...currentTableSizes.map((row) {
                              final rowSize = row[0];
                              final isSelected = _selectedSize == rowSize;
                              return TableRow(
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? c.primarySoft
                                      : Colors.transparent,
                                ),
                                children: [
                                  InkWell(
                                    onTap: () => _applyGuideSize(rowSize, ctx),
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: AppSpacing.md,
                                        vertical: AppSpacing.md,
                                      ),
                                      child: Text(
                                        rowSize,
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: isSelected
                                              ? c.primary
                                              : c.textPrimary,
                                        ),
                                      ),
                                    ),
                                  ),
                                  InkWell(
                                    onTap: () => _applyGuideSize(rowSize, ctx),
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: AppSpacing.md,
                                        vertical: AppSpacing.md,
                                      ),
                                      child: Text(row[1],
                                          style: TextStyle(
                                              fontSize: 12,
                                              color: c.textSecondary)),
                                    ),
                                  ),
                                  InkWell(
                                    onTap: () => _applyGuideSize(rowSize, ctx),
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: AppSpacing.md,
                                        vertical: AppSpacing.md,
                                      ),
                                      child: Text(row[2],
                                          style: TextStyle(
                                              fontSize: 12,
                                              color: c.textSecondary)),
                                    ),
                                  ),
                                  InkWell(
                                    onTap: () => _applyGuideSize(rowSize, ctx),
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: AppSpacing.md,
                                        vertical: AppSpacing.md,
                                      ),
                                      child: Text(row[3],
                                          style: TextStyle(
                                              fontSize: 12,
                                              color: c.textSecondary)),
                                    ),
                                  ),
                                ],
                              );
                            }),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),

                      Container(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        decoration: BoxDecoration(
                          color: c.primarySoft,
                          borderRadius:
                              BorderRadius.circular(AppTheme.radiusSm),
                          border: Border.all(color: c.border),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '• Nếu phân vân giữa 2 kích cỡ, bạn nên chọn kích cỡ lớn hơn để mặc thoải mái.',
                              style: TextStyle(
                                  color: c.textSecondary,
                                  fontSize: 12,
                                  height: 1.4),
                            ),
                            const SizedBox(height: AppSpacing.xs),
                            Text(
                              '• Menly hỗ trợ đổi size miễn phí tận nơi trong 30 ngày.',
                              style: TextStyle(
                                  color: c.textSecondary,
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

  /// Nen chung cho cac khoi noi dung (quyen loi, mo ta, danh gia):
  /// the sang bo goc manh, vien mong, khong do bong nang.
  static BoxDecoration _contentCardDecoration(AppColors c) {
    return BoxDecoration(
      color: c.surface,
      borderRadius: BorderRadius.circular(AppTheme.radiusXl),
      border: Border.all(color: c.border),
    );
  }

  /// Gallery anh that lay tu product_images cua backend.
  Widget _buildGallery(ProductModel p) {
    final c = AppColors.of(context);
    final images = p.galleryImages;
    if (images.isEmpty) {
      return Padding(
        padding: _galleryPadding,
        child: Container(
          width: double.infinity,
          height: 400,
          decoration: BoxDecoration(
            color: c.surfaceVariant,
            borderRadius: BorderRadius.circular(AppTheme.radiusXl),
          ),
          alignment: Alignment.center,
          child: Text('Menly',
              style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: c.textMuted)),
        ),
      );
    }

    final activeIndex = _imageIndex.clamp(0, images.length - 1);

    return Column(
      children: [
        // Anh lon bo goc manh (radiusXl) va chua le hai ben cho thoang
        Padding(
          padding: _galleryPadding,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppTheme.radiusXl),
            child: SizedBox(
              height: 400,
              child: Stack(
                children: [
                  PageView.builder(
                    controller: _imageController,
                    itemCount: images.length,
                    onPageChanged: (index) =>
                        setState(() => _imageIndex = index),
                    itemBuilder: (_, index) => AppImage(
                      url: images[index],
                      width: double.infinity,
                      fit: BoxFit.cover,
                      placeholder: (_) => Container(color: c.surfaceVariant),
                      errorWidget: (_) => Container(
                        color: c.surfaceVariant,
                        alignment: Alignment.center,
                        child: Text('Menly',
                            style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: c.textMuted)),
                      ),
                    ),
                  ),
                  if (images.length > 1)
                    Positioned(
                      right: AppSpacing.md,
                      bottom: AppSpacing.md,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md,
                          vertical: AppSpacing.xs,
                        ),
                        decoration: BoxDecoration(
                          // Lop phu toi tren anh de so trang luon doc duoc
                          color: Colors.black.withValues(alpha: 0.55),
                          borderRadius:
                              BorderRadius.circular(AppTheme.radiusPill),
                        ),
                        child: Text(
                          '${activeIndex + 1}/${images.length}',
                          style: TextStyle(
                              color: c.onInk,
                              fontSize: 12,
                              fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
        if (images.length > 1)
          SizedBox(
            height: 80,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.xl,
                vertical: AppSpacing.md,
              ),
              scrollDirection: Axis.horizontal,
              itemCount: images.length,
              separatorBuilder: (_, __) =>
                  const SizedBox(width: AppSpacing.sm),
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
                      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                      border: Border.all(
                        // Anh dang xem duoc vien ink day hon de de nhan ra
                        color: isActive ? c.primary : c.border,
                        width: isActive ? 2 : 1,
                      ),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: AppImage(
                      url: images[index],
                      fit: BoxFit.cover,
                      placeholder: (_) => Container(color: c.surfaceVariant),
                      errorWidget: (_) => Container(color: c.surfaceVariant),
                    ),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }

  /// O chon kich co: o vuong bo tron, dang chon thi nen ink chu sang.
  ///
  /// Hien het lua chon ra man hinh thay vi giau trong nut xo: nguoi mua nhin
  /// mot cai la biet co nhung size nao, khong phai bam ra bam vao tung lan.
  Widget _buildSizeChips(List<String> availableSizes) {
    if (availableSizes.isEmpty) return const SizedBox.shrink();
    final c = AppColors.of(context);
    return Wrap(
      spacing: AppSpacing.md,
      runSpacing: AppSpacing.md,
      children: availableSizes.map((size) {
        final isSelected = size == _selectedSize;
        final hint = _getSizeHint(size);
        return InkWell(
          onTap: () => _onSizeChanged(size),
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          child: Container(
            height: _sizeBoxHeight,
            constraints: const BoxConstraints(minWidth: _sizeBoxMinWidth),
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            // Khong dat alignment o day: Container co alignment se no het be
            // rong cho phep, nen san pham chi co mot size se thanh mot thanh
            // dai suot man hinh. De cot con tu quyet dinh be rong.
            decoration: BoxDecoration(
              color: isSelected ? c.primary : c.surface,
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              border: Border.all(color: isSelected ? c.primary : c.border),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  size,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    height: 1.1,
                    color: isSelected ? c.onPrimary : c.textPrimary,
                  ),
                ),
                if (hint.isNotEmpty)
                  Text(
                    hint,
                    style: TextStyle(
                      fontSize: 10.5,
                      height: 1.1,
                      color: isSelected
                          ? c.onPrimary.withValues(alpha: 0.75)
                          : c.textMuted,
                    ),
                  ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  /// O chon mau: cham tron, dang chon thi co vong ring bao ngoai.
  ///
  /// Ten mau van nam ngay duoi cham de nguoi mua doc duoc ca nhung mau chua co
  /// ma mau that (luc do cham to bang nen phu de khong gay hieu nham).
  Widget _buildColorChips(List<String> availableColors) {
    if (availableColors.isEmpty) return const SizedBox.shrink();
    final c = AppColors.of(context);
    return Wrap(
      spacing: AppSpacing.md,
      runSpacing: AppSpacing.md,
      children: availableColors.map((color) {
        final isSelected = color == _selectedColor;
        final colorDot = _getColorForName(color);
        return InkWell(
          onTap: () => _onColorChanged(color),
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          child: SizedBox(
            width: _colorSwatchSlotWidth,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: _colorSwatchRingSize,
                  height: _colorSwatchRingSize,
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected ? c.primary : Colors.transparent,
                      width: 2,
                    ),
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      color: colorDot ?? c.surfaceVariant,
                      shape: BoxShape.circle,
                      border: Border.all(color: c.border),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  color,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    fontSize: 11.5,
                    height: 1.2,
                    color: isSelected ? c.textPrimary : c.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  /// Nut gio hang kem so mat hang, dat o thanh tren.
  ///
  /// De nguoi mua them hang xong la sang gio duoc ngay, khong phai quay lai
  /// man truoc roi tim tab gio.
  Widget _buildCartButton(CartProvider cart) {
    final c = AppColors.of(context);
    final soMatHang = cart.items.length;
    return Stack(
      alignment: Alignment.center,
      children: [
        IconButton(
          icon: Icon(Icons.shopping_bag_outlined, color: c.textPrimary),
          tooltip: 'Giỏ hàng',
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const CartPage()),
            );
          },
        ),
        if (soMatHang > 0)
          Positioned(
            top: AppSpacing.sm,
            right: AppSpacing.sm,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
              decoration: BoxDecoration(
                color: c.danger,
                borderRadius: BorderRadius.circular(AppTheme.radiusSm),
              ),
              constraints: const BoxConstraints(minWidth: 16),
              child: Text(
                soMatHang > 99 ? '99+' : '$soMatHang',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: c.onPrimary,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
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
      backgroundColor: c.background,
      appBar: AppBar(
        title: Text(p.name),
        actions: [
          _buildCartButton(cart),
          IconButton(
            icon: Icon(
              isFav ? Icons.favorite : Icons.favorite_border,
              color: isFav ? c.danger : c.textPrimary,
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
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Danh muc, danh gia
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md,
                          vertical: AppSpacing.xs,
                        ),
                        decoration: BoxDecoration(
                          color: c.primarySoft,
                          borderRadius:
                              BorderRadius.circular(AppTheme.radiusPill),
                        ),
                        child: Text(
                          p.categoryName.toUpperCase(),
                          style: TextStyle(
                              fontSize: 11,
                              color: c.primary,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                      Row(
                        children: [
                          if (p.ratingCount > 0)
                            Text('★ ',
                                style: TextStyle(
                                    color: c.secondary,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16)),
                          Text(
                              p.ratingCount <= 0
                                  ? 'Chưa có đánh giá'
                                  : '${p.ratingAvg.toStringAsFixed(1)} (${p.ratingCount} đánh giá)',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  color: p.ratingCount <= 0
                                      ? c.textSecondary
                                      : c.textPrimary)),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // Ten san pham
                  Text(
                    p.name,
                    style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        letterSpacing: -0.3,
                        height: 1.3,
                        color: c.textPrimary),
                  ),
                  const SizedBox(height: AppSpacing.sm),

                  // Gia tien kem gia gach ngang lam moc neo tam ly.
                  //
                  // LUU Y: gia gach ngang hien dang suy ra tu gia ban nhan he
                  // so ben duoi chu KHONG phai gia goc that trong du lieu. Khi
                  // bang products co cot gia goc rieng thi doi sang doc cot do,
                  // va chi hien khi gia goc thuc su lon hon gia ban.
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        formatPrice(p.price),
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          color: c.danger,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Text(
                        formatPrice((p.price * _heSoGiaNeo).toInt()),
                        style: TextStyle(
                          fontSize: 14,
                          color: c.textMuted,
                          decoration: TextDecoration.lineThrough,
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: AppSpacing.xxl),

                  // 2. CHON KICH CO & MAU SAC THEO DANG DROPDOWN
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Chọn phân loại sản phẩm',
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: c.textPrimary),
                      ),
                      TextButton(
                        style: TextButton.styleFrom(
                            visualDensity: VisualDensity.compact,
                            padding: EdgeInsets.zero),
                        onPressed: () => _showSizeGuideModal(context),
                        child: Text('Bảng quy đổi size',
                            style: TextStyle(
                                fontSize: 12,
                                color: c.primary,
                                fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // CHON KICH CO
                  _buildSizeChips(availableSizes),
                  const SizedBox(height: AppSpacing.md),

                  // CHON MAU SAC
                  if (_loadingDetail && p.variants.isEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.md),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: c.primary),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Text('Đang tải phân loại sản phẩm...',
                              style: TextStyle(
                                  fontSize: 12, color: c.textMuted)),
                        ],
                      ),
                    )
                  else if (p.variants.isEmpty || availableSizes.isEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.md),
                      child: Text(
                        p.variants.isEmpty
                            ? 'Sản phẩm chưa có biến thể hàng hóa.'
                            : 'Sản phẩm hiện đã hết hàng.',
                        style: TextStyle(color: c.danger),
                      ),
                    ),
                  _buildColorChips(availableColors),
                  if (selectedVariant != null && selectedVariant.stock > 0)
                    Padding(
                      padding: const EdgeInsets.only(top: AppSpacing.sm),
                      child: Text(
                        'Còn ${selectedVariant.stock} sản phẩm cho phân loại này',
                        style: TextStyle(
                            fontSize: 12, color: c.textSecondary),
                      ),
                    ),
                  const SizedBox(height: AppSpacing.xl),

                  // 3. CHON SO LUONG
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Số lượng:',
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: c.textPrimary)),
                      Container(
                        decoration: BoxDecoration(
                          color: c.surface,
                          border: Border.all(color: c.border),
                          borderRadius:
                              BorderRadius.circular(AppTheme.radiusPill),
                        ),
                        child: Row(
                          children: [
                            IconButton(
                              icon: Text('-',
                                  style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: c.textPrimary)),
                              onPressed: () {
                                if (_quantity > 1) {
                                  setState(() => _quantity--);
                                }
                              },
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: AppSpacing.md),
                              child: Text('$_quantity',
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                      color: c.textPrimary)),
                            ),
                            IconButton(
                              icon: Text('+',
                                  style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: c.textPrimary)),
                              onPressed: _quantity < maxQuantity
                                  ? () => setState(() => _quantity++)
                                  : null,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: AppSpacing.xxxl),

                  // 4. CHINH SACH THOI TRANG MENLY
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    decoration: _contentCardDecoration(c),
                    child: const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ProductPerkItem(
                            title: 'Đổi trả 30 ngày',
                            subtitle: 'Miễn phí đổi size/màu tận nhà'),
                        Divider(height: AppSpacing.lg),
                        ProductPerkItem(
                            title: 'Giao nhanh 24h',
                            subtitle: 'Nội thành nhận ngay trong ngày'),
                        Divider(height: AppSpacing.lg),
                        ProductPerkItem(
                            title: 'Chất lượng cam kết',
                            subtitle:
                                '100% Cotton chải kỹ, thoáng mát, bền form'),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xxl),

                  // 5. MO TA CHI TIET
                  const SectionHeader(title: 'Mô tả sản phẩm'),
                  const SizedBox(height: AppSpacing.md),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    decoration: _contentCardDecoration(c),
                    child: Text(
                      p.description.trim().isEmpty
                          ? 'Sản phẩm chưa có mô tả chi tiết.'
                          : p.description,
                      style: TextStyle(
                          fontSize: 14,
                          height: 1.6,
                          color: c.textSecondary),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xxxl),
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    decoration: _contentCardDecoration(c),
                    child: ProductReviewsSection(
                      productId: p.id,
                      productName: p.name,
                      thumbnailUrl: p.thumbnailUrl,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xxl),
                  ProductRelatedGrid(
                    product: _product,
                    relatedProducts: _relatedProducts,
                    wishlist: wishlist,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                ],
              ),
            ),
          ],
        ),
      ),

      // Thanh thao tac duoi cung: Nut Them vao gio & Nut Mua ngay
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: c.surface,
          boxShadow: [
            // Bong rat nhe, chi de tach thanh thao tac khoi noi dung cuon
            BoxShadow(
              color: c.shadow,
              blurRadius: 10,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          child: Row(
            children: [
              Expanded(
                child: SecondaryButton(
                  height: _actionButtonHeight,
                  label: 'Thêm vào giỏ',
                  onPressed: canPurchase
                      ? () async {
                          final added = await cart.addToCart(
                            p,
                            size: _selectedSize,
                            color: _selectedColor,
                            quantity: _quantity,
                          );
                          if (!context.mounted) return;

                          final messenger = ScaffoldMessenger.of(context);
                          messenger.hideCurrentSnackBar();
                          messenger.showSnackBar(
                            SnackBar(
                              content: Text(added
                                  ? 'Đã thêm $_quantity x "${p.name}" (Size: $_selectedSize, Màu: $_selectedColor) vào giỏ hàng'
                                  : cart.errorMessage ??
                                      'Không thể thêm sản phẩm vào giỏ'),
                              backgroundColor:
                                  added ? c.primary : c.danger,
                              duration: const Duration(seconds: 2),
                            ),
                          );
                        }
                      : null,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: PrimaryButton(
                  height: _actionButtonHeight,
                  label: 'Mua ngay',
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
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
