import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_theme.dart';

/// Mot o so lieu nhanh (don hang / yeu thich / voucher) o man tai khoan.
///
/// Ca o deu bam duoc nen co icon va vung cham rong, khong chi la con so tron.
class ProfileStatItem extends StatelessWidget {
  final String label;
  final String value;
  final IconData? icon;
  final VoidCallback onTap;

  const ProfileStatItem({
    super.key,
    required this.label,
    required this.value,
    this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
          child: Column(
            children: [
              if (icon != null) ...[
                Icon(icon, size: 18, color: c.textMuted),
                const SizedBox(height: AppSpacing.sm),
              ],
              Text(
                value,
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 20,
                  height: 1,
                  color: c.textPrimary,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                label,
                style: TextStyle(fontSize: 12, color: c.textSecondary),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
