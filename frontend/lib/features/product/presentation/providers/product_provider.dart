import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:menly_app/core/network/api_client.dart';
import 'package:menly_app/features/home/data/models/banner_model.dart';
import 'package:menly_app/features/product/data/models/category_model.dart';
import 'package:menly_app/features/product/data/models/product_model.dart';

/// So san pham toi da tai ve mot lan cho man hinh chinh.
const int _productFetchLimit = 200;

/// Provider quan ly San pham, Banner, Danh muc, Da xem gan day, Lich su tim kiem
/// Ket noi truc tiep cac API backend da hoan thien:
/// - GET /api/v1/banners (AP-BN1)
/// - GET /api/v1/categories (AP-SP1)
/// - GET /api/v1/products (AP-SP1, TM11)
/// - GET /api/v1/products/:id (AP-SP1)
class ProductProvider extends ChangeNotifier {
  final ApiClient _api = ApiClient();

  List<ProductModel> _allProducts = [];
  List<ProductModel> _filteredProducts = [];
  List<BannerModel> _banners = [];
  List<CategoryModel> _categories = [];
  List<ProductModel> _recentlyViewed = [];
  List<String> _searchHistory = [];

  bool _loading = false;
  String? _error;
  Future<void>? _initialLoad;
  DateTime? _lastLoadedAt;

  // Filter state
  String _selectedCategory = 'Tất cả';
  String? _selectedCategoryId;
  String _searchQuery = '';
  String _sortBy =
      'newest'; // 'newest', 'price_asc', 'price_desc', 'best_seller'
  double _minPrice = 0;
  double _maxPrice = 1000000;
  String? _selectedSize;
  String? _selectedColor;
  double _minRating = 0.0;
  bool _onlyInStock = false;
  String _classification = 'all'; // 'all', 'new', 'best_seller'

  ProductProvider() {
    _initialLoad = init();
  }

  bool get isLoading => _loading;
  String? get error => _error;
  List<ProductModel> get products => _filteredProducts;
  List<ProductModel> get allProducts => List.unmodifiable(_allProducts);
  List<BannerModel> get banners => _banners;
  List<CategoryModel> get categoryItems => List.unmodifiable(_categories);
  List<ProductModel> get recentlyViewed => _recentlyViewed;
  List<String> get searchHistory => _searchHistory;

  /// Tong so san pham that tai duoc tu API (dung cho man cho).
  int get totalProductCount => _allProducts.length;
  int get bannerCount => _banners.length;
  int get categoryCount => _categories.length;

  String get selectedCategory => _selectedCategory;
  String get searchQuery => _searchQuery;
  String get sortBy => _sortBy;
  double get minPrice => _minPrice;
  double get maxPrice => _maxPrice;
  String? get selectedSize => _selectedSize;
  String? get selectedColor => _selectedColor;
  double get minRating => _minRating;
  bool get onlyInStock => _onlyInStock;
  String get classification => _classification;

  /// So luong tieu chi loc dang duoc ap dung (khong tinh sap xep)
  int get activeFilterCount {
    int count = 0;
    if (_selectedCategory != 'Tất cả') count++;
    if (_minPrice > 0 || _maxPrice < 1000000) count++;
    if (_selectedSize != null && _selectedSize != 'Tất cả') count++;
    if (_selectedColor != null && _selectedColor != 'Tất cả') count++;
    if (_minRating > 0) count++;
    if (_onlyInStock) count++;
    if (_classification != 'all') count++;
    return count;
  }

  /// Lay danh sach san pham moi nhat (TM11)
  List<ProductModel> get newProducts {
    final list = _allProducts.where((p) => p.isNew).toList();
    return list.isNotEmpty ? list : _allProducts.take(8).toList();
  }

  /// Lay danh sach san pham ban chay (TM11)
  List<ProductModel> get bestSellers {
    final list = _allProducts.where((p) => p.isBestSeller).toList();
    return list.isNotEmpty ? list : _allProducts.skip(4).take(8).toList();
  }

  /// Danh muc san pham (ket noi API /categories)
  List<String> get categories {
    final list = ['Tất cả'];
    list.addAll(_categories.map((c) => c.name));
    return list;
  }

  Future<void> init() async {
    await Future.wait([
      loadBanners(),
      loadCategories(),
      loadProducts(),
      loadRecentlyViewed(),
      loadSearchHistory(),
    ]);
  }

