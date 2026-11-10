import 'package:flutter/material.dart';

import '../../../../core/widgets/state_views.dart';

/// Trang thai gio hang trong.
///
/// Dung lai [StatusView] de man gio hang co cung bo cuc, cung co chu va cung
/// khoang cach voi moi trang thai rong khac trong ung dung.
class CartEmptyView extends StatelessWidget {
  final VoidCallback? onShopNow;

  const CartEmptyView({super.key, this.onShopNow});

  @override
  Widget build(BuildContext context) {
    return StatusView(
      title: 'Giỏ hàng của bạn đang trống',
      message:
          'Hãy khám phá bộ sưu tập thời trang nam Menly để tìm những sản phẩm phù hợp nhất với bạn.',
      actionLabel: 'Khám phá sản phẩm',
      onAction: onShopNow,
      primaryAction: true,
    );
  }
}
