import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:menly_app/features/auth/presentation/pages/login_page.dart';

void main() {
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
