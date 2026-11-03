import 'package:menly_app/core/utils/app_snackbar.dart';
import 'package:menly_app/core/widgets/product_card.dart';
import 'package:menly_app/features/cart/presentation/providers/cart_provider.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:menly_app/core/theme/app_theme.dart';
import 'package:menly_app/models/product_model.dart';
import 'package:menly_app/features/address/presentation/pages/address_page.dart';
import 'package:menly_app/features/auth/presentation/pages/change_password_page.dart';
import 'package:menly_app/features/auth/presentation/pages/login_page.dart';
import 'package:menly_app/features/order/presentation/pages/my_orders_page.dart';
import 'package:menly_app/features/order/presentation/pages/staff_order_management_page.dart';
import 'package:menly_app/features/product/presentation/pages/product_detail_page.dart';
import 'package:menly_app/features/product/presentation/pages/product_list_page.dart';
import 'package:menly_app/features/product/presentation/pages/search_page.dart';
import 'package:menly_app/features/product/presentation/providers/product_provider.dart';
import 'package:menly_app/features/support/presentation/pages/about_page.dart';
import 'package:menly_app/features/support/presentation/pages/contact_page.dart';
import 'package:menly_app/features/support/presentation/pages/faq_page.dart';
import 'package:menly_app/features/support/presentation/pages/policy_page.dart';
import 'package:menly_app/features/voucher/presentation/pages/voucher_list_page.dart';
import 'package:menly_app/features/wishlist/presentation/providers/wishlist_provider.dart';

