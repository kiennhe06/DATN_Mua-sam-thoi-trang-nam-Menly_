import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:menly_app/features/auth/presentation/pages/login_page.dart';
import 'package:menly_app/features/notification/presentation/pages/notifications_page.dart';
import 'package:menly_app/features/notification/presentation/providers/notification_provider.dart';
import 'package:menly_app/features/voucher/presentation/pages/voucher_list_page.dart';
import 'package:menly_app/features/voucher/presentation/providers/voucher_provider.dart';

void main() {
  test('Kho voucher fallback phai co du lieu khong rong', () {
    final vouchers = VoucherProvider.fallbackVouchers;

    expect(vouchers, isNotEmpty);
    expect(vouchers.any((v) => v.code == 'WELCOME10'), isTrue);
    expect(vouchers.any((v) => v.code == 'SALE50K'), isTrue);
  });

  testWidgets('Kho voucher hien thi danh sach du phong khi dang tai API', (tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => VoucherProvider(autoLoad: false),
        child: const MaterialApp(home: VoucherListPage()),
      ),
    );

    expect(find.text('Kho Voucher'), findsOneWidget);
    expect(find.text('WELCOME10'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Thong bao hien thi uu dai va voucher dang hoat dong', (tester) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => NotificationProvider(autoLoad: false)),
          ChangeNotifierProvider(create: (_) => VoucherProvider(autoLoad: false)),
        ],
        child: const MaterialApp(home: NotificationsPage()),
      ),
    );

    expect(find.text('Ưu đãi và voucher'), findsOneWidget);
    expect(find.text('Giảm 10% cho đơn đầu tiên'), findsOneWidget);
    expect(find.textContaining('WELCOME10'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Trang dang nhap khoi dong duoc trong MaterialApp', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: LoginPage(),
      ),
    );

    expect(find.byType(LoginPage), findsOneWidget);
    expect(find.text('Đăng nhập'), findsWidgets);
  });

  testWidgets('Trang dang nhap phai co form, quen mat khau va dang ky', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: LoginPage()));

    expect(find.text('Đăng nhập'), findsWidgets);
    expect(find.text('Quên mật khẩu?'), findsOneWidget);
    expect(find.text('Đăng ký ngay'), findsOneWidget);
  });
}
