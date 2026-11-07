import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../widgets/app_pill_nav.dart';
import '../../features/auth/presentation/pages/profile_page.dart';
import '../../features/cart/presentation/pages/cart_page.dart';
import '../../features/cart/presentation/providers/cart_provider.dart';
import '../../features/home/presentation/pages/home_page.dart';
import '../../features/wishlist/presentation/pages/wishlist_page.dart';

class TabSwitchNotification extends Notification {
  final int targetIndex;
  const TabSwitchNotification(this.targetIndex);
}

/// Khung dieu huong chinh voi thanh Tab AppPillNav noi (4 tab: Trang chu, Yeu thich, Gio hang, Ca nhan)
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
        bottomNavigationBar: AppPillNav(
          currentIndex: _currentIndex,
          onTap: (idx) => setState(() => _currentIndex = idx),
          items: [
            const PillNavItem(
              Icons.home_outlined,
              selectedIcon: Icons.home,
              label: 'Trang chủ',
            ),
            const PillNavItem(
              Icons.favorite_border,
              selectedIcon: Icons.favorite,
              label: 'Yêu thích',
            ),
            PillNavItem(
              Icons.shopping_bag_outlined,
              selectedIcon: Icons.shopping_bag,
              badge: cart.totalItemCount,
              label: 'Giỏ hàng',
            ),
            const PillNavItem(
              Icons.person_outline,
              selectedIcon: Icons.person,
              label: 'Cá nhân',
            ),
          ],
        ),
      ),
    );
  }
}
