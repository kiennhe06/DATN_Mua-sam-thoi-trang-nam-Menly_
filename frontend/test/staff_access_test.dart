import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:menly_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:menly_app/features/order/presentation/providers/order_provider.dart';
import 'package:menly_app/features/staff/presentation/pages/staff_profile_page.dart';

class FakeOrderProvider extends OrderProvider {
  @override
  Future<void> loadOrders() async {}

  @override
  Future<void> loadStaffOrders() async {}
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Staff separation & access control tests', () {
    test('Staff UserModel nhan dung vai tro staff', () {
      final staffUser = UserModel(
        id: 'staff-1',
        email: 'quocanh08102006bn@gmail.com',
        fullName: 'Nhân viên 1',
        role: 'staff',
      );

      expect(staffUser.role, 'staff');
      expect(staffUser.email, 'quocanh08102006bn@gmail.com');
    });

    testWidgets('StaffProfilePage hien thi dung thong tin nhan vien va badge Staff',
        (tester) async {
      final staffUser = UserModel(
        id: 'staff-1',
        email: 'quocanh08102006bn@gmail.com',
        fullName: 'Nhân viên 1',
        role: 'staff',
      );

      final authProvider = AuthProvider();
      await authProvider.setUserFromLogin(staffUser);

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: authProvider),
            ChangeNotifierProvider<OrderProvider>(create: (_) => FakeOrderProvider()),
          ],
          child: const MaterialApp(
            home: StaffProfilePage(),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Cổng Nhân Viên Menly'), findsOneWidget);
      expect(find.text('Nhân viên 1'), findsOneWidget);
      expect(find.text('quocanh08102006bn@gmail.com'), findsOneWidget);
      expect(find.text('NHÂN VIÊN CỬA HÀNG (STAFF)'), findsOneWidget);
      expect(find.text('Đổi mật khẩu'), findsOneWidget);
      expect(find.text('Đăng xuất tài khoản'), findsOneWidget);
    });
  });
}

