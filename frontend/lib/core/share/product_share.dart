import 'package:flutter/services.dart';
import 'package:menly_app/features/product/data/models/product_model.dart';
import 'package:share_plus/share_plus.dart';

class ProductShare {
  const ProductShare._();

  static const String storeBaseUrl = 'https://menly.shop';
  static const String productPath = '/san-pham';

  static Uri productUri(ProductModel product) {
    final slug = product.slug.trim();
    final key = slug.isNotEmpty ? slug : product.id.trim();
    return Uri.parse('$storeBaseUrl$productPath/$key');
  }

  static String shareText(ProductModel product) {
    return 'Xem sản phẩm "${product.name}" tại Menly\n'
        'Giá: ${formatPrice(product.price)}\n'
        '${productUri(product)}';
  }

  static String formatPrice(int value) {
    final digits = value.toString();
    final buffer = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      if (i > 0 && (digits.length - i) % 3 == 0) {
        buffer.write('.');
      }
      buffer.write(digits[i]);
    }
    return '${buffer.toString()} đ';
  }

  static Future<ShareResult> share(ProductModel product) {
    return SharePlus.instance.share(
      ShareParams(
        text: shareText(product),
        subject: product.name,
      ),
    );
  }

  static Future<void> copyLink(ProductModel product) {
    return Clipboard.setData(
      ClipboardData(text: productUri(product).toString()),
    );
  }
}
