import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:menly_app/core/theme/app_theme.dart';
import 'package:menly_app/core/widgets/category_pill.dart';
import 'package:menly_app/core/widgets/product_card.dart';
import 'package:menly_app/features/product/data/models/product_model.dart';
import 'package:menly_app/features/auth/presentation/pages/login_page.dart';
import 'package:menly_app/features/auth/presentation/pages/profile_page.dart';
import 'package:menly_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:menly_app/features/notification/presentation/pages/notifications_page.dart';
import 'package:menly_app/features/notification/presentation/providers/notification_provider.dart';
import 'package:menly_app/features/cart/presentation/providers/cart_provider.dart';
import 'package:menly_app/features/product/presentation/pages/product_detail_page.dart';
import 'package:menly_app/features/product/presentation/pages/product_list_page.dart';
import 'package:menly_app/features/product/presentation/providers/product_provider.dart';
import 'package:menly_app/features/voucher/presentation/pages/voucher_list_page.dart';
import 'package:menly_app/features/wishlist/presentation/providers/wishlist_provider.dart';
import '../widgets/home_banner_slider.dart';
import '../widgets/home_search_bar.dart';
import '../widgets/home_filter_tab.dart';
import '../widgets/home_info_footer.dart';
import '../widgets/home_recently_viewed.dart';

enum _HomeTabFilter { newest, bestSeller }

