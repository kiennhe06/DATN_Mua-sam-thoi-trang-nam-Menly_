import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:menly_app/core/network/api_client.dart';
import 'package:menly_app/features/auth/presentation/pages/forgot_password_page.dart';
import 'package:menly_app/features/auth/presentation/pages/register_page.dart';
import 'package:menly_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:menly_app/core/navigation/main_navigation_shell.dart';
import 'package:menly_app/core/navigation/staff_navigation_shell.dart';
import 'package:menly_app/features/cart/presentation/providers/cart_provider.dart';
import 'package:menly_app/features/notification/presentation/providers/notification_provider.dart';
import 'package:menly_app/features/order/presentation/providers/order_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:menly_app/core/session/user_session.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isSubmitting = false;
  bool _obscurePassword = true;

  Future<void> _submitLogin() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final response = await ApiClient().dio.post(
        '/auth/login',
        data: {
          'email': _emailController.text.trim(),
          'password': _passwordController.text,
        },
      );

      final payload = response.data['data'] ?? response.data;
      final accessToken = payload['access_token'] ?? payload['accessToken'];
      final refreshToken = payload['refresh_token'] ?? payload['refreshToken'];

      if (accessToken != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('access_token', accessToken.toString());
        if (refreshToken != null) {
          await prefs.setString('refresh_token', refreshToken.toString());
        }
      }

      if (!mounted) return;

      // Xoa du lieu cua nguoi dung truoc truoc khi nap du lieu nguoi vua dang
      // nhap. Cac provider song suot vong doi ung dung nen khong tu mat.
      clearUserDataInMemory(context);

      // Cap nhat ngay thong tin nguoi dung vao AuthProvider de khi chuyen sang
      // tab Ca nhan khong bi coi la chua dang nhap (khong phai dang nhap lai).
      final userJson = payload['user'];
      String userRole = 'customer';
      if (userJson is Map) {
        final userModel = UserModel.fromJson(Map<String, dynamic>.from(userJson));
        userRole = userModel.role;
        await context.read<AuthProvider>().setUserFromLogin(userModel);
        if (!mounted) return;
        await context.read<NotificationProvider>().loadNotifications();
        if (!mounted) return;
      }
      if (userRole == 'staff') {
        context.read<OrderProvider>().loadStaffOrders();
      } else {
        context.read<CartProvider>().loadCartFromApi();
        context.read<OrderProvider>().loadOrders();
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(userRole == 'staff'
              ? 'Đăng nhập Cổng Nhân Viên thành công.'
              : 'Đăng nhập thành công.'),
          backgroundColor: Colors.green,
        ),
      );
      final Widget destination = userRole == 'staff'
          ? const StaffNavigationShell()
          : const MainNavigationShell();
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => destination),
        (route) => false,
      );
    } on DioException catch (e) {
      final message = e.response?.data['error']?.toString() ?? 'Đăng nhập thất bại. Vui lòng thử lại.';
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Đăng nhập'),
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [

                    const Text(
                      'Chào mừng bạn quay lại',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Đăng nhập để tiếp tục mua sắm tại Menly',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey, fontSize: 15),
                    ),
                    const SizedBox(height: 24),
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        final email = value?.trim() ?? '';
                        if (email.isEmpty) {
                          return 'Vui lòng nhập email';
                        }
                        if (!email.contains('@')) {
                          return 'Email không hợp lệ';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      decoration: InputDecoration(
                        labelText: 'Mật khẩu',
                        
                        border: const OutlineInputBorder(),
                        suffixIcon: TextButton(
                          child: Text(_obscurePassword ? 'Hiện' : 'Ẩn', style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
                          onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                        ),
                      ),
                      validator: (value) {
                        if ((value ?? '').isEmpty) {
                          return 'Vui lòng nhập mật khẩu';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const ForgotPasswordPage()),
                          );
                        },
                        child: const Text('Quên mật khẩu?', style: TextStyle(color: Colors.black87)),
                      ),
                    ),
                    const SizedBox(height: 8),
                    FilledButton(
                      onPressed: _isSubmitting ? null : _submitLogin,
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: Colors.black87,
                      ),
                      child: Text(_isSubmitting ? 'Đang đăng nhập...' : 'Đăng nhập'),
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      alignment: WrapAlignment.center,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        const Text('Bạn chưa có tài khoản?'),
                        TextButton(
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(builder: (_) => const RegisterPage()),
                            );
                          },
                          child: const Text('Đăng ký ngay', style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
