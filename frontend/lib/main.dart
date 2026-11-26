import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/theme/theme_controller.dart';
import 'core/utils/app_logger.dart';
import 'features/address/presentation/providers/address_provider.dart';
import 'features/auth/presentation/providers/auth_provider.dart';
import 'features/cart/presentation/providers/cart_provider.dart';
import 'features/notification/presentation/providers/notification_provider.dart';
import 'features/onboarding/presentation/pages/splash_page.dart';
import 'features/order/presentation/providers/order_provider.dart';
import 'features/product/presentation/providers/product_provider.dart';
import 'features/review/presentation/providers/review_provider.dart';
import 'features/voucher/presentation/providers/voucher_provider.dart';
import 'features/wishlist/presentation/providers/wishlist_provider.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Loi widget: van de Flutter in man hinh do nhu cu, nhung ghi them vao log
  // de con doc lai duoc sau khi man hinh do da bien mat.
  final xuLyCu = FlutterError.onError;
  FlutterError.onError = (chiTiet) {
    AppLogger.loi(
      'Lỗi widget: ${chiTiet.exceptionAsString()}',
      khuVuc: 'Flutter',
      loi: chiTiet.exception,
      stackTrace: chiTiet.stack,
    );
    xuLyCu?.call(chiTiet);
  };

  // Loi khong ai bat o tang duoi (Future bi quen await, loi tu nen tang).
  // Khong co dong nay thi nhung loi do bien mat hoan toan.
  PlatformDispatcher.instance.onError = (loi, stackTrace) {
    AppLogger.loi(
      'Lỗi không ai bắt',
      khuVuc: 'Flutter',
      loi: loi,
      stackTrace: stackTrace,
    );
    // true = da xu ly xong, dung lam sap app.
    return true;
  };

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
        ChangeNotifierProvider(create: (_) => ReviewProvider()),
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
            home: const SplashPage(),
          );
        },
      ),
    );
  }
}

