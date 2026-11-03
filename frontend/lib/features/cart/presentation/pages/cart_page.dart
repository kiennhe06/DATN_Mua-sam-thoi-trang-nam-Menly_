import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../models/cart_item_model.dart';
import '../providers/cart_provider.dart';
import '../widgets/cart_bottom_bar.dart';
import '../widgets/cart_clear_dialog.dart';
import '../widgets/cart_empty_view.dart';
import '../widgets/cart_item_card.dart';
import 'package:menly_app/features/voucher/presentation/widgets/voucher_select_sheet.dart';
import 'package:menly_app/features/order/presentation/pages/checkout_page.dart';

/// Trang Gio hang Menly cao cap theo phong cach UI/UX toi gian
class CartPage extends StatelessWidget {
  const CartPage({super.key});

  void _proceedToCheckout(BuildContext context, CartProvider cart) {
    final selectedItems = cart.selectedItems;
    if (selectedItems.isEmpty) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CheckoutPage(customItems: selectedItems),
      ),
    );
  }

  void _openVoucherSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const VoucherSelectSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final cart = context.watch<CartProvider>();

    return Scaffold(
      backgroundColor: c.background,
      appBar: AppBar(
        title: Text(
          'Giỏ hàng${cart.totalItemCount > 0 ? " (${cart.totalItemCount})" : ""}',
          style: TextStyle(color: c.textPrimary, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          if (cart.items.isNotEmpty)
            TextButton(
              onPressed: () => CartClearDialog.show(context, cart),
              child: Text(
                'Xóa hết',
                style: TextStyle(color: c.danger, fontWeight: FontWeight.w600, fontSize: 13),
              ),
            ),
        ],
      ),
      body: cart.items.isEmpty
          ? CartEmptyView(
              onShopNow: () {
                // Quay tro ve tab Trang chu
              },
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 120),
              children: [
                // Thanh chon tat ca & Ma giam gia
                Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: c.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: c.border),
                  ),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () => cart.toggleSelectAll(),
                        behavior: HitTestBehavior.opaque,
                        child: Row(
                          children: [
                            Container(
                              width: 22,
                              height: 22,
                              decoration: BoxDecoration(
                                color: cart.isAllSelected ? c.primary : Colors.transparent,
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: cart.isAllSelected ? c.primary : c.border,
                                  width: 1.6,
                                ),
                              ),
                              child: cart.isAllSelected
                                  ? Center(
                                      child: Text(
                                        '✓',
                                        style: TextStyle(
                                          color: c.onPrimary,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13,
                                        ),
                                      ),
                                    )
                                  : null,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Chọn tất cả (${cart.items.length})',
                              style: TextStyle(
                                color: c.textPrimary,
                                fontWeight: FontWeight.bold,
                                fontSize: 13.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Spacer(),
                      TextButton(
                        onPressed: () => _openVoucherSheet(context),
                        child: Text(
                          cart.appliedVoucher != null
                              ? 'Mã: ${cart.appliedVoucher!.code}'
                              : 'Chọn mã giảm giá',
                          style: TextStyle(
                            color: c.secondary,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Danh sach san pham trong gio
                for (final CartItemModel item in cart.items)
                  CartItemCard(
                    item: item,
                    selected: item.isSelected,
                    onToggleSelected: () => cart.toggleItemSelection(item.id),
                    onQtyChange: (newQty) => cart.updateQuantity(item.id, newQty),
                    onRemove: () => cart.removeItem(item.id),
                  ),
              ],
            ),
      bottomSheet: cart.items.isNotEmpty
          ? CartBottomBar(
              cart: cart,
              onCheckout: () => _proceedToCheckout(context, cart),
            )
          : null,
    );
  }
}
