import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/format.dart';
import '../../../../core/widgets/app_buttons.dart';
import '../providers/cart_provider.dart';

class CartBottomBar extends StatelessWidget {
  final CartProvider cart;
  final VoidCallback onCheckout;

  const CartBottomBar({
    super.key,
    required this.cart,
    required this.onCheckout,
  });

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final selectedCount = cart.selectedItems.length;
    final hasSelection = selectedCount > 0;

    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.xl,
        AppSpacing.xl,
        AppSpacing.xl,
        AppSpacing.lg,
      ),
      // Khoi tong tien bo tron manh o canh tren, bong do rat nhe.
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppTheme.radiusXl),
        ),
        border: Border(top: BorderSide(color: c.border)),
        boxShadow: [
          BoxShadow(
            color: c.shadow,
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Tổng thanh toán:',
                style: TextStyle(color: c.textSecondary, fontSize: 14),
              ),
              Text(
                formatVnd(cart.finalTotal),
                style: TextStyle(
                  // Tong tien to mau ink giong gia trong the san pham
                  color: c.textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          PrimaryButton(
            label: hasSelection
                ? 'Thanh toán ($selectedCount món)'
                : 'Chọn sản phẩm để mua',
            height: 56,
            onPressed: hasSelection ? onCheckout : null,
          ),
        ],
      ),
    );
  }
}
