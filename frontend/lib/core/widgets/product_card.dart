import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../utils/format.dart';
import 'add_to_cart_button.dart';
import 'pressable.dart';
import 'package:menly_app/features/product/data/models/product_model.dart';

/// The san pham chuan cua Menly.
///
/// The nam phang tren nen kem: khong vien, khong do bong, chi anh bo goc va chu
/// ben duoi. Anh va chu la vung bam mo trang chi tiet, con nut "CHON MUA" nam
/// ngoai vung do vi no mo bang chon size chu khong dieu huong.
class ProductCard extends StatelessWidget {
  // Ten san pham luon chiem dung so dong nay nen khoi chu duoi the cao co dinh,
  // nho vay anh o moi the trong cung mot hang deu cao bang nhau.
  static const double _nameFontSize = 12.5;
  static const double _nameLineHeight = 1.45;
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Pressable(
            onTap: onTap,
            scale: 0.98,
            borderRadius: BorderRadius.circular(AppTheme.radiusCard),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Anh nhan phan chieu cao con lai cua o luoi. Dung Expanded thay
                // cho AspectRatio co dinh de the khong bi tran khi o luoi thap di
                // tren man hinh hep (chu va nut ben duoi cao co dinh theo pixel).
                Expanded(child: _imageStack(c)),
                const SizedBox(height: 9),
                // Chua san cho du 2 dong de gia o moi the deu thang hang
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
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0.2,
                    ),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  formatVnd(product.price),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: c.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.2,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 9),
        AddToCartButton(onTap: onAdd ?? onTap),
      ],
    );
  }

  Widget _imageStack(AppColors c) {
    return Stack(
      fit: StackFit.expand,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(AppTheme.radiusCard),
          child: _image(c),
        ),
        if (badge != null)
          Positioned(
            top: 9,
            left: 9,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
              decoration: BoxDecoration(
                color: c.inkCard,
                borderRadius: BorderRadius.circular(AppTheme.radiusXs),
              ),
              child: Text(
                badge!,
                style: TextStyle(
                  color: c.onInk,
                  fontSize: 9.5,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                ),
              ),
            ),
          ),
        Positioned(
          top: 7,
          right: 7,
          child: _FavButton(active: isFavorite, onTap: onToggleFavorite),
        ),
      ],
    );
  }

  Widget _image(AppColors c) {
    if (product.thumbnailUrl.isEmpty) {
      return _imageFallback(c);
    }
    return CachedNetworkImage(
      imageUrl: product.thumbnailUrl,
      fit: BoxFit.cover,
      placeholder: (_, __) => Container(color: c.surfaceVariant),
      errorWidget: (_, __, ___) => _imageFallback(c),
    );
  }

  Widget _imageFallback(AppColors c) {
    return Container(
      color: c.surfaceVariant,
      alignment: Alignment.center,
      child: Text(
        'MENLY',
        style: TextStyle(
          color: c.textMuted,
          fontSize: 11,
          fontWeight: FontWeight.w600,
          letterSpacing: 2.4,
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
      borderRadius: BorderRadius.circular(AppTheme.radiusPill),
      child: Container(
        width: 30,
        height: 30,
        // Nen kem mo de nut noi tren anh ma khong can do bong
        decoration: BoxDecoration(
          color: c.background.withValues(alpha: 0.72),
          shape: BoxShape.circle,
        ),
        child: Center(
          child: Icon(
            active ? Icons.favorite : Icons.favorite_border,
            key: ValueKey(active),
            size: 17,
            color: active ? c.danger : c.textPrimary,
          ),
        ),
      ),
    );
  }
}
