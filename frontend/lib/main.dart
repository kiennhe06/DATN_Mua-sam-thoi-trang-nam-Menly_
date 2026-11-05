import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/theme/theme_controller.dart';
import 'core/widgets/app_pill_nav.dart';
import 'features/address/presentation/providers/address_provider.dart';
import 'features/auth/presentation/pages/profile_page.dart';
import 'features/auth/presentation/providers/auth_provider.dart';
import 'features/cart/presentation/pages/cart_page.dart';
import 'features/cart/presentation/providers/cart_provider.dart';
import 'features/home/presentation/pages/home_page.dart';
import 'features/notification/presentation/providers/notification_provider.dart';
import 'features/order/presentation/providers/order_provider.dart';
import 'features/product/presentation/providers/product_provider.dart';
import 'features/voucher/presentation/providers/voucher_provider.dart';
import 'features/wishlist/presentation/pages/wishlist_page.dart';
import 'features/wishlist/presentation/providers/wishlist_provider.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MenlyApp());
}

class MenlyApp extends StatelessWidget {
  const MenlyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeController()..load()),
        ChangeNotifierProvider(create: (_) => AuthProvider()..init()),
        ChangeNotifierProvider(create: (_) => ProductProvider()),
        ChangeNotifierProvider(create: (_) => CartProvider()),
        ChangeNotifierProvider(create: (_) => WishlistProvider()),
        ChangeNotifierProvider(create: (_) => AddressProvider()),
        ChangeNotifierProvider(create: (_) => OrderProvider()),
        ChangeNotifierProvider(create: (_) => VoucherProvider()),
        ChangeNotifierProvider(create: (_) => NotificationProvider()),
      ],
      child: Consumer<ThemeController>(
        builder: (context, themeCtrl, _) {
          return MaterialApp(
            title: 'Menly',
            debugShowCheckedModeBanner: false,
            theme: themeCtrl.lightTheme,
            darkTheme: themeCtrl.darkTheme,
            themeMode: themeCtrl.mode,
            home: const MainNavigationShell(),
          );
        },
      ),
    );
  }
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
    return Scaffold(
      extendBody: true,
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: AppPillNav(
        currentIndex: _currentIndex,
        onTap: (idx) => setState(() => _currentIndex = idx),
        items: const [
          PillNavItem(
            Icons.home_outlined,
            selectedIcon: Icons.home,
            label: 'Trang chủ',
          ),
          PillNavItem(
            Icons.favorite_border,
            selectedIcon: Icons.favorite,
            label: 'Yêu thích',
          ),
          PillNavItem(
            Icons.shopping_bag_outlined,
            selectedIcon: Icons.shopping_bag,
            label: 'Giỏ hàng',
          ),
          PillNavItem(
            Icons.person_outline,
            selectedIcon: Icons.person,
            label: 'Cá nhân',
          ),
        ],
      ),
    );
  }
}
