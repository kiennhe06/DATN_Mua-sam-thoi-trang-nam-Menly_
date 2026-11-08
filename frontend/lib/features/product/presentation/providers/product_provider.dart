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

  /// Thoi gian toi thieu giua hai lan tu dong tai lai khi quay lai app.
  static const Duration _tuoiToiDa = Duration(seconds: 30);

  /// Tai lai neu du lieu da cu.
  ///
  /// Quan tri them hoac xoa san pham tren web thi app dang mo khong biet. Goi
  /// ham nay khi nguoi dung quay lai app de ho thay kho hang dung thuc te ma
  /// khong phai khoi dong lai. Co moc thoi gian de chuyen man qua lai khong
  /// bien thanh goi API lien tuc.
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

  /// Reset bo loc
  void resetFilters() {
    _selectedCategory = 'Tất cả';
    _selectedCategoryId = null;
    _searchQuery = '';
    _sortBy = 'newest';
    _minPrice = 0;
    _maxPrice = 1000000;
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

    // Filter theo category
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

    // Filter theo search query
    if (_searchQuery.trim().isNotEmpty) {
      final q = _searchQuery.toLowerCase().trim();
      result = result.where((p) {
        return p.name.toLowerCase().contains(q) ||
            p.description.toLowerCase().contains(q) ||
            p.categoryName.toLowerCase().contains(q);
      }).toList();
    }

    // Filter theo khoang gia
    result = result
        .where((p) => p.price >= _minPrice && p.price <= _maxPrice)
        .toList();

    // Sap xep
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
