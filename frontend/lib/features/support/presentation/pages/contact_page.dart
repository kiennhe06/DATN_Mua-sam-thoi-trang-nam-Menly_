import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_buttons.dart';
import 'about_page.dart';

/// Trang Lien he ho tro khach hang Menly
class ContactPage extends StatefulWidget {
  const ContactPage({super.key});

  @override
  State<ContactPage> createState() => _ContactPageState();
}

class _ContactPageState extends State<ContactPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _messageController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  void _copyHotline() {
    Clipboard.setData(const ClipboardData(text: '19006868'));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Đã sao chép số hotline 1900 6868')),
    );
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    _nameController.clear();
    _emailController.clear();
    _messageController.clear();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Đã gửi liên hệ. Menly sẽ phản hồi sớm nhất có thể.'),
        backgroundColor: AppColors.of(context).inkCard,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Scaffold(
      backgroundColor: c.background,
      appBar: AppBar(
        title: const Text('Liên hệ'),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          const SupportSectionTitle('Kênh hỗ trợ'),
          _contactTile(
            context,
            title: 'Hotline',
            subtitle: '1900 6868 (8:00 – 22:00 hàng ngày)',
            onTap: _copyHotline,
          ),
          _contactTile(
            context,
            title: 'Email',
            subtitle: 'support@menly.vn',
            onTap: () {
              Clipboard.setData(const ClipboardData(text: 'support@menly.vn'));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Đã sao chép email hỗ trợ')),
              );
            },
          ),
          _contactTile(
            context,
            title: 'Địa chỉ',
            subtitle: '12 Nguyễn Trãi, Quận 5, TP. Hồ Chí Minh',
          ),
          const SizedBox(height: AppSpacing.lg),
          const SupportSectionTitle('Gửi tin nhắn'),
          SupportCard(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Họ tên',
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Nhập họ tên' : null,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'Nhập email';
                      if (!v.contains('@')) return 'Email chưa hợp lệ';
                      return null;
                    },
                  ),
                  const SizedBox(height: AppSpacing.md),
                  TextFormField(
                    controller: _messageController,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      labelText: 'Nội dung',
                      alignLabelWithHint: true,
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Nhập nội dung' : null,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  PrimaryButton(
                    label: 'Gửi liên hệ',
                    height: 48,
                    onPressed: _submit,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _contactTile(
    BuildContext context, {
    required String title,
    required String subtitle,
    VoidCallback? onTap,
  }) {
    final c = AppColors.of(context);
    return SupportCard(
      child: ListTile(
        title: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 14,
            color: c.textPrimary,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(color: c.textSecondary),
        ),
        trailing: onTap == null
            ? null
            : TextButton(
                onPressed: onTap,
                child: Text(
                  'Sao chép',
                  style: TextStyle(fontSize: 12, color: c.primary),
                ),
              ),
        onTap: onTap,
      ),
    );
  }
}
