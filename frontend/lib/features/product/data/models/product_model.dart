/// Model bien the san pham (size, mau, ton kho)
class ProductVariantModel {
  final String id;
  final String size;
  final String color;
  final String sku;
  final int stock;

  const ProductVariantModel({
    required this.id,
    required this.size,
    required this.color,
    required this.sku,
    required this.stock,
  });

  factory ProductVariantModel.fromJson(Map<String, dynamic> json) {
    return ProductVariantModel(
      id: json['id']?.toString() ?? '',
      size: json['size']?.toString() ?? '',
      color: json['color']?.toString() ?? '',
      sku: json['sku']?.toString() ?? '',
      // Thieu ton kho thi coi nhu het hang, khong doan bua thanh con hang
      stock: (json['stock'] is num) ? (json['stock'] as num).toInt() : 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'size': size,
        'color': color,
        'sku': sku,
        'stock': stock,
      };
}

/// Model san pham Menly (AP-SP1, TM11, TM02, AP-YT1)
/// Chi dung du lieu that tra ve tu backend, khong tu sinh bien the/anh gia.
class ProductModel {
  final String id;
  final String name;
  final String slug;
  final String description;
  final int price;
  final String thumbnailUrl;
  final String categoryId;
  final String categoryName;
  final double ratingAvg;
  final int ratingCount;
  final bool isNew;
  final bool isBestSeller;
  final List<ProductVariantModel> variants;
  final List<String> images;

  const ProductModel({
    required this.id,
    required this.name,
    required this.slug,
    this.description = '',
    required this.price,
    required this.thumbnailUrl,
    this.categoryId = '',
    this.categoryName = '',
    this.ratingAvg = 0,
    this.ratingCount = 0,
    this.isNew = false,
    this.isBestSeller = false,
    this.variants = const [],
    this.images = const [],
  });

  /// Danh sach anh that de hien thi gallery (uu tien product_images, sau do thumbnail).
  List<String> get galleryImages {
    final seen = <String>{};
    final real = <String>[];
    for (final url in [...images, thumbnailUrl]) {
      if (url.isEmpty || url.contains('picsum.photos') || seen.contains(url)) {
        continue;
      }
      seen.add(url);
      real.add(url);
    }
    return real;
  }

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    final parsedVariants = <ProductVariantModel>[];
    final rawVariants = json['variants'] ?? json['product_variants'];
    if (rawVariants is List) {
      parsedVariants.addAll(rawVariants.whereType<Map>().map(
          (v) => ProductVariantModel.fromJson(Map<String, dynamic>.from(v))));
    }
    // Khong tu sinh bien the thay the khi may chu khong tra ve. Bien the tu bia
    // co id khong phai UUID nen gio hang se tu choi, va ton kho bia ra lam nguoi
    // dung tuong con hang. De trong thi man hinh hien dung "khong co hang".

    final parsedImages = _parseImages(json['product_images'] ?? json['images']);

    final rawThumb = json['thumbnail_url']?.toString() ?? '';
    final validThumb =
        (rawThumb.isNotEmpty && !rawThumb.contains('picsum')) ? rawThumb : '';

    return ProductModel(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      slug: json['slug']?.toString() ?? '',
      description: json['description']?.toString() ??
          json['descr']?.toString() ??
          '',
      price: (json['price'] is num) ? (json['price'] as num).toInt() : 0,
      thumbnailUrl: validThumb.isNotEmpty
          ? validThumb
          : (parsedImages.isNotEmpty ? parsedImages.first : ''),
      categoryId: json['category_id']?.toString() ?? '',
      categoryName: json['category_name']?.toString() ??
          (json['categories'] is Map
              ? (json['categories']['name']?.toString() ?? '')
              : ''),
      ratingAvg:
          (json['rating_avg'] is num) ? (json['rating_avg'] as num).toDouble() : 0,
      ratingCount:
          (json['rating_count'] is num) ? (json['rating_count'] as num).toInt() : 0,
      isNew: json['is_new'] == true || json['is_new'] == 1,
      isBestSeller: json['is_best_seller'] == true || json['is_best_seller'] == 1,
      variants: parsedVariants,
      images: parsedImages,
    );
  }

  static List<String> _parseImages(dynamic raw) {
    if (raw is! List) return const [];

    final entries = <Map<String, dynamic>>[];
    for (final item in raw) {
      if (item is Map) {
        entries.add(Map<String, dynamic>.from(item));
      } else if (item is String && item.isNotEmpty) {
        entries.add({'url': item});
      }
    }

    entries.sort((a, b) {
      final aOrder =
          a['sort_order'] is num ? (a['sort_order'] as num).toInt() : 0;
      final bOrder =
          b['sort_order'] is num ? (b['sort_order'] as num).toInt() : 0;
      return aOrder.compareTo(bOrder);
    });

    return entries
        .map((entry) => entry['url']?.toString() ?? '')
        .where((url) => url.isNotEmpty && !url.contains('picsum.photos'))
        .toList();
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'slug': slug,
        'description': description,
        'price': price,
        'thumbnail_url': thumbnailUrl,
        'category_id': categoryId,
        'category_name': categoryName,
        'rating_avg': ratingAvg,
        'rating_count': ratingCount,
        'is_new': isNew,
        'is_best_seller': isBestSeller,
        'variants': variants.map((v) => v.toJson()).toList(),
        'images': images,
      };
}
