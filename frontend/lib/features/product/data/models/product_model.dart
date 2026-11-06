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
      stock: (json['stock'] is num) ? (json['stock'] as num).toInt() : 50,
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
    if (parsedVariants.isEmpty) {
      final cat = (json['category_name']?.toString() ?? '').toLowerCase();
      final name = (json['name']?.toString() ?? '').toLowerCase();
      final slug = (json['slug']?.toString() ?? '').toLowerCase();
      final isBottom = cat.contains('quần') ||
          cat.contains('jean') ||
          name.contains('quần') ||
          name.contains('jean') ||
          slug.contains('quan') ||
          slug.contains('jean');

      if (isBottom) {
        parsedVariants = [
          ProductVariantModel(id: '${json['id']}-29-den', size: '29', color: 'Đen', sku: '${json['slug']}-29-Den', stock: 30),
          ProductVariantModel(id: '${json['id']}-30-den', size: '30', color: 'Đen', sku: '${json['slug']}-30-Den', stock: 45),
          ProductVariantModel(id: '${json['id']}-31-den', size: '31', color: 'Đen', sku: '${json['slug']}-31-Den', stock: 50),
          ProductVariantModel(id: '${json['id']}-32-den', size: '32', color: 'Đen', sku: '${json['slug']}-32-Den', stock: 40),
          ProductVariantModel(id: '${json['id']}-33-den', size: '33', color: 'Đen', sku: '${json['slug']}-33-Den', stock: 35),
          ProductVariantModel(id: '${json['id']}-34-den', size: '34', color: 'Đen', sku: '${json['slug']}-34-Den', stock: 25),
          ProductVariantModel(id: '${json['id']}-30-xanh', size: '30', color: 'Xanh Đậm', sku: '${json['slug']}-30-Xanh', stock: 40),
          ProductVariantModel(id: '${json['id']}-31-xanh', size: '31', color: 'Xanh Đậm', sku: '${json['slug']}-31-Xanh', stock: 40),
          ProductVariantModel(id: '${json['id']}-32-xanh', size: '32', color: 'Xanh Đậm', sku: '${json['slug']}-32-Xanh', stock: 30),
        ];
      } else {
        parsedVariants = [
          ProductVariantModel(id: '${json['id']}-s-den', size: 'S', color: 'Đen', sku: '${json['slug']}-S-Den', stock: 30),
          ProductVariantModel(id: '${json['id']}-m-den', size: 'M', color: 'Đen', sku: '${json['slug']}-M-Den', stock: 50),
          ProductVariantModel(id: '${json['id']}-l-den', size: 'L', color: 'Đen', sku: '${json['slug']}-L-Den', stock: 50),
          ProductVariantModel(id: '${json['id']}-xl-den', size: 'XL', color: 'Đen', sku: '${json['slug']}-XL-Den', stock: 40),
          ProductVariantModel(id: '${json['id']}-2xl-den', size: '2XL', color: 'Đen', sku: '${json['slug']}-2XL-Den', stock: 25),
          ProductVariantModel(id: '${json['id']}-m-trang', size: 'M', color: 'Trắng', sku: '${json['slug']}-M-Trang', stock: 40),
          ProductVariantModel(id: '${json['id']}-l-trang', size: 'L', color: 'Trắng', sku: '${json['slug']}-L-Trang', stock: 40),
          ProductVariantModel(id: '${json['id']}-xl-trang', size: 'XL', color: 'Trắng', sku: '${json['slug']}-XL-Trang', stock: 30),
          ProductVariantModel(id: '${json['id']}-m-xam', size: 'M', color: 'Xám', sku: '${json['slug']}-M-Xam', stock: 35),
          ProductVariantModel(id: '${json['id']}-l-xam', size: 'L', color: 'Xám', sku: '${json['slug']}-L-Xam', stock: 35),
        ];
      }
    }

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
