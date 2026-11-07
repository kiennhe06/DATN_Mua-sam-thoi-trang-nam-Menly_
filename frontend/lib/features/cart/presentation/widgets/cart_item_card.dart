import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/format.dart';
import 'package:menly_app/features/cart/data/models/cart_item_model.dart';

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
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: c.border),
        boxShadow: [
          BoxShadow(
            color: c.shadow,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Checkbox chon san pham de thanh toan
          GestureDetector(
            onTap: onToggleSelected,
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding: const EdgeInsets.only(right: 10),
              child: Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: selected ? c.primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(6),
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
            borderRadius: BorderRadius.circular(12),
            child: SizedBox(
              width: 72,
              height: 72,
              child: thumb.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: thumb,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        color: c.surfaceVariant,
                        child: Center(
                          child: CircularProgressIndicator(
                            color: c.secondary,
                            strokeWidth: 2,
                          ),
                        ),
                      ),
                      errorWidget: (context, url, error) => _placeholder(context),
                    )
                  : _placeholder(context),
            ),
          ),
          const SizedBox(width: 12),

          // Thong tin san pham & So luong
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
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
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          height: 1.3,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    GestureDetector(
                      onTap: onRemove,
                      behavior: HitTestBehavior.opaque,
                      child: Padding(
                        padding: const EdgeInsets.only(left: 4, bottom: 4),
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
                const SizedBox(height: 4),
                Text(
                  '${item.size} · ${item.color}',
                  style: TextStyle(color: c.textMuted, fontSize: 12),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      formatVnd(item.subtotal),
                      style: TextStyle(
                        color: c.secondary,
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Row(
                      children: [
                        _stepButton(context, '-', () {
                          if (item.quantity > 1) {
                            onQtyChange(item.quantity - 1);
                          } else {
                            onRemove();
                          }
                        }),
                        Container(
                          width: 32,
                          height: 28,
                          margin: const EdgeInsets.symmetric(horizontal: 6),
                          decoration: BoxDecoration(
                            color: c.surfaceVariant,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Center(
                            child: Text(
                              '${item.quantity}',
                              style: TextStyle(
                                color: c.textPrimary,
                                fontWeight: FontWeight.w800,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ),
                        _stepButton(
                          context,
                          '+',
                          () => onQtyChange(item.quantity + 1),
                        ),
                      ],
                    ),
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
            color: c.secondary,
            fontSize: 26,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }

  Widget _stepButton(BuildContext context, String symbol, VoidCallback onTap) {
    final c = AppColors.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: c.surfaceVariant,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: c.border),
        ),
        child: Center(
          child: Text(
            symbol,
            style: TextStyle(
              color: c.secondary,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}
