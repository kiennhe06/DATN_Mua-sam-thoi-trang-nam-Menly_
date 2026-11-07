import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import 'pressable.dart';

/// Nut "CHON MUA" duoi moi the san pham.
///
/// Vien mong tren nen trong thay vi nen dac: the san pham nam trang tren nen
/// kem nen mot nut dac se keo het su chu y khoi anh san pham.
class AddToCartButton extends StatelessWidget {
  final VoidCallback? onTap;
  final String label;
  final double height;

  const AddToCartButton({
    super.key,
    required this.onTap,
    this.label = 'CHỌN MUA',
    this.height = 36,
  });

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Pressable(
      onTap: onTap,
      scale: 0.96,
      borderRadius: BorderRadius.circular(AppTheme.radiusSm),
      child: Container(
        height: height,
        width: double.infinity,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          border: Border.all(color: c.textPrimary),
          borderRadius: BorderRadius.circular(AppTheme.radiusSm),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: c.textPrimary,
            fontSize: 10.5,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.3,
          ),
        ),
      ),
    );
  }
}