/// Trang chu Menly - Giao dien Thoi trang nam cao cap (AP-BN1, TM11, TM02, TM03, TM10, TM05)
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final PageController _bannerController = PageController();
  int _currentBannerIndex = 0;
  Timer? _bannerTimer;

  @override
  void initState() {
    super.initState();
    _startBannerAutoScroll();
  }

  void _startBannerAutoScroll() {
    _bannerTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
      final productProv = context.read<ProductProvider>();
      if (productProv.banners.isNotEmpty && _bannerController.hasClients) {
        _currentBannerIndex = (_currentBannerIndex + 1) % productProv.banners.length;
        _bannerController.animateToPage(
          _currentBannerIndex,
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeInOutCubic,
        );
      }
    });
  }

  @override
  void dispose() {
    _bannerTimer?.cancel();
    _bannerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final productProv = context.watch<ProductProvider>();
    final wishlistProv = context.watch<WishlistProvider>();

    return Scaffold(
      backgroundColor: AppTheme.scaffoldBackground,
      appBar: AppBar(
        titleSpacing: 16,
        backgroundColor: Colors.white,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: AppTheme.primary,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'MENLY',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 16,
                  letterSpacing: 2.0,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'FASHION FOR MEN',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.2,
                    color: AppTheme.textSecondary,
                  ),
                ),
                Text(
                  'Chuẩn mực phái mạnh',
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const VoucherListPage())),
            child: const Text('Voucher', style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.accentOrange, fontSize: 13)),
          ),
          TextButton(
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LoginPage())),
            child: const Text('Tài khoản', style: TextStyle(fontWeight: FontWeight.w600, color: AppTheme.textPrimary, fontSize: 13)),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => productProv.init(),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. THANH TIM KIEM HIEN DAI
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                child: InkWell(
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SearchPage())),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppTheme.border),
                      boxShadow: AppTheme.softShadow,
                    ),
                    child: const Row(
                      children: [
                        Text(
                          'Tìm áo polo, sơ mi, quần âu, blazer...',
                          style: TextStyle(color: AppTheme.textMuted, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // 2. HERO BANNER CAROUSEL
              if (productProv.banners.isNotEmpty) ...[
                SizedBox(
                  height: 190,
                  child: PageView.builder(
                    controller: _bannerController,
                    itemCount: productProv.banners.length,
                    onPageChanged: (idx) => setState(() => _currentBannerIndex = idx),
                    itemBuilder: (ctx, i) {
                      final b = productProv.banners[i];
                      return Container(
                        margin: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          image: DecorationImage(
                            image: NetworkImage(b.imageUrl),
                            fit: BoxFit.cover,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.12),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Container(
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            gradient: LinearGradient(
                              colors: [
                                Colors.black.withValues(alpha: 0.8),
                                Colors.transparent,
                              ],
                              begin: Alignment.bottomLeft,
                              end: Alignment.topRight,
                            ),
                          ),
                          alignment: Alignment.bottomLeft,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: AppTheme.accentRed,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Text(
                                  'BỘ SƯU TẬP MỚI',
                                  style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                b.title,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                  shadows: [Shadow(color: Colors.black54, blurRadius: 4)],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                // Indicator dots
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    productProv.banners.length,
                    (idx) => AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      width: _currentBannerIndex == idx ? 22 : 6,
                      height: 6,
                      margin: const EdgeInsets.symmetric(horizontal: 3, vertical: 8),
                      decoration: BoxDecoration(
                        color: _currentBannerIndex == idx ? AppTheme.primary : Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ),
                ),
              ],



              // 4. DANH MUC & TIEN ICH NHANH
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildQuickAction(
                      label: 'Voucher',
                      color: AppTheme.accentOrange,
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const VoucherListPage())),
                    ),
                    _buildQuickAction(
                      label: 'Đơn của tôi',
                      color: AppTheme.primaryAccent,
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MyOrdersPage())),
                    ),
                    _buildQuickAction(
                      label: 'Sổ địa chỉ',
                      color: Colors.teal,
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AddressPage())),
                    ),
                    _buildQuickAction(
                      label: 'Đổi mật khẩu',
                      color: Colors.indigo,
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ChangePasswordPage())),
                    ),
                    _buildQuickAction(
                      label: 'Quản trị viên',
                      color: Colors.purple,
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const StaffOrderManagementPage())),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 10),

              // 5. SECTION: SAN PHAM MOI NHAT (NEW IN)
              _buildSectionHeader(
                title: 'Sản phẩm mới nhất',
                badge: 'NEW IN',
                badgeColor: AppTheme.primary,
                subtitle: 'Bộ sưu tập xu hướng thiết kế tối giản, lịch lãm',
                onSeeAll: () {
                  productProv.setSortBy('newest');
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const ProductListPage()));
                },
              ),
              _buildProductGrid(productProv.newProducts, wishlistProv),

              const SizedBox(height: 16),

              // 6. SECTION: SAN PHAM BAN CHAY (BEST SELLERS)
              _buildSectionHeader(
                title: 'Sản phẩm bán chạy',
                badge: 'HOT TREND',
                badgeColor: AppTheme.accentRed,
                subtitle: 'Những món đồ được quý ông săn đón nhiều nhất',
                onSeeAll: () {
                  productProv.setSortBy('best_seller');
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const ProductListPage()));
                },
              ),
              _buildProductGrid(productProv.bestSellers, wishlistProv),

              const SizedBox(height: 16),

              // 7. SECTION: DA XEM GAN DAY (RECENTLY VIEWED)
              if (productProv.recentlyViewed.isNotEmpty) ...[
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Đã xem gần đây',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17, letterSpacing: -0.2),
                          ),
                          Text('Các sản phẩm bạn vừa tham khảo', style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                        ],
                      ),
                      TextButton(
                        onPressed: () => productProv.clearRecentlyViewed(),
                        child: const Text('Xóa lịch sử', style: TextStyle(color: AppTheme.accentRed, fontSize: 12)),
                      ),
                    ],
                  ),
                ),
                _buildProductGrid(productProv.recentlyViewed, wishlistProv),
                const SizedBox(height: 24),
              ],
              _buildInfoFooter(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoFooter() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      padding: const EdgeInsets.fromLTRB(8, 16, 8, 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          const Text('MENLY', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.5)),
          const SizedBox(height: 4),
          Text('Thời trang nam', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
          const SizedBox(height: 8),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 4,
            children: [
              TextButton(
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AboutPage())),
                child: const Text('Giới thiệu'),
              ),
              TextButton(
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ContactPage())),
                child: const Text('Liên hệ'),
              ),
              TextButton(
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PolicyPage())),
                child: const Text('Chính sách'),
              ),
              TextButton(
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const FAQPage())),
                child: const Text('Hỏi đáp'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickAction({
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Text(label.substring(0, 1).toUpperCase(), style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 18)),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.textPrimary),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader({
    required String title,
    required String subtitle,
    required VoidCallback onSeeAll,
    String? badge,
    Color? badgeColor,
  }) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: AppTheme.textPrimary,
                        letterSpacing: -0.3,
                      ),
                    ),
                    if (badge != null) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: badgeColor ?? AppTheme.primary,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          badge,
                          style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(subtitle, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
              ],
            ),
          ),
          TextButton(
            onPressed: onSeeAll,
            style: TextButton.styleFrom(
              padding: EdgeInsets.zero,
              visualDensity: VisualDensity.compact,
            ),
            child: const Row(
              children: [
                Text('Xem tất cả', style: TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold, fontSize: 13)),

              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductGrid(List<ProductModel> items, WishlistProvider wishlistProv) {
    if (items.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Center(child: Text('Đang cập nhật sản phẩm...')),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.58,
          crossAxisSpacing: 14,
          mainAxisSpacing: 14,
        ),
        itemCount: items.length,
        itemBuilder: (ctx, i) {
          final p = items[i];
          final isFav = wishlistProv.isFavorite(p.id);

          return ProductCard(
            product: p,
            isFavorite: isFav,
            badge: p.isNew ? 'MỚI' : (p.isBestSeller ? 'HOT' : null),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => ProductDetailPage(product: p)),
              );
            },
            onToggleFavorite: () => wishlistProv.toggleFavorite(p),
            onAdd: () {
              final cart = context.read<CartProvider>();
              final s = p.variants.isNotEmpty ? p.variants.first.size : 'M';
              final col = p.variants.isNotEmpty ? p.variants.first.color : 'Đen';
              cart.addToCart(p, size: s, color: col, quantity: 1);
              AppSnackBar.show(context, message: 'Đã thêm "${p.name}" vào giỏ');
            },
          );
        },
      ),
    );
  }
}
