import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../support/presentation/pages/about_page.dart';
import '../../../support/presentation/pages/contact_page.dart';
import '../../../support/presentation/pages/faq_page.dart';
import '../../../support/presentation/pages/policy_page.dart';

class HomeInfoFooter extends StatelessWidget {
  const HomeInfoFooter({super.key});

  /// Nut chu dang vien thuoc, dung chung cho ca bon duong dan ho tro.
  Widget _linkButton(
    BuildContext context, {
    required String label,
    required WidgetBuilder page,
  }) {
    return TextButton(
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusPill),
        ),
      ),
      onPressed: () => Navigator.push(
        context,
        MaterialPageRoute(builder: page),
      ),
      child: Text(label, style: const TextStyle(fontSize: 12)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.lg,
        AppSpacing.lg,
      ),
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.xxl,
        AppSpacing.lg,
        AppSpacing.xl,
      ),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusXl),
        border: Border.all(color: c.border),
        boxShadow: [
          BoxShadow(
            color: c.shadow,
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            'MENLY FASHION',
            style: TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 13,
              letterSpacing: 1.5,
              color: c.textPrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Thương hiệu thời trang nam cao cấp',
            style: TextStyle(fontSize: 11, color: c.textSecondary),
          ),
          const SizedBox(height: AppSpacing.lg),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xs,
            children: [
              _linkButton(
                context,
                label: 'Giới thiệu',
                page: (_) => const AboutPage(),
              ),
              _linkButton(
                context,
                label: 'Liên hệ',
                page: (_) => const ContactPage(),
              ),
              _linkButton(
                context,
                label: 'Chính sách',
                page: (_) => const PolicyPage(),
              ),
              _linkButton(
                context,
                label: 'Hỏi đáp',
                page: (_) => const FAQPage(),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
