import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import 'pressable.dart';

/// Tab chon danh muc.
///
/// Chi la chu voi mot gach chan mong khi duoc chon, khong to nen. Danh muc la
/// thu de loc nhanh chu khong phai noi dung chinh, nen khong can hut mat.
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
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        alignment: Alignment.center,
        padding: const EdgeInsets.only(bottom: 5),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: selected ? c.textPrimary : Colors.transparent,
              width: 2,
            ),
          ),
        ),
        child: Text(
          label,
          maxLines: 1,
          style: TextStyle(
            color: selected ? c.textPrimary : c.textSecondary,
            fontSize: 13,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
            letterSpacing: 0.2,
          ),
        ),
      ),
    );
  }
}
