import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_buttons.dart';
import '../providers/cart_provider.dart';

class CartClearDialog {
  static void show(BuildContext context, CartProvider cart) {
    final c = AppColors.of(context);
    showModalBottomSheet(
      context: context,
      backgroundColor: c.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => Padding(
        padding: EdgeInsets.fromLTRB(
          24,
          16,
          24,
          MediaQuery.of(context).padding.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: c.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Xóa toàn bộ giỏ hàng?',
              style: TextStyle(
                color: c.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Tất cả sản phẩm trong giỏ sẽ bị xóa. Thao tác này không thể hoàn tác.',
              textAlign: TextAlign.center,
              style: TextStyle(color: c.textSecondary, fontSize: 13.5, height: 1.4),
            ),
            const SizedBox(height: 24),
            DestructiveButton(
              label: 'Xóa toàn bộ',
              onPressed: () {
                cart.clearCart();
                Navigator.pop(context);
              },
            ),
            const SizedBox(height: 10),
            SecondaryButton(
              label: 'Giữ lại',
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }
}
