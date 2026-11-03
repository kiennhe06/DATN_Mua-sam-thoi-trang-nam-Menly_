import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import 'pressable.dart';

/// Nut Them gio chuan phong cach toi gian cua he thong Menly.
class AddToCartButton extends StatelessWidget {
  final VoidCallback? onTap;
  final String label;
  final double height;

  const AddToCartButton({
    super.key,
    required this.onTap,
    this.label = 'Thêm giỏ',
    this.height = 36,
  });

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Pressable(
      onTap: onTap,
      scale: 0.96,
      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      child: Container(
        height: height,
        width: double.infinity,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: c.surfaceVariant,
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: c.textPrimary,
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

