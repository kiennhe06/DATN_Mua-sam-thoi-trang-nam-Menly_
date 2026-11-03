import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_buttons.dart';

class CartEmptyView extends StatelessWidget {
  final VoidCallback? onShopNow;

  const CartEmptyView({super.key, this.onShopNow});

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: c.surfaceVariant,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  'M',
                  style: TextStyle(
                    color: c.secondary,
                    fontSize: 34,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Giỏ hàng của bạn đang trống',
              style: TextStyle(
                color: c.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Hãy khám phá bộ sưu tập thời trang nam Menly để tìm những sản phẩm phù hợp nhất với bạn.',
              textAlign: TextAlign.center,
              style: TextStyle(color: c.textSecondary, fontSize: 13.5, height: 1.5),
            ),
            const SizedBox(height: 28),
            if (onShopNow != null)
              PrimaryButton(
                label: 'Khám phá sản phẩm',
                expanded: false,
                onPressed: onShopNow,
              ),
          ],
        ),
      ),
    );
  }
}
