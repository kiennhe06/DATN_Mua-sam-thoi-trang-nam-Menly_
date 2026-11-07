import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../utils/format.dart';
import 'add_to_cart_button.dart';
import 'pressable.dart';
import 'package:menly_app/features/product/data/models/product_model.dart';

/// The san pham chuan UI/UX Menly:
/// Bo goc tron, hieu ung hover/press nhe, anh theo ty le, nut tim yeu thich va nut them gio.
class ProductCard extends StatelessWidget {
  // Ten san pham luon chiem dung so dong nay nen khoi chu duoi the cao co dinh,
  // nho vay anh o moi the trong cung mot hang deu cao bang nhau.
  static const double _nameFontSize = 13.0;
  static const double _nameLineHeight = 1.25;
  static const int _nameMaxLines = 2;
  static const double _nameBoxHeight =
      _nameFontSize * _nameLineHeight * _nameMaxLines;

  final ProductModel product;
  final bool isFavorite;
  final VoidCallback? onTap;
  final VoidCallback? onToggleFavorite;
  final VoidCallback? onAdd;
  final String? badge;

  const ProductCard({
    super.key,
    required this.product,
    this.isFavorite = false,
    this.onTap,
    this.onToggleFavorite,
    this.onAdd,
    this.badge,
  });

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Pressable(
      onTap: onTap,
      scale: 0.98,
      child: Container(
        decoration: BoxDecoration(
          color: c.surface,
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          border: Border.all(color: c.border.withValues(alpha: 0.7)),
          boxShadow: [
            BoxShadow(
              color: c.shadow,
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Anh nhan phan chieu cao con lai cua o luoi. Dung Expanded thay cho
            // AspectRatio co dinh de the khong bi tran khi o luoi thap di tren
            // man hinh hep (chu va nut ben duoi cao co dinh theo pixel).
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(AppTheme.radiusLg),
                    ),
                    child: _image(c),
                  ),
                  if (badge != null)
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: c.inkCard.withValues(alpha: 0.85),
                          borderRadius:
                              BorderRadius.circular(AppTheme.radiusPill),
                        ),
                        child: Text(
                          badge!,
                          style: TextStyle(
                            color: c.onInk,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: _FavButton(
                      active: isFavorite,
                      onTap: onToggleFavorite,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Chua san cho du 2 dong de gia va nut o moi the deu thang hang
                  SizedBox(
                    height: _nameBoxHeight,
                    child: Text(
                      product.name,
                      maxLines: _nameMaxLines,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: c.textPrimary,
                        fontSize: _nameFontSize,
                        height: _nameLineHeight,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    formatVnd(product.price),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: c.secondary,
                      fontSize: 14.0,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  AddToCartButton(
                    onTap: onAdd ?? onTap,
                    height: 32,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _image(AppColors c) {
    if (product.thumbnailUrl.isEmpty) {
      return Container(
        color: c.surfaceVariant,
        child: const Center(
          child: Text('Menly', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 13)),
        ),
      );
    }
    return CachedNetworkImage(
      imageUrl: product.thumbnailUrl,
      fit: BoxFit.cover,
      placeholder: (_, __) => Container(color: c.surfaceVariant),
      errorWidget: (_, __, ___) => Container(
        color: c.surfaceVariant,
        child: const Center(
          child: Text('Menly', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 13)),
        ),
      ),
    );
  }
}

class _FavButton extends StatelessWidget {
  final bool active;
  final VoidCallback? onTap;
  const _FavButton({required this.active, this.onTap});

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Pressable(
      onTap: onTap,
      scale: 0.85,
      borderRadius: BorderRadius.circular(17),
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: c.surface.withValues(alpha: 0.92),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(color: c.shadow, blurRadius: 8, offset: const Offset(0, 2)),
          ],
        ),
        child: Center(
          child: Icon(
            active ? Icons.favorite : Icons.favorite_border,
            key: ValueKey(active),
            size: 17,
            color: active ? c.danger : c.textSecondary,
          ),
        ),
      ),
    );
  }
}
