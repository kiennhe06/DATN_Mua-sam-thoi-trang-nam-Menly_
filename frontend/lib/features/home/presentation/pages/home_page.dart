import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:menly_app/core/navigation/main_navigation_shell.dart';
import 'package:menly_app/core/theme/app_colors.dart';
import 'package:menly_app/core/theme/app_spacing.dart';
import 'package:menly_app/core/widgets/category_tab.dart';
import 'package:menly_app/core/widgets/section_header.dart';
import 'package:menly_app/core/widgets/state_views.dart';
import 'package:menly_app/core/widgets/product_card.dart';
import 'package:menly_app/features/product/presentation/pages/search_page.dart';
import 'package:menly_app/features/product/data/models/product_model.dart';
import 'package:menly_app/features/auth/presentation/pages/login_page.dart';
import 'package:menly_app/features/auth/presentation/pages/profile_page.dart';
import 'package:menly_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:menly_app/features/auth/presentation/widgets/profile_avatar.dart';
import 'package:menly_app/features/notification/presentation/widgets/notification_bell_button.dart';
import 'package:menly_app/features/cart/presentation/providers/cart_provider.dart';
import 'package:menly_app/features/product/presentation/pages/product_detail_page.dart';
import 'package:menly_app/features/product/presentation/pages/product_list_page.dart';
import 'package:menly_app/features/product/presentation/providers/product_provider.dart';
import 'package:menly_app/features/wishlist/presentation/providers/wishlist_provider.dart';
import '../widgets/home_banner_slider.dart';
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

class _HomePageState extends State<HomePage> with WidgetsBindingObserver {
  static const int _homeProductLimit = 8;
  final PageController _bannerController = PageController();
  int _currentBannerIndex = 0;
  Timer? _bannerTimer;
  _HomeTabFilter _tabFilter = _HomeTabFilter.newest;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _startBannerAutoScroll();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<ProductProvider>().clearSearchQuery();
      }
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Quay lai app thi tai lai kho hang: quan tri co the da them hoac xoa san
    // pham tren web trong luc app nam nen. Provider tu bo qua neu vua tai xong.
    if (state == AppLifecycleState.resumed && mounted) {
      context.read<ProductProvider>().refreshIfStale();
    }
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
    WidgetsBinding.instance.removeObserver(this);
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
        // Chua san pham nao du luot danh gia de goi la ban chay: xep theo so
        // danh gia giam dan. Truoc day cho nay tra ve danh sach dao nguoc,
        // tuc la dung nhung san pham cu nhat lam "ban chay".
        final byPopularity = [...baseProducts]
          ..sort((a, b) {
            final byCount = b.ratingCount.compareTo(a.ratingCount);
            return byCount != 0 ? byCount : b.ratingAvg.compareTo(a.ratingAvg);
          });
        return byPopularity.take(_homeProductLimit).toList();
    }
  }

  @override
  Widget build(BuildContext context) {
    final productProv = context.watch<ProductProvider>();
    final wishlistProv = context.watch<WishlistProvider>();

    final currentCategory = productProv.selectedCategory;
    // Trang chu luon hien thi toan bo san pham theo danh muc, khong bi kẹt boi query tim kiem
    final baseProducts = productProv.getCategoryProducts(currentCategory);
    final displayedProducts = _filterProducts(baseProducts);
    final c = AppColors.of(context);

    return Scaffold(
      backgroundColor: c.background,
      appBar: AppBar(
        backgroundColor: c.background,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        titleSpacing: 0,
        leading: IconButton(
          tooltip: 'Tìm kiếm',
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const SearchPage()),
          ),
          icon: Icon(Icons.search, color: c.textPrimary, size: 22),
        ),
        // Khoang dem trai bu lai khoang cach chu cuoi, de chu nam dung giua
        title: Padding(
          padding: const EdgeInsets.only(left: 5.5),
          child: Text(
            'MENLY',
            style: TextStyle(
              color: c.textPrimary,
              fontSize: 17,
              fontWeight: FontWeight.w600,
              letterSpacing: 5.5,
            ),
          ),
        ),
        actions: [
          const NotificationBellButton(),
          Consumer<CartProvider>(
            builder: (_, cart, __) => IconButton(
              tooltip: 'Giỏ hàng',
              onPressed: () => const TabSwitchNotification(2).dispatch(context),
              icon: Badge.count(
                count: cart.totalItemCount,
                isLabelVisible: cart.totalItemCount > 0,
                backgroundColor: c.danger,
                textColor: c.onPrimary,
                textStyle:
                    const TextStyle(fontSize: 9.5, fontWeight: FontWeight.w700),
                child: Icon(
                  Icons.shopping_bag_outlined,
                  color: c.textPrimary,
                  size: 22,
                ),
              ),
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
                if (auth.isLoggedIn) {
                  return ProfileAvatar(
                    avatarUrl: auth.user?.avatarUrl,
                    radius: 12,
                    fallbackText: auth.user?.fullName ?? 'M',
                  );
                }
                return Icon(
                  Icons.person_outline_rounded,
                  color: c.textPrimary,
                  size: 23,
                );
              },
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Divider(height: 1, thickness: 1, color: c.border),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          productProv.clearSearchQuery();
          await productProv.init();
        },
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
                padding: const EdgeInsets.only(
                  top: AppSpacing.sm,
                  bottom: AppSpacing.md,
                ),
                child: SizedBox(
                  height: 40,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding:
                        const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                    itemCount: productProv.categories.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(width: AppSpacing.sm),
                    itemBuilder: (ctx, i) {
                      final cat = productProv.categories[i];
                      final isSelected = currentCategory == cat;
                      return CategoryTab(
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
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.sm,
                  AppSpacing.lg,
                  AppSpacing.md,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Tieu de khoi dung chung: chu dam ben trai, "Xem tat ca"
                    // nho ben phai.
                    SectionHeader(
                      title: (currentCategory == 'Tất cả'
                              ? 'Tất cả sản phẩm'
                              : currentCategory)
                          .toUpperCase(),
                      actionLabel: 'Xem tất cả',
                      onAction: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const ProductListPage()),
                        );
                      },
                    ),
                    const SizedBox(height: AppSpacing.md),
                    // Bo loc tab hang ngang o ben duoi: Chi giu san pham moi va ban chay
                    Row(
                      children: [
                        HomeFilterTab(
                          label: 'Mới',
                          active: _tabFilter == _HomeTabFilter.newest,
                          onTap: () => setState(
                              () => _tabFilter = _HomeTabFilter.newest),
                        ),
                        const SizedBox(width: AppSpacing.sm),
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

              // Khoang tho cuoi trang
              const SizedBox(height: AppSpacing.xxl),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProductGrid(
      List<ProductModel> items, WishlistProvider wishlistProv) {
    if (items.isEmpty) {
      return StatusView(
        icon: Icons.search_off_rounded,
        title: 'Không tìm thấy sản phẩm trong danh mục này',
        actionLabel: 'Xem tất cả sản phẩm',
        onAction: () => context.read<ProductProvider>().setCategory('Tất cả'),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        // Nhieu khoang trang giua cac the de luoi san pham tho hon.
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.5,
          crossAxisSpacing: AppSpacing.lg,
          mainAxisSpacing: AppSpacing.xl,
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
