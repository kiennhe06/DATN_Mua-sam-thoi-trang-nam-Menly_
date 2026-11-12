import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import 'pressable.dart';

/// Nut "CHON MUA" duoi moi the san pham.
///
/// Dang vien thuoc nen dac mau ink, cung ngon ngu voi cac nut hanh dong khac.
/// Vien mong truoc day lam nut chim han xuong, nhin khong ra la nut bam.
class AddToCartButton extends StatelessWidget {
  final VoidCallback? onTap;
  final String label;
  final double height;

  const AddToCartButton({
    super.key,
    required this.onTap,
    this.label = 'CHỌN MUA',
    this.height = 38,
  });

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Pressable(
      onTap: onTap,
      scale: 0.96,
      borderRadius: BorderRadius.circular(AppTheme.radiusPill),
      child: Container(
        height: height,
        width: double.infinity,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: c.primary,
          borderRadius: BorderRadius.circular(AppTheme.radiusPill),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: c.onPrimary,
            fontSize: 10.5,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.3,
          ),
        ),
      ),
    );
  }
}
