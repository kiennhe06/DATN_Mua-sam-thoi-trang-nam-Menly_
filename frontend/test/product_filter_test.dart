import 'package:flutter_test/flutter_test.dart';
import 'package:menly_app/features/product/data/models/product_model.dart';
import 'package:menly_app/features/product/presentation/providers/product_provider.dart';

void main() {
  group('ProductProvider.matchColor', () {
    test('matchColor dung cho cac bien the thuc te trong Menly', () {
      // Mau Den
      expect(ProductProvider.matchColor('Den', 'Đen'), isTrue);
      expect(ProductProvider.matchColor('Đen', 'Đen'), isTrue);
      expect(ProductProvider.matchColor('Trắng', 'Đen'), isFalse);

      // Mau Trang
      expect(ProductProvider.matchColor('Trang', 'Trắng'), isTrue);
      expect(ProductProvider.matchColor('Trắng', 'Trắng'), isTrue);
      expect(ProductProvider.matchColor('Đen', 'Trắng'), isFalse);

      // Mau Xanh / Navy
      expect(ProductProvider.matchColor('Xanh', 'Xanh / Navy'), isTrue);
      expect(ProductProvider.matchColor('Navy', 'Xanh / Navy'), isTrue);
      expect(ProductProvider.matchColor('Xanh jean', 'Xanh / Navy'), isTrue);
      expect(ProductProvider.matchColor('Xanh kẻ', 'Xanh / Navy'), isTrue);
      expect(ProductProvider.matchColor('Xanh nhạt', 'Xanh / Navy'), isTrue);
      expect(ProductProvider.matchColor('Xanh rêu', 'Xanh / Navy'), isFalse);

      // Mau Xanh reu
      expect(ProductProvider.matchColor('Xanh rêu', 'Xanh rêu'), isTrue);
      expect(ProductProvider.matchColor('Xanh', 'Xanh rêu'), isFalse);

      // Be / Nau
      expect(ProductProvider.matchColor('Nâu', 'Be / Nâu'), isTrue);
      expect(ProductProvider.matchColor('Be', 'Be / Nâu'), isTrue);
      expect(ProductProvider.matchColor('Cam đất', 'Be / Nâu'), isTrue);
      expect(ProductProvider.matchColor('Đen', 'Be / Nâu'), isFalse);

      // Mau Khac
      expect(ProductProvider.matchColor('Đỏ', 'Khác'), isTrue);
      expect(ProductProvider.matchColor('Hồng nhạt', 'Khác'), isTrue);
      expect(ProductProvider.matchColor('Vàng', 'Khác'), isTrue);
      expect(ProductProvider.matchColor('Đen', 'Khác'), isFalse);
    });
  });

  group('ProductModel variant matching', () {
    final testProduct = ProductModel(
      id: 'p1',
      name: 'Áo sơ mi nam Oxford',
      slug: 'ao-so-mi-nam-oxford',
      price: 250000,
      thumbnailUrl: 'https://example.com/thumb.jpg',
      ratingAvg: 4.8,
      ratingCount: 15,
      isNew: true,
      isBestSeller: false,
      variants: const [
        ProductVariantModel(id: 'v1', size: 'M', color: 'Trắng', sku: 'SMI-W-M', stock: 10),
        ProductVariantModel(id: 'v2', size: 'L', color: 'Trắng', sku: 'SMI-W-L', stock: 0),
        ProductVariantModel(id: 'v3', size: 'XL', color: 'Xanh', sku: 'SMI-B-XL', stock: 5),
      ],
    );

    test('Loc dung size va ton kho theo bien the', () {
      // Co size M va con hang
      final hasSizeMInStock = testProduct.variants.any((v) => v.size == 'M' && v.stock > 0);
      expect(hasSizeMInStock, isTrue);

      // Size L het hang
      final hasSizeLInStock = testProduct.variants.any((v) => v.size == 'L' && v.stock > 0);
      expect(hasSizeLInStock, isFalse);

      // Size S khong ton tai
      final hasSizeS = testProduct.variants.any((v) => v.size == 'S');
      expect(hasSizeS, isFalse);

      // Rating 4.5+ phu hop voi 4.8
      expect(testProduct.ratingAvg >= 4.5, isTrue);
      // Rating 5.0 khong phu hop
      expect(testProduct.ratingAvg >= 5.0, isFalse);
    });
  });
}

