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
      size: json['size']?.toString() ?? 'M',
      color: json['color']?.toString() ?? 'Đen',
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

  const ProductModel({
    required this.id,
    required this.name,
    required this.slug,
    this.description = '',
    required this.price,
    required this.thumbnailUrl,
    this.categoryId = '',
    this.categoryName = '',
    this.ratingAvg = 5.0,
    this.ratingCount = 0,
    this.isNew = false,
    this.isBestSeller = false,
    this.variants = const [],
  });

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    var rawVariants = json['variants'] ?? json['product_variants'];
    List<ProductVariantModel> parsedVariants = [];
    if (rawVariants is List) {
      parsedVariants = rawVariants
          .map((v) => ProductVariantModel.fromJson(Map<String, dynamic>.from(v)))
          .toList();
    }
    // Khong tu sinh bien the thay the khi may chu khong tra ve. Bien the tu bia
    // co id khong phai UUID nen gio hang se tu choi, va ton kho bia ra lam nguoi
    // dung tuong con hang. De trong thi man hinh hien dung "khong co hang".

    return ProductModel(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      slug: json['slug']?.toString() ?? '',
      description: json['description']?.toString() ?? json['descr']?.toString() ?? 'Sản phẩm thời trang nam Menly cao cấp, thiết kế hiện đại, chất liệu bền đẹp, thoải mái vận động.',
      price: (json['price'] is num) ? (json['price'] as num).toInt() : 0,
      thumbnailUrl: (json['thumbnail_url'] != null && !json['thumbnail_url'].toString().contains('picsum')) ? json['thumbnail_url'].toString() : 'https://images.unsplash.com/photo-1521572267360-ee0c2909d518?w=800&q=80',
      categoryId: json['category_id']?.toString() ?? '',
      categoryName: json['category_name']?.toString() ?? '',
      ratingAvg: (json['rating_avg'] is num) ? (json['rating_avg'] as num).toDouble() : 4.8,
      ratingCount: (json['rating_count'] is num) ? (json['rating_count'] as num).toInt() : 12,
      isNew: json['is_new'] == true || json['is_new'] == 1,
      isBestSeller: json['is_best_seller'] == true || json['is_best_seller'] == 1,
      variants: parsedVariants,
    );
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
  };
}