  /// Dung cho man cho: doi du lieu that nap xong ma khong goi API trung lap.
  Future<void> ensureInitialized() => _initialLoad ??= init();

  /// Thoi gian toi thieu giua hai lan tu dong tai lai.
  ///
  /// De ngan de quan tri them hoac duyet san pham ben web xong, chuyen sang app
  /// la thay ngay. Van co moc de chuyen tab qua lai khong thanh goi lien tuc.
  static const Duration _tuoiToiDa = Duration(seconds: 5);

  /// Tai lai neu du lieu da cu.
  ///
  /// Goi khi quay lai app va khi quay ve tab Trang chu. Quan tri them, duyet
  /// hay xoa san pham ben web thi app dang mo khong he biet, neu khong tai lai
  /// thi phai khoi dong lai app moi thay.
  Future<void> refreshIfStale() async {
    final lastLoaded = _lastLoadedAt;
    if (lastLoaded != null && DateTime.now().difference(lastLoaded) < _tuoiToiDa) {
      return;
    }
    await init();
  }

  /// AP-BN1: Goi API GET /api/v1/banners
  Future<void> loadBanners() async {
    try {
      final res = await _api.dio.get('/banners');
      if (res.statusCode == 200 && res.data['data'] != null) {
        _banners = (res.data['data'] as List)
            .map((b) => BannerModel.fromJson(Map<String, dynamic>.from(b)))
            .toList();
      } else {
        _banners = [];
      }
    } catch (_) {
      // Loi API -> khong hien banner (khong dung du lieu gia)
      _banners = [];
    }
    notifyListeners();
  }

  /// AP-SP1: Goi API GET /api/v1/categories
  Future<void> loadCategories() async {
    try {
      final res = await _api.dio.get('/categories');
      if (res.statusCode == 200 && res.data['data'] != null) {
        _categories = (res.data['data'] as List)
            .map((c) => CategoryModel.fromJson(Map<String, dynamic>.from(c)))
            .toList();
        notifyListeners();
      }
    } catch (_) {}
  }

  /// AP-SP1 & TM11: Goi API GET /api/v1/products (loc theo search, categoryId, limit)
  Future<void> loadProducts() async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      // Luon tai toan bo kho san pham de phuc vu trang chu va tim kiem tuc thi kem anh
      final queryParams = <String, dynamic>{'limit': _productFetchLimit};
      if (_selectedCategoryId != null) {
        queryParams['categoryId'] = _selectedCategoryId;
      }

