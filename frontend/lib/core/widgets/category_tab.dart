import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_theme.dart';
import 'pressable.dart';

/// Chip chon danh muc.
///
/// Dang vien thuoc: dang chon thi to nen ink chu sang, chua chon thi nen the
/// co vien mong. Cung mot kieu chip dung cho moi cho loc trong ung dung.
class CategoryTab extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback? onTap;

  const CategoryTab({
    super.key,
    required this.label,
    this.selected = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Pressable(
      onTap: onTap,
      scale: 0.95,
      borderRadius: BorderRadius.circular(AppTheme.radiusPill),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: selected ? c.primary : c.surface,
          borderRadius: BorderRadius.circular(AppTheme.radiusPill),
          border: Border.all(color: selected ? c.primary : c.border),
        ),
        child: Text(
          label,
          maxLines: 1,
          style: TextStyle(
            color: selected ? c.onPrimary : c.textSecondary,
            fontSize: 13,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            letterSpacing: 0.2,
          ),
        ),
      ),
    );
  }
}
