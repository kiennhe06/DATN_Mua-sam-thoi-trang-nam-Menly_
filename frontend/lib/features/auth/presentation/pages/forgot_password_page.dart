import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:menly_app/core/network/api_client.dart';
import 'package:menly_app/core/theme/app_colors.dart';
import 'package:menly_app/core/theme/app_spacing.dart';
import 'package:menly_app/core/widgets/app_buttons.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _isSubmitting = false;

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      await ApiClient().dio.post(
        '/auth/forgot-password',
        data: {'email': _emailController.text.trim()},
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Yêu cầu đặt lại mật khẩu đã được gửi. Hãy kiểm tra email của bạn.'),
          backgroundColor: AppColors.of(context).success,
        ),
      );
      Navigator.of(context).pop();
    } on DioException catch (e) {
      final message = e.response?.data['error']?.toString() ??
          'Không thể gửi yêu cầu đặt lại mật khẩu. Vui lòng thử lại.';
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: AppColors.of(context).danger,
        ),
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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quên mật khẩu'),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.xxl),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: AppSpacing.xl),
                    const Text(
                      'Khôi phục mật khẩu',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      'Nhập email đã đăng ký để gửi hướng dẫn đặt lại mật khẩu.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: c.textMuted, fontSize: 15),
                    ),
                    const SizedBox(height: AppSpacing.xxl),
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(labelText: 'Email'),
                      validator: (value) {
                        final email = value?.trim() ?? '';
                        if (email.isEmpty) return 'Vui lòng nhập email';
                        if (!email.contains('@')) return 'Email không hợp lệ';
                        return null;
                      },
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    PrimaryButton(
                      label: _isSubmitting ? 'Đang gửi...' : 'Gửi hướng dẫn',
                      onPressed: _isSubmitting ? null : _submit,
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