      final res = await _api.dio.get('/products', queryParameters: queryParams);
      if (res.statusCode == 200 && res.data['data'] != null) {
        final list = res.data['data'] as List;
        // Nhan Moi / Ban chay do may chu quyet dinh theo du lieu that.
        // Truoc day cho nay tu gan nhan theo vi tri trong danh sach, nghia la
        // 10 san pham dau luon la "moi" du chung duoc them tu bao gio.
        _allProducts = list
            .map((item) => ProductModel.fromJson(Map<String, dynamic>.from(item)))
            .toList();
      } else {
        _allProducts = [];
        _error = 'Không tải được danh sách sản phẩm';
      }
    } catch (_) {
      // Loi API -> trang thai loi that, khong thay the bang du lieu gia
      _allProducts = [];
      _error = 'Không tải được danh sách sản phẩm. Vui lòng thử lại.';
    }

    _lastLoadedAt = DateTime.now();
    _applyFilters();
    _loading = false;
    notifyListeners();
  }

  /// AP-SP1: Goi API GET /api/v1/products/:id de lay chi tiet day du bien the & anh
  Future<ProductModel?> fetchProductDetail(String id) async {
    try {
      final res = await _api.dio.get('/products/$id');
      if (res.statusCode == 200 && res.data['data'] != null) {
        return ProductModel.fromJson(
            Map<String, dynamic>.from(res.data['data']));
      }
    } catch (_) {}
    // Fallback
    try {
      return _allProducts.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }

  /// San pham cung danh muc, loai tru san pham hien tai (trang chi tiet)
  List<ProductModel> relatedProductsFor(ProductModel product, {int limit = 8}) {
    bool sameCategory(ProductModel other) {
      if (product.categoryId.isNotEmpty && other.categoryId.isNotEmpty) {
        return other.categoryId == product.categoryId;
      }
      if (product.categoryName.isNotEmpty && other.categoryName.isNotEmpty) {
        return other.categoryName.toLowerCase() ==
            product.categoryName.toLowerCase();
      }
      return false;
    }

    final sources = List<ProductModel>.from(_allProducts);

    final related =
        sources.where((p) => p.id != product.id && sameCategory(p)).toList();

    if (related.length < limit) {
      for (final p in sources) {
        if (related.length >= limit) break;
        if (p.id == product.id) continue;
        if (related.any((r) => r.id == p.id)) continue;
        related.add(p);
      }
    }

    return related.take(limit).toList();
  }

  /// Lay san pham lien quan: uu tien API loc theo categoryId, fallback danh sach local
  Future<List<ProductModel>> fetchRelatedProducts(ProductModel product) async {
    try {
      final queryParams = <String, dynamic>{'limit': 12};
      if (product.categoryId.isNotEmpty) {
        queryParams['categoryId'] = product.categoryId;
      }

      final res = await _api.dio.get('/products', queryParameters: queryParams);
      if (res.statusCode == 200 && res.data['data'] != null) {
        final apiProducts = (res.data['data'] as List)
            .map((p) => ProductModel.fromJson(Map<String, dynamic>.from(p)))
            .where((p) => p.id != product.id)
            .toList();
        if (apiProducts.isNotEmpty) {
          return apiProducts.take(8).toList();
        }
      }
    } catch (_) {}

    return relatedProductsFor(product);
  }

  /// AP-SP1: Bo loc theo danh muc
  void setCategory(String category) {
    _selectedCategory = category;
    if (category == 'Tất cả') {
      _selectedCategoryId = null;
    } else {
      final cat = _categories.cast<CategoryModel?>().firstWhere(
            (c) => c?.name.toLowerCase() == category.toLowerCase(),
            orElse: () => null,
          );
      _selectedCategoryId = cat?.id;
    }
    _applyFilters();
    notifyListeners();
  }

  /// AP-SP1 & TM03: Tim kiem theo tu khoa
  void setSearchQuery(String query) {
    _searchQuery = query;
    _applyFilters();
    notifyListeners();
  }

  /// AP-SP1: Sap xep
  void setSortBy(String sort) {
    _sortBy = sort;
    _applyFilters();
    notifyListeners();
  }

  /// AP-SP1: Khoang gia
  void setPriceRange(double min, double max) {
    _minPrice = min;
    _maxPrice = max;
    _applyFilters();
    notifyListeners();
  }

  /// Loc theo size
  void setSelectedSize(String? size) {
    _selectedSize = (size == 'Tất cả' || size == null || size.isEmpty) ? null : size;
    _applyFilters();
    notifyListeners();
  }

  /// Loc theo mau sac
  void setSelectedColor(String? color) {
    _selectedColor = (color == 'Tất cả' || color == null || color.isEmpty) ? null : color;
    _applyFilters();
    notifyListeners();
  }

  /// Loc theo danh gia toi thieu
  void setMinRating(double rating) {
    _minRating = rating;
    _applyFilters();
    notifyListeners();
  }

  /// Loc theo tinh trang con hang
  void setOnlyInStock(bool value) {
    _onlyInStock = value;
    _applyFilters();
    notifyListeners();
  }

  /// Loc theo phan loai: 'all', 'new', 'best_seller'
  void setClassification(String value) {
    _classification = value;
    _applyFilters();
    notifyListeners();
  }

  /// Ap dung nhieu bo loc nang cao mot luc (dung trong modal bo loc)
  void applyAdvancedFilters({
    String? sort,
    double? minPrice,
    double? maxPrice,
    String? size,
    String? color,
    double? minRating,
    bool? onlyInStock,
    String? classification,
  }) {
    if (sort != null) _sortBy = sort;
    if (minPrice != null) _minPrice = minPrice;
    if (maxPrice != null) _maxPrice = maxPrice;
    _selectedSize = (size == 'Tất cả' || size == null || size.isEmpty) ? null : size;
    _selectedColor = (color == 'Tất cả' || color == null || color.isEmpty) ? null : color;
    if (minRating != null) _minRating = minRating;
    if (onlyInStock != null) _onlyInStock = onlyInStock;
    if (classification != null) _classification = classification;

    _applyFilters();
    notifyListeners();
  }

  /// Tinh truoc so luong san pham phu hop voi tieu chi loc (hien thi realtime tren nut "Ap dung")
  int countFilteredProducts({
    String? category,
    String? sort,
    double? minPrice,
    double? maxPrice,
    String? size,
    String? color,
    double? minRating,
    bool? onlyInStock,
    String? classification,
  }) {
    List<ProductModel> list = List.from(_allProducts);
    final cat = category ?? _selectedCategory;
    if (cat != 'Tất cả') {
      list = list.where((p) {
        if (_selectedCategoryId != null && p.categoryId.isNotEmpty) {
          return p.categoryId == _selectedCategoryId;
        }
        return p.categoryName.toLowerCase().contains(cat.toLowerCase());
      }).toList();
    }
    if (_searchQuery.trim().isNotEmpty) {
      final q = _searchQuery.toLowerCase().trim();
      list = list.where((p) =>
          p.name.toLowerCase().contains(q) ||
          p.description.toLowerCase().contains(q) ||
          p.categoryName.toLowerCase().contains(q)).toList();
    }
    final minP = minPrice ?? _minPrice;
    final maxP = maxPrice ?? _maxPrice;
    list = list.where((p) => p.price >= minP && p.price <= maxP).toList();

    final cls = classification ?? _classification;
    if (cls == 'new') {
      list = list.where((p) => p.isNew).toList();
    } else if (cls == 'best_seller') {
      list = list.where((p) => p.isBestSeller).toList();
    }

    final rating = minRating ?? _minRating;
    if (rating > 0) {
      list = list.where((p) => p.ratingAvg >= rating).toList();
    }

    final s = (size == 'Tất cả' || size == null || size.isEmpty) ? null : size;
    if (s != null) {
      final sUpper = s.toUpperCase().trim();
      list = list.where((p) => p.variants.any((v) => v.size.toUpperCase().trim() == sUpper)).toList();
    }

    final c = (color == 'Tất cả' || color == null || color.isEmpty) ? null : color;
    if (c != null) {
      list = list.where((p) => p.variants.any((v) => matchColor(v.color, c))).toList();
    }

    final stock = onlyInStock ?? _onlyInStock;
    if (stock) {
      list = list.where((p) {
        return p.variants.any((v) {
          final matchSize = s == null || v.size.toUpperCase().trim() == s.toUpperCase().trim();
          final matchCol = c == null || matchColor(v.color, c);
          return v.stock > 0 && matchSize && matchCol;
        });
      }).toList();
    }

    return list.length;
  }

  /// Bo tung tieu chi loc rieng le (dung cho chip badge x)
  void clearCategory() => setCategory('Tất cả');
  void clearPriceFilter() => setPriceRange(0, 1000000);
  void clearSizeFilter() {
    _selectedSize = null;
    _applyFilters();
    notifyListeners();
  }
  void clearColorFilter() {
    _selectedColor = null;
    _applyFilters();
    notifyListeners();
  }
  void clearRatingFilter() {
    _minRating = 0.0;
    _applyFilters();
    notifyListeners();
  }
  void clearStockFilter() {
    _onlyInStock = false;
    _applyFilters();
    notifyListeners();
  }
  void clearClassificationFilter() {
    _classification = 'all';
    _applyFilters();
    notifyListeners();
  }

  /// Reset toan bo bo loc
  void resetFilters() {
    _selectedCategory = 'Tất cả';
    _selectedCategoryId = null;
    _searchQuery = '';
    _sortBy = 'newest';
    _minPrice = 0;
    _maxPrice = 1000000;
    _selectedSize = null;
    _selectedColor = null;
    _minRating = 0.0;
    _onlyInStock = false;
    _classification = 'all';
    _applyFilters();
    notifyListeners();
  }

  /// Xoa tu khoa tim kiem va cap nhat lai bo loc
  void clearSearchQuery() {
    if (_searchQuery.isNotEmpty) {
      _searchQuery = '';
      _applyFilters();
      notifyListeners();
    }
  }

  /// Kiem tra mau bien the co phu hop voi mau can loc hay khong
  static bool matchColor(String variantColor, String filterColor) {
    if (filterColor.isEmpty || filterColor == 'Tất cả') return true;
    final v = variantColor.toLowerCase().trim();
    final f = filterColor.toLowerCase().trim();

    if (f.contains('đen') || f.contains('den')) {
      return v.contains('đen') || v.contains('den') || v.contains('black');
    }
    if (f.contains('trắng') || f.contains('trang')) {
      return v.contains('trắng') || v.contains('trang') || v.contains('white');
    }
    if (f.contains('xanh rêu') || f.contains('rêu') || f.contains('reu')) {
      return v.contains('rêu') || v.contains('reu') || v.contains('olive');
    }
    if (f.contains('xanh') || f.contains('navy')) {
      if (v.contains('rêu') || v.contains('reu')) return false;
      return v.contains('xanh') ||
          v.contains('navy') ||
          v.contains('jean') ||
          v.contains('blue');
    }
    if (f.contains('xám') || f.contains('xam')) {
      return v.contains('xám') ||
          v.contains('xam') ||
          v.contains('grey') ||
          v.contains('gray');
    }
    if (f.contains('be') || f.contains('nâu') || f.contains('nau')) {
      return v.contains('be') ||
          v.contains('nâu') ||
          v.contains('nau') ||
          v.contains('cam đất') ||
          v.contains('cam dat') ||
          v.contains('brown');
    }
    if (f.contains('khác') || f.contains('khac')) {
      return v.contains('đỏ') ||
          v.contains('do') ||
          v.contains('hồng') ||
          v.contains('hong') ||
          v.contains('vàng') ||
          v.contains('vang') ||
          v.contains('cam') ||
          (!v.contains('đen') &&
              !v.contains('den') &&
              !v.contains('trắng') &&
              !v.contains('trang') &&
              !v.contains('xanh') &&
              !v.contains('navy') &&
              !v.contains('xám') &&
              !v.contains('xam') &&
              !v.contains('be') &&
              !v.contains('nâu') &&
              !v.contains('nau'));
    }
    return v.contains(f);
  }

  /// Lay danh sach san pham cho trang chu theo tung danh muc (khong bi anh huong boi query tim kiem)
  List<ProductModel> getCategoryProducts(String category) {
    if (category == 'Tất cả') {
      return List.unmodifiable(_allProducts);
    }
    return _allProducts.where((p) {
      if (_selectedCategoryId != null && p.categoryId.isNotEmpty) {
        return p.categoryId == _selectedCategoryId;
      }
      return p.categoryName.toLowerCase().contains(category.toLowerCase());
    }).toList();
  }

  /// Tim kiem san pham theo tu khoa (kem anh, gia, danh muc de hien thi ngay tren SearchPage)
  List<ProductModel> searchProducts(String query) {
    if (query.trim().isEmpty) return [];
    final q = query.toLowerCase().trim();
    return _allProducts.where((p) {
      return p.name.toLowerCase().contains(q) ||
          p.categoryName.toLowerCase().contains(q) ||
          p.description.toLowerCase().contains(q);
    }).toList();
  }

  void _applyFilters() {
    List<ProductModel> result = List.from(_allProducts);

    // 1. Filter theo category
    if (_selectedCategory != 'Tất cả') {
      result = result.where((p) {
        if (_selectedCategoryId != null && p.categoryId.isNotEmpty) {
          return p.categoryId == _selectedCategoryId;
        }
        return p.categoryName
            .toLowerCase()
            .contains(_selectedCategory.toLowerCase());
      }).toList();
    }

    // 2. Filter theo search query
    if (_searchQuery.trim().isNotEmpty) {
      final q = _searchQuery.toLowerCase().trim();
      result = result.where((p) {
        return p.name.toLowerCase().contains(q) ||
            p.description.toLowerCase().contains(q) ||
            p.categoryName.toLowerCase().contains(q);
      }).toList();
    }

    // 3. Filter theo khoang gia
    result = result
        .where((p) => p.price >= _minPrice && p.price <= _maxPrice)
        .toList();

    // 4. Filter theo phan loai (all, new, best_seller)
    if (_classification == 'new') {
      result = result.where((p) => p.isNew).toList();
    } else if (_classification == 'best_seller') {
      result = result.where((p) => p.isBestSeller).toList();
    }

    // 5. Filter theo danh gia toi thieu
    if (_minRating > 0) {
      result = result.where((p) => p.ratingAvg >= _minRating).toList();
    }

    // 6. Filter theo size
    if (_selectedSize != null && _selectedSize != 'Tất cả') {
      final s = _selectedSize!.toUpperCase().trim();
      result = result.where((p) {
        return p.variants.any((v) => v.size.toUpperCase().trim() == s);
      }).toList();
    }

    // 7. Filter theo mau sac
    if (_selectedColor != null && _selectedColor != 'Tất cả') {
      result = result.where((p) {
        return p.variants.any((v) => matchColor(v.color, _selectedColor!));
      }).toList();
    }

    // 8. Filter theo tinh trang con hang
    if (_onlyInStock) {
      result = result.where((p) {
        return p.variants.any((v) {
          final matchSize = _selectedSize == null ||
              _selectedSize == 'Tất cả' ||
              v.size.toUpperCase().trim() == _selectedSize!.toUpperCase().trim();
          final matchCol = _selectedColor == null ||
              _selectedColor == 'Tất cả' ||
              matchColor(v.color, _selectedColor!);
          return v.stock > 0 && matchSize && matchCol;
        });
      }).toList();
    }

    // 9. Sap xep
    switch (_sortBy) {
      case 'price_asc':
        result.sort((a, b) => a.price.compareTo(b.price));
        break;
      case 'price_desc':
        result.sort((a, b) => b.price.compareTo(a.price));
        break;
      case 'best_seller':
        result.sort((a, b) =>
            (b.isBestSeller ? 1 : 0).compareTo(a.isBestSeller ? 1 : 0));
        break;
      case 'rating_desc':
        result.sort((a, b) => b.ratingAvg.compareTo(a.ratingAvg));
        break;
      case 'newest':
      default:
        result.sort((a, b) => (b.isNew ? 1 : 0).compareTo(a.isNew ? 1 : 0));
        break;
    }

    _filteredProducts = result;
  }

  // =================== TM02: ĐÃ XEM GẦN ĐÂY ===================

  Future<void> addToRecentlyViewed(ProductModel product) async {
    _recentlyViewed.removeWhere((p) => p.id == product.id);
    _recentlyViewed.insert(0, product);
    if (_recentlyViewed.length > 10) {
      _recentlyViewed = _recentlyViewed.sublist(0, 10);
    }
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      final ids = _recentlyViewed.map((p) => p.id).toList();
      await prefs.setStringList('recently_viewed_ids', ids);
    } catch (_) {}
  }

  Future<void> loadRecentlyViewed() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final ids = prefs.getStringList('recently_viewed_ids') ?? [];
      if (ids.isNotEmpty) {
        _recentlyViewed = ids
            .map((id) => _allProducts.cast<ProductModel?>().firstWhere(
                  (p) => p?.id == id,
                  orElse: () => null,
                ))
            .whereType<ProductModel>()
            .toList();
      }
    } catch (_) {}
    notifyListeners();
  }

  Future<void> clearRecentlyViewed() async {
    _recentlyViewed.clear();
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('recently_viewed_ids');
    } catch (_) {}
  }

  // =================== TM03: GỢI Ý & LỊCH SỬ TÌM KIẾM ===================

  Future<void> loadSearchHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _searchHistory = prefs.getStringList('search_history') ??
          [
            'Áo sơ mi trắng',
            'Quần jeans slimfit',
            'Áo khoác bomber',
            'Áo polo nam',
          ];
    } catch (_) {
      _searchHistory = ['Áo sơ mi', 'Áo thun', 'Quần jeans'];
    }
    notifyListeners();
  }

  Future<void> addSearchKeyword(String keyword) async {
    final term = keyword.trim();
    if (term.isEmpty) return;

    _searchHistory.remove(term);
    _searchHistory.insert(0, term);
    if (_searchHistory.length > 8) {
      _searchHistory = _searchHistory.sublist(0, 8);
    }
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList('search_history', _searchHistory);
    } catch (_) {}
  }

  Future<void> removeSearchKeyword(String keyword) async {
    _searchHistory.remove(keyword);
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList('search_history', _searchHistory);
    } catch (_) {}
  }

  Future<void> clearSearchHistory() async {
    _searchHistory.clear();
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('search_history');
    } catch (_) {}
  }

  List<String> getSuggestions(String query) {
    if (query.trim().isEmpty) return [];
    final q = query.toLowerCase().trim();
    final suggestions = <String>{};

    for (var p in _allProducts) {
      if (p.name.toLowerCase().contains(q)) {
        suggestions.add(p.name);
      }
      if (p.categoryName.toLowerCase().contains(q)) {
        suggestions.add(p.categoryName);
      }
    }
    return suggestions.take(5).toList();
  }
  /// Xoa du lieu cua nguoi dung truoc khi doi tai khoan.
  ///
  /// Danh sach xem gan day va lich su tim kiem la rieng tung nguoi; de lai thi
  /// nguoi dang nhap sau thay nguoi truoc da xem va tim nhung gi.
  void clearUserData() {
    _recentlyViewed = [];
    _searchHistory = [];
    notifyListeners();
  }

}
