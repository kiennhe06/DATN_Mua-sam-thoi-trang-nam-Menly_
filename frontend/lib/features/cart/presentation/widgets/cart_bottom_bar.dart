import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
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
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 14),
      decoration: BoxDecoration(
        color: c.surface,
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
                  color: c.secondary,
                  fontSize: 19,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          PrimaryButton(
            label: hasSelection
                ? 'Thanh toán ($selectedCount món)'
                : 'Chọn sản phẩm để mua',
            onPressed: hasSelection ? onCheckout : null,
          ),
        ],
      ),
    );
  }
}
