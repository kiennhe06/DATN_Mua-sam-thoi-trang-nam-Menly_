import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:menly_app/core/network/api_client.dart';
import 'package:menly_app/core/theme/app_colors.dart';
import 'package:menly_app/core/theme/app_spacing.dart';
import 'package:menly_app/core/widgets/app_buttons.dart';

class ChangePasswordPage extends StatefulWidget {
  const ChangePasswordPage({super.key});

  @override
  State<ChangePasswordPage> createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends State<ChangePasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isSubmitting = false;
  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      await ApiClient().dio.post(
        '/auth/change-password',
        data: {
          'currentPassword': _currentPasswordController.text,
          'newPassword': _newPasswordController.text,
        },
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Đổi mật khẩu thành công.'),
          backgroundColor: AppColors.of(context).success,
        ),
      );
      Navigator.of(context).pop();
    } on DioException catch (e) {
      final message = e.response?.data['error']?.toString() ?? 'Đổi mật khẩu thất bại.';
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
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  /// O nhap mat khau dung chung cho ca ba truong: cung mot kieu o nhap va
  /// cung mot nut Hien / An.
  Widget _oMatKhau({
    required TextEditingController controller,
    required String label,
    required bool obscure,
    required VoidCallback onToggle,
    required FormFieldValidator<String> validator,
  }) {
    final c = AppColors.of(context);
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      decoration: InputDecoration(
        labelText: label,
        suffixIcon: TextButton(
          onPressed: onToggle,
          child: Text(
            obscure ? 'Hiện' : 'Ẩn',
            style: TextStyle(color: c.textMuted, fontWeight: FontWeight.bold),
          ),
        ),
      ),
      validator: validator,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Đổi mật khẩu'),
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
                      'Bảo mật tài khoản',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: AppSpacing.xxl),
                    _oMatKhau(
                      controller: _currentPasswordController,
                      label: 'Mật khẩu hiện tại',
                      obscure: _obscureCurrent,
                      onToggle: () => setState(() => _obscureCurrent = !_obscureCurrent),
                      validator: (value) => (value == null || value.trim().isEmpty)
                          ? 'Vui lòng nhập mật khẩu hiện tại'
                          : null,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    _oMatKhau(
                      controller: _newPasswordController,
                      label: 'Mật khẩu mới',
                      obscure: _obscureNew,
                      onToggle: () => setState(() => _obscureNew = !_obscureNew),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) return 'Vui lòng nhập mật khẩu mới';
                        if (value.length < 6) return 'Mật khẩu mới phải có ít nhất 6 ký tự';
                        return null;
                      },
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    _oMatKhau(
                      controller: _confirmPasswordController,
                      label: 'Xác nhận mật khẩu mới',
                      obscure: _obscureConfirm,
                      onToggle: () => setState(() => _obscureConfirm = !_obscureConfirm),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) return 'Vui lòng xác nhận mật khẩu mới';
                        if (value != _newPasswordController.text) return 'Mật khẩu xác nhận không khớp';
                        return null;
                      },
                    ),
                    const SizedBox(height: AppSpacing.xxl),
                    PrimaryButton(
                      label: _isSubmitting ? 'Đang cập nhật...' : 'Cập nhật mật khẩu',
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
