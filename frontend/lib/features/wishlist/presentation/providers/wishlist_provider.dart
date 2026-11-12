import 'package:flutter/foundation.dart';
import 'package:menly_app/core/network/api_client.dart';
import 'package:menly_app/features/product/data/models/product_model.dart';

/// Provider quan ly Danh sach yeu thich (Wishlist) & Nut trai tim
/// Ket noi truc tiep cac API backend da hoan thien (AP-YT1):
/// - GET /api/v1/wishlist (Lay danh sach yeu thich cua toi)
/// - POST /api/v1/wishlist/:productId (Them vao yeu thich)
/// - DELETE /api/v1/wishlist/:productId (Bo yeu thich)
/// - GET /api/v1/wishlist/check/:productId (Kiem tra da yeu thich chua)
class WishlistProvider extends ChangeNotifier {
  final ApiClient _api = ApiClient();
  final List<ProductModel> _favorites = [];
  bool _isLoading = false;
  String? _error;

  WishlistProvider() {
    loadFavorites();
  }

  List<ProductModel> get favorites => _favorites;
  int get count => _favorites.length;
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Kiem tra xem 1 san pham co dang trong danh sach yeu thich khong
  bool isFavorite(String productId) {
    return _favorites.any((p) => p.id == productId);
  }

  /// Toggle trai tim yeu thich (Them hoac Xoa) - Dong bo voi Backend
  Future<bool> toggleFavorite(ProductModel product) async {
    final exists = isFavorite(product.id);

    if (exists) {
      _favorites.removeWhere((p) => p.id == product.id);
      notifyListeners();

      // Goi API backend DELETE /api/v1/wishlist/:productId
      try {
        await _api.dio.delete('/wishlist/${product.id}');
      } catch (_) {}
      return false;
    } else {
      _favorites.insert(0, product);
      notifyListeners();

      // Goi API backend POST /api/v1/wishlist/:productId
      try {
        await _api.dio.post('/wishlist/${product.id}');
      } catch (_) {}
      return true;
    }
  }

  /// Xoa khoi danh sach yeu thich
  Future<void> removeFavorite(String productId) async {
    _favorites.removeWhere((p) => p.id == productId);
    notifyListeners();

    try {
      await _api.dio.delete('/wishlist/$productId');
    } catch (_) {}
  }

  /// Xoa toan bo
  Future<void> clearAll() async {
    final ids = _favorites.map((p) => p.id).toList();
    _favorites.clear();
    notifyListeners();

    for (var id in ids) {
      try {
        await _api.dio.delete('/wishlist/$id');
      } catch (_) {}
    }
  }

  /// Load tu Backend API GET /api/v1/wishlist (chi dung du lieu that tu may chu)
  Future<void> loadFavorites() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final res = await _api.dio.get('/wishlist');
      if (res.statusCode == 200 && res.data['data'] != null) {
        final list = res.data['data'] as List;
        final List<ProductModel> loaded = [];

        for (var item in list) {
          if (item['products'] != null) {
            loaded.add(ProductModel.fromJson(
                Map<String, dynamic>.from(item['products'])));
          }
        }

        _favorites
          ..clear()
          ..addAll(loaded);
      } else {
        _favorites.clear();
        _error = 'Không tải được danh sách yêu thích';
      }
    } catch (_) {
      // Loi API hoac chua dang nhap -> trang thai loi that, khong dung du lieu gia
      _favorites.clear();
      _error = 'Không tải được danh sách yêu thích. Vui lòng thử lại.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Xoa du lieu cua nguoi dung truoc khi doi tai khoan.
  void clearUserData() {
    _favorites.clear();
    _error = null;
    _isLoading = false;
    notifyListeners();
  }

}
