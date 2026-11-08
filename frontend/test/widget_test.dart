import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:menly_app/features/auth/presentation/pages/login_page.dart';
import 'package:menly_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:menly_app/features/auth/presentation/widgets/profile_avatar.dart';
import 'package:menly_app/features/notification/presentation/pages/notifications_page.dart';
import 'package:menly_app/features/notification/presentation/providers/notification_provider.dart';
import 'package:menly_app/features/support/data/support_chat_service.dart';
import 'package:menly_app/features/voucher/presentation/pages/voucher_list_page.dart';
import 'package:menly_app/features/voucher/presentation/providers/voucher_provider.dart';

void main() {
  test('Chat CSKH doc duoc thong tin hoi thoai va tin nhan', () {
    final conversation = SupportConversation.fromJson({
      'id': 'conversation-id',
      'user_id': 'customer-id',
      'last_message': 'Tôi cần hỗ trợ đơn hàng',
      'last_message_at': '2026-11-07T10:00:00Z',
      'unread_staff_count': 2,
      'customer': {
        'full_name': 'Khách hàng Menly',
        'email': 'customer@example.com',
      },
    });
    final message = SupportChatMessage.fromJson({
      'id': 'message-id',
      'conversation_id': conversation.id,
      'sender_id': conversation.userId,
      'sender_role': 'customer',
      'content': 'Tôi cần hỗ trợ đơn hàng',
      'created_at': '2026-11-07T10:00:00Z',
    });

    expect(conversation.customerName, 'Khách hàng Menly');
    expect(conversation.unreadStaffCount, 2);
    expect(message.senderRole, 'customer');
    expect(message.content, conversation.lastMessage);
  });

  test('Avatar co cac lua chon co san va co the xoa avatar', () {
    final user = UserModel(
      id: 'user-1',
      email: 'member@example.com',
      fullName: 'Menly Member',
      avatarUrl: AvatarPreset.presets.first.id,
    );

    expect(AvatarPreset.presets, hasLength(6));
    expect(user.copyWith(clearAvatar: true).avatarUrl, isNull);
  });

  testWidgets('Avatar mau co san hien thi duoc khong can mang', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Wrap(
            children: AvatarPreset.presets
                .map((preset) => ProfileAvatar(avatarUrl: preset.id, radius: 32))
                .toList(),
          ),
        ),
      ),
    );

    expect(find.byType(ProfileAvatar), findsNWidgets(6));
    expect(tester.takeException(), isNull);
  });

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
