import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/format.dart';
import 'package:menly_app/features/cart/data/models/cart_item_model.dart';
import 'package:menly_app/core/widgets/app_image.dart';

class CartItemCard extends StatelessWidget {
  final CartItemModel item;
  final VoidCallback onRemove;
  final ValueChanged<int> onQtyChange;
  final bool selected;
  final VoidCallback onToggleSelected;

  const CartItemCard({
    super.key,
    required this.item,
    required this.onRemove,
    required this.onQtyChange,
    required this.selected,
    required this.onToggleSelected,
  });

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final thumb = item.product.thumbnailUrl;

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.lg),
      // Moi dong gio hang la mot the trang bo tron manh, bong do rat nhe de
      // the noi nhe tren nen be ma van giu ve phang cua he thiet ke.
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusXl),
        border: Border.all(color: c.border),
        boxShadow: [
          BoxShadow(
            color: c.shadow,
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Checkbox chon san pham de thanh toan
          GestureDetector(
            onTap: onToggleSelected,
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding: const EdgeInsets.only(right: AppSpacing.md),
              child: Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: selected ? c.primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                  border: Border.all(
                    color: selected ? c.primary : c.border,
                    width: 1.6,
                  ),
                ),
                child: selected
                    ? Center(
                        child: Text(
                          '✓',
                          style: TextStyle(
                            color: c.onPrimary,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      )
                    : null,
              ),
            ),
          ),

          // Anh san pham
          ClipRRect(
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            child: SizedBox(
              width: 72,
              height: 72,
              child: AppImage(
                url: thumb,
                fit: BoxFit.cover,
                placeholder: (context) => Container(
                  color: c.surfaceVariant,
                  child: Center(
                    child: CircularProgressIndicator(
                      color: c.primary,
                      strokeWidth: 2,
                    ),
                  ),
                ),
                errorWidget: (context) => _placeholder(context),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.lg),

          // Thong tin san pham & So luong
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Tang 1: ten san pham
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        item.product.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: c.textPrimary,
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                          height: 1.35,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    GestureDetector(
                      onTap: onRemove,
                      behavior: HitTestBehavior.opaque,
                      child: Padding(
                        padding: const EdgeInsets.only(
                          left: AppSpacing.xs,
                          bottom: AppSpacing.xs,
                        ),
                        child: Text(
                          'Xóa',
                          style: TextStyle(
                            color: c.danger,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),
                // Tang 2: phan loai
                Text(
                  '${item.size} · ${item.color}',
                  style: TextStyle(color: c.textMuted, fontSize: 12),
                ),
                const SizedBox(height: AppSpacing.md),
                // Tang 3: gia va nut tang giam so luong
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Flexible(
                      child: Text(
                        formatVnd(item.subtotal),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          // Gia to mau ink giong ProductCard
                          color: c.textPrimary,
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    _quantityStepper(context, c),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _placeholder(BuildContext context) {
    final c = AppColors.of(context);
    return Container(
      color: c.surfaceVariant,
      child: Center(
        child: Text(
          item.product.name.isNotEmpty ? item.product.name[0].toUpperCase() : 'M',
          style: TextStyle(
            color: c.textMuted,
            fontSize: 26,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }

  /// Ba phan lien nhau `- [so luong] +`: nut `+` nen dac ink, nut `-` nen nhat
  /// vien mong, so o giua khong vien.
  Widget _quantityStepper(BuildContext context, AppColors c) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _stepButton(
          c,
          '-',
          filled: false,
          onTap: () {
            if (item.quantity > 1) {
              onQtyChange(item.quantity - 1);
            } else {
              onRemove();
            }
          },
        ),
        SizedBox(
          width: 36,
          height: 32,
          child: Center(
            child: Text(
              '${item.quantity}',
              style: TextStyle(
                color: c.textPrimary,
                fontWeight: FontWeight.w700,
                fontSize: 14,
              ),
            ),
          ),
        ),
        _stepButton(
          c,
          '+',
          filled: true,
          onTap: () => onQtyChange(item.quantity + 1),
        ),
      ],
    );
  }

  Widget _stepButton(
    AppColors c,
    String symbol, {
    required bool filled,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: filled ? c.primary : c.surfaceVariant,
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          border: filled ? null : Border.all(color: c.border),
        ),
        child: Center(
          child: Text(
            symbol,
            style: TextStyle(
              color: filled ? c.onPrimary : c.textPrimary,
              fontSize: 17,
              fontWeight: FontWeight.w800,
              height: 1,
            ),
          ),
        ),
      ),
    );
  }
}