/// Trang chu Menly - Hien thi tron ven toan bo san pham, bo cuc gon gang khong chiem het man hinh
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  static const int _homeProductLimit = 8;
  final PageController _bannerController = PageController();
  int _currentBannerIndex = 0;
  Timer? _bannerTimer;
  _HomeTabFilter _tabFilter = _HomeTabFilter.newest;

  @override
  void initState() {
    super.initState();
    _startBannerAutoScroll();
  }

  void _startBannerAutoScroll() {
    _bannerTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
      final productProv = context.read<ProductProvider>();
      if (productProv.banners.isNotEmpty && _bannerController.hasClients) {
        _currentBannerIndex =
            (_currentBannerIndex + 1) % productProv.banners.length;
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

  List<ProductModel> _filterProducts(List<ProductModel> baseProducts) {
    switch (_tabFilter) {
      case _HomeTabFilter.newest:
        final list = baseProducts.where((p) => p.isNew).toList();
        if (list.isNotEmpty) {
          return list.take(_homeProductLimit).toList();
        }
        return baseProducts.take(_homeProductLimit).toList();
      case _HomeTabFilter.bestSeller:
        final list = baseProducts.where((p) => p.isBestSeller).toList();
        if (list.isNotEmpty) {
          return list.take(_homeProductLimit).toList();
        }
        return baseProducts.reversed.take(_homeProductLimit).toList();
    }
  }

  @override
  Widget build(BuildContext context) {
    final productProv = context.watch<ProductProvider>();
    final wishlistProv = context.watch<WishlistProvider>();

    final currentCategory = productProv.selectedCategory;
    final baseProducts = productProv.products;
    final displayedProducts = _filterProducts(baseProducts);

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
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'FASHION FOR MEN',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.2,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  Text(
                    'Chuẩn mực phái mạnh',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const VoucherListPage()),
            ),
            child: const Text('Voucher',
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.accentOrange,
                    fontSize: 13)),
          ),
          IconButton(
            tooltip: 'Thông báo',
            visualDensity: VisualDensity.compact,
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const NotificationsPage()),
            ),
            icon: Stack(
              clipBehavior: Clip.none,
              children: [
                const Icon(
                  Icons.notifications_outlined,
                  color: AppTheme.textPrimary,
                  size: 22,
                ),
                Consumer<NotificationProvider>(
                  builder: (_, notifProv, __) {
                    if (notifProv.unreadCount > 0) {
                      return Positioned(
                        top: -2,
                        right: -2,
                        child: Container(
                          padding: const EdgeInsets.all(3),
                          decoration: const BoxDecoration(
                            color: AppTheme.accentRed,
                            shape: BoxShape.circle,
                          ),
                          constraints: const BoxConstraints(
                            minWidth: 14,
                            minHeight: 14,
                          ),
                          child: Text(
                            '${notifProv.unreadCount}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Tài khoản',
            visualDensity: VisualDensity.compact,
            onPressed: () {
              final auth = context.read<AuthProvider>();
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => auth.isLoggedIn
                      ? const ProfilePage()
                      : const LoginPage(),
                ),
              );
            },
            icon: Consumer<AuthProvider>(
              builder: (_, auth, __) {
                if (auth.isLoggedIn &&
                    auth.user?.avatarUrl != null &&
                    auth.user!.avatarUrl!.isNotEmpty) {
                  return CircleAvatar(
                    radius: 12,
                    backgroundImage: NetworkImage(auth.user!.avatarUrl!),
                  );
                }
                return const Icon(
                  Icons.person_outline_rounded,
                  color: AppTheme.textPrimary,
                  size: 23,
                );
              },
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => productProv.init(),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. THANH TIM KIEM TINH GON
              const HomeSearchBar(),

              // 2. HERO BANNER THIET KE NHO GON
              HomeBannerSlider(
                controller: _bannerController,
                banners: productProv.banners,
                currentIndex: _currentBannerIndex,
                onPageChanged: (idx) =>
                    setState(() => _currentBannerIndex = idx),
              ),

              // 3. DANH MUC CUON NGANG (Category Pills)
              Padding(
                padding: const EdgeInsets.only(top: 4, bottom: 8),
                child: SizedBox(
                  height: 38,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: productProv.categories.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (ctx, i) {
                      final cat = productProv.categories[i];
                      final isSelected = currentCategory == cat;
                      return CategoryPill(
                        label: cat,
                        selected: isSelected,
                        onTap: () => productProv.setCategory(cat),
                      );
                    },
                  ),
                ),
              ),

              // 4. HEADER DIEU HUONG TOAN BO SAN PHAM & BO LOC TAB HANG NGANG O BEN DUOI
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 6),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          currentCategory == 'Tất cả'
                              ? 'Tất cả sản phẩm'
                              : currentCategory,
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                            color: AppTheme.textPrimary,
                            letterSpacing: -0.2,
                          ),
                        ),
                        InkWell(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const ProductListPage()),
                            );
                          },
                          borderRadius: BorderRadius.circular(6),
                          child: const Padding(
                            padding: EdgeInsets.symmetric(
                                horizontal: 4, vertical: 4),
                            child: Text(
                              'Xem tất cả',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.accentOrange,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // Bo loc tab hang ngang o ben duoi: Chi giu san pham moi va ban chay
                    Row(
                      children: [
                        HomeFilterTab(
                          label: 'Mới',
                          active: _tabFilter == _HomeTabFilter.newest,
                          onTap: () => setState(
                              () => _tabFilter = _HomeTabFilter.newest),
                        ),
                        const SizedBox(width: 20),
                        HomeFilterTab(
                          label: 'Bán chạy',
                          active: _tabFilter == _HomeTabFilter.bestSeller,
                          onTap: () => setState(
                              () => _tabFilter = _HomeTabFilter.bestSeller),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // 5. LUOI 2 COT TOAN BO SAN PHAM
              _buildProductGrid(displayedProducts, wishlistProv),

              // 6. SAN PHAM DA XEM GAN DAY (Neu co)
              HomeRecentlyViewed(
                items: productProv.recentlyViewed,
                onClear: () => productProv.clearRecentlyViewed(),
              ),

              // 7. FOOTER THONG TIN MENLY
              const HomeInfoFooter(),

              // Khoang cach duoi tranh bi che boi AppPillNav noi
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProductGrid(
      List<ProductModel> items, WishlistProvider wishlistProv) {
    if (items.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(32),
        alignment: Alignment.center,
        child: Column(
          children: [
            const Text(
              'Không tìm thấy sản phẩm trong danh mục này',
              style: TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 13,
                  fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () =>
                  context.read<ProductProvider>().setCategory('Tất cả'),
              child: const Text('Xem tất cả sản phẩm',
                  style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.65,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
        ),
        itemCount: items.length,
        itemBuilder: (ctx, i) {
          final p = items[i];
          final isFav = wishlistProv.isFavorite(p.id);

          final badgeText = _tabFilter == _HomeTabFilter.newest ? 'MỚI' : 'HOT';

          return ProductCard(
            product: p,
            isFavorite: isFav,
            badge: badgeText,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => ProductDetailPage(product: p)),
              );
            },
            onToggleFavorite: () => wishlistProv.toggleFavorite(p),
            onAdd: () async {
              final cart = context.read<CartProvider>();
              final productProv = context.read<ProductProvider>();
              final messenger = ScaffoldMessenger.of(context);
              final detail = await productProv.fetchProductDetail(p.id);
              final source = detail ?? p;
              final availableVariants =
                  source.variants.where((variant) => variant.stock > 0);
              if (availableVariants.isEmpty) {
                messenger.showSnackBar(const SnackBar(
                    content: Text('Sản phẩm hiện không có hàng')));
                return;
              }
              final variant = availableVariants.first;
              final added = await cart.addToCart(source,
                  size: variant.size, color: variant.color);
              messenger.showSnackBar(SnackBar(
                content: Text(added
                    ? 'Đã thêm "${p.name}" vào giỏ'
                    : cart.errorMessage ?? 'Không thể thêm sản phẩm vào giỏ'),
              ));
            },
          );
        },
      ),
    );
  }
}
