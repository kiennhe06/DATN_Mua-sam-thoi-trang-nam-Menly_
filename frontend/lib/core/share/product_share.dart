import 'package:flutter/services.dart';
import 'package:menly_app/core/network/api_client.dart';
import 'package:menly_app/core/utils/format.dart';
import 'package:menly_app/features/product/data/models/product_model.dart';
import 'package:share_plus/share_plus.dart';

class ProductShare {
  const ProductShare._();

  static const String productPath = '/san-pham';

  /// Lien ket that tro toi trang san pham do backend dung tu du lieu Supabase.
  static Uri productUri(ProductModel product) {
    final origin = ApiClient().origin;
    final id = Uri.encodeComponent(product.id.trim());
    return Uri.parse('$origin$productPath/$id');
  }

  static String shareText(ProductModel product) {
    return 'Xem sản phẩm "${product.name}" tại Menly\n'
        'Giá: ${formatPrice(product.price)}\n'
        '${productUri(product)}';
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
