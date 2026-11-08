import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../widgets/app_bottom_nav.dart';
import '../../features/auth/presentation/pages/profile_page.dart';
import '../../features/cart/presentation/pages/cart_page.dart';
import '../../features/cart/presentation/providers/cart_provider.dart';
import '../../features/home/presentation/pages/home_page.dart';
import '../../features/product/presentation/providers/product_provider.dart';
import '../../features/wishlist/presentation/pages/wishlist_page.dart';

class TabSwitchNotification extends Notification {
  final int targetIndex;
  const TabSwitchNotification(this.targetIndex);
}

/// Khung dieu huong chinh voi thanh AppBottomNav (4 tab: Trang chu, Yeu thich,
/// Gio hang, Ca nhan)
class MainNavigationShell extends StatefulWidget {
  const MainNavigationShell({super.key});

  @override
  State<MainNavigationShell> createState() => _MainNavigationShellState();
}

class _MainNavigationShellState extends State<MainNavigationShell> {
  int _currentIndex = 0;

  final List<Widget> _pages = const [
    HomePage(),
    WishlistPage(),
    CartPage(),
    ProfilePage(),
  ];

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();
    return NotificationListener<TabSwitchNotification>(
      onNotification: (notif) {
        setState(() => _currentIndex = notif.targetIndex);
        return true;
      },
      child: Scaffold(
        extendBody: false,
        body: IndexedStack(
          index: _currentIndex,
          children: _pages,
        ),
        bottomNavigationBar: AppBottomNav(
          currentIndex: _currentIndex,
          onTap: (idx) {
            if (idx == 0) {
              final productProv = context.read<ProductProvider>();
              productProv.clearSearchQuery();
              // IndexedStack giu nguyen trang chu nen no khong tu dung lai.
              // Quay ve tab nay thi lay du lieu moi, de san pham vua them hoac
              // vua duyet ben web hien ra ngay.
              productProv.refreshIfStale();
            }
            setState(() => _currentIndex = idx);
          },
          items: [
            const BottomNavItem(
              Icons.home_outlined,
              label: 'Trang chủ',
            ),
            const BottomNavItem(
              Icons.favorite_border,
              label: 'Yêu thích',
            ),
            BottomNavItem(
              Icons.shopping_bag_outlined,
              badge: cart.totalItemCount,
              label: 'Giỏ hàng',
            ),
            const BottomNavItem(
              Icons.person_outline,
              label: 'Cá nhân',
            ),
          ],
        ),
      ),
    );
  }
}
