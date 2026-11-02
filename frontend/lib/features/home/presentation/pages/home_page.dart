import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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
import 'package:menly_app/features/support/presentation/pages/faq_page.dart';
import 'package:menly_app/features/voucher/presentation/pages/voucher_list_page.dart';
import 'package:menly_app/features/wishlist/presentation/providers/wishlist_provider.dart';

/// Trang chu Menly
/// Phu trach boi: Thanh Toan (AP-BN1, TM11, TM02, TM03, TM10, TM05)
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
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
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
      appBar: AppBar(
        titleSpacing: 16,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Text(
                'MENLY',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 16,
                  letterSpacing: 1.5,
                ),
              ),
            ),
            const SizedBox(width: 8),
            const Text(
              'Thời trang nam',
              style: TextStyle(fontSize: 14, color: Colors.grey, fontWeight: FontWeight.normal),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_outline, color: Colors.black87),
            tooltip: 'Tài khoản',
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const LoginPage()));
            },
          ),
          IconButton(
            icon: const Icon(Icons.lock_reset_rounded, color: Colors.black87),
            tooltip: 'Đổi mật khẩu',
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const ChangePasswordPage()));
            },
          ),
          IconButton(
            icon: const Icon(Icons.confirmation_num_outlined, color: Colors.deepOrange),
            tooltip: 'Kho Voucher (TM10)',
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const VoucherListPage()));
            },
          ),
          IconButton(
            icon: const Icon(Icons.help_outline),
            tooltip: 'FAQ (TM05)',
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const FAQPage()));
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => productProv.init(),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Thanh tim kiem nhanh (TM03)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                child: InkWell(
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const SearchPage()));
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.search, color: Colors.grey),
                        SizedBox(width: 8),
                        Text(
                          'Tìm áo sơ mi, áo polo, quần jeans...',
                          style: TextStyle(color: Colors.grey, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // AP-BN1: Banner chay o trang chu app
              if (productProv.banners.isNotEmpty) ...[
                SizedBox(
                  height: 180,
                  child: PageView.builder(
                    controller: _bannerController,
                    itemCount: productProv.banners.length,
                    onPageChanged: (idx) => setState(() => _currentBannerIndex = idx),
                    itemBuilder: (ctx, i) {
                      final b = productProv.banners[i];
                      return Container(
                        margin: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          image: DecorationImage(
                            image: NetworkImage(b.imageUrl),
                            fit: BoxFit.cover,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.1),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(14),
                            gradient: LinearGradient(
                              colors: [Colors.black.withValues(alpha: 0.7), Colors.transparent],
                              begin: Alignment.bottomLeft,
                              end: Alignment.topRight,
                            ),
                          ),
                          alignment: Alignment.bottomLeft,
                          child: Text(
                            b.title,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                // Indicator cham tron
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    productProv.banners.length,
                    (idx) => Container(
                      width: _currentBannerIndex == idx ? 18 : 6,
                      height: 6,
                      margin: const EdgeInsets.symmetric(horizontal: 3, vertical: 8),
                      decoration: BoxDecoration(
                        color: _currentBannerIndex == idx ? Colors.black87 : Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ),
                ),
              ],

              // Danh sach nut chuc nang nhanh
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  alignment: WrapAlignment.spaceBetween,
                  children: [
                    _buildQuickAction(
                      icon: Icons.confirmation_num_outlined,
                      label: 'Voucher',
                      color: Colors.deepOrange,
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const VoucherListPage())),
                    ),
                    _buildQuickAction(
                      icon: Icons.receipt_long_outlined,
                      label: 'Đơn của tôi',
                      color: Colors.blue.shade700,
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MyOrdersPage())),
                    ),
                    _buildQuickAction(
                      icon: Icons.location_on_outlined,
                      label: 'Sổ địa chỉ',
                      color: Colors.teal,
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AddressPage())),
                    ),
                    _buildQuickAction(
                      icon: Icons.person_outline,
                      label: 'Tài khoản',
                      color: Colors.purple,
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LoginPage())),
                    ),
                    _buildQuickAction(
                      icon: Icons.manage_accounts_outlined,
                      label: 'Nhân viên',
                      color: Colors.purple,
                      onTap: () =>
                          Navigator.push(context, MaterialPageRoute(builder: (_) => const StaffOrderManagementPage())),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // TM11: Section San pham moi nhat
              _buildSectionHeader(
                title: 'Sản phẩm mới nhất 🔥',
                subtitle: 'Bộ sưu tập xu hướng mới vừa lên kệ',
                onSeeAll: () {
                  productProv.setSortBy('newest');
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const ProductListPage()));
                },
              ),
              _buildHorizontalProductList(productProv.newProducts, wishlistProv),

              const SizedBox(height: 16),

              // TM11: Section San pham ban chay
              _buildSectionHeader(
                title: 'Sản phẩm bán chạy 👑',
                subtitle: 'Được phái mạnh yêu thích và lựa chọn nhiều nhất',
                onSeeAll: () {
                  productProv.setSortBy('best_seller');
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const ProductListPage()));
                },
              ),
              _buildHorizontalProductList(productProv.bestSellers, wishlistProv),

              const SizedBox(height: 16),

              // TM02: Danh sach Da xem gan day
              if (productProv.recentlyViewed.isNotEmpty) ...[
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Đã xem gần đây 👀', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
                          Text('Các sản phẩm bạn vừa xem qua', style: TextStyle(color: Colors.grey, fontSize: 12)),
                        ],
                      ),
                      TextButton(
                        onPressed: () => productProv.clearRecentlyViewed(),
                        child: const Text('Xóa lịch sử', style: TextStyle(color: Colors.redAccent, fontSize: 12)),
                      ),
                    ],
                  ),
                ),
                _buildHorizontalProductList(productProv.recentlyViewed, wishlistProv),
                const SizedBox(height: 24),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickAction({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: Column(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: color.withValues(alpha: 0.12),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 6),
            Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader({
    required String title,
    required String subtitle,
    required VoidCallback onSeeAll,
  }) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
                Text(subtitle, style: const TextStyle(color: Colors.grey, fontSize: 12)),
              ],
            ),
          ),
          TextButton(
            onPressed: onSeeAll,
            child: const Text('Xem tất cả >', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildHorizontalProductList(List<ProductModel> items, WishlistProvider wishlistProv) {
    if (items.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Center(child: Text('Đang cập nhật sản phẩm...')),
      );
    }

    return SizedBox(
      height: 250,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (ctx, i) {
          final p = items[i];
          final isFav = wishlistProv.isFavorite(p.id);

          return InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => ProductDetailPage(product: p)),
              );
            },
            borderRadius: BorderRadius.circular(12),
            child: Container(
              width: 150,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Stack(
                    children: [
                      ClipRRect(
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                        child: Image.network(
                          p.thumbnailUrl,
                          width: 150,
                          height: 140,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            width: 150,
                            height: 140,
                            color: Colors.grey.shade200,
                            child: const Icon(Icons.checkroom, size: 30),
                          ),
                        ),
                      ),
                      Positioned(
                        top: 6,
                        right: 6,
                        child: CircleAvatar(
                          radius: 14,
                          backgroundColor: Colors.white.withValues(alpha: 0.9),
                          child: IconButton(
                            padding: EdgeInsets.zero,
                            icon: Icon(
                              isFav ? Icons.favorite : Icons.favorite_border,
                              color: isFav ? Colors.red : Colors.black87,
                              size: 16,
                            ),
                            onPressed: () => wishlistProv.toggleFavorite(p),
                          ),
                        ),
                      ),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          p.name,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${p.price} đ',
                          style: const TextStyle(
                            color: Colors.redAccent,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
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
    );
  }
}
