import 'package:flutter/foundation.dart';
import 'package:menly_app/core/mock_data.dart';
import 'package:menly_app/core/network/api_client.dart';
import 'package:menly_app/models/cart_item_model.dart';
import 'package:menly_app/models/product_model.dart';
import 'package:menly_app/models/voucher_model.dart';

/// Provider quan ly Gio hang va Ap dung ma giam gia
/// Ket noi truc tiep cac API backend moi nhat (AP-GH1, AP-VC1):
/// - GET /api/v1/cart (Xem chi tiet gio hang tu may chu)
/// - POST /api/v1/cart/items (Them san pham vao gio hang)
/// - PUT /api/v1/cart/items/:variantId (Cap nhat so luong mon)
/// - DELETE /api/v1/cart/items/:variantId (Xoa 1 mon)
/// - DELETE /api/v1/cart (Xoa ca gio hang)
class CartProvider extends ChangeNotifier {
  final ApiClient _api = ApiClient();
  final List<CartItemModel> _items = [];
  VoucherModel? _appliedVoucher;
  final int _baseShippingFee = 25000;
  bool _isLoading = false;

  final RegExp _uuidRegex = RegExp(r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$');

  CartProvider() {
    loadCartFromApi();
  }

  List<CartItemModel> get items => _items;
  VoucherModel? get appliedVoucher => _appliedVoucher;
  bool get isLoading => _isLoading;

  /// Tong so san pham trong gio
  int get totalItemCount =>
      _items.fold(0, (sum, item) => sum + item.quantity);

  /// Cac san pham dang duoc tick chon
  List<CartItemModel> get selectedItems =>
      _items.where((i) => i.isSelected).toList();

  /// Co dang chon tat ca khong?
  bool get isAllSelected =>
      _items.isNotEmpty && _items.every((i) => i.isSelected);

  /// Tam tinh cua cac mon duoc chon
  int get selectedSubtotal =>
      selectedItems.fold(0, (sum, item) => sum + item.totalPrice);

  /// So tien giam gia tu voucher da ap dung (AP-VC1)
  int get discountAmount {
    if (_appliedVoucher == null) return 0;
    return _appliedVoucher!.calculateDiscount(selectedSubtotal);
  }

  /// Phi van chuyen
  int get shippingFee {
    if (selectedItems.isEmpty) return 0;
    if (_appliedVoucher?.code == 'FREESHIP' && selectedSubtotal >= 300000) {
      return 0;
    }
    return _baseShippingFee;
  }

  /// Tong tien can thanh toan cuoi cung
  int get finalTotal {
    if (selectedItems.isEmpty) return 0;
    final total = selectedSubtotal - discountAmount + shippingFee;
    return total > 0 ? total : 0;
  }

  // =================== AP-GH1: KẾT NỐI API BACKEND GIỎ HÀNG ===================

  /// Goi API GET /api/v1/cart de dong bo gio hang tu may chu
  Future<void> loadCartFromApi() async {
    _isLoading = true;
    notifyListeners();

    try {
      final res = await _api.dio.get('/cart');
      if (res.statusCode == 200 && res.data['data'] != null) {
        final rawList = res.data['data'] as List;
        if (rawList.isNotEmpty) {
          _items.clear();
          for (var item in rawList) {
            _items.add(CartItemModel.fromBackendJson(Map<String, dynamic>.from(item)));
          }
          _isLoading = false;
          notifyListeners();
          return;
        }
      }
    } catch (_) {
      // Backend offline hoac chua dang nhap -> Dung sample fallback
    }

    if (_items.isEmpty) {
      _initSampleCart();
    }
    _isLoading = false;
    notifyListeners();
  }

  void _initSampleCart() {
    if (MockData.products.length >= 2) {
      _items.add(CartItemModel(
        id: 'cart-1',
        product: MockData.products[0],
        variantId: 'v-01-m',
        size: 'M',
        color: 'Trắng',
        quantity: 1,
        isSelected: true,
      ));
      _items.add(CartItemModel(
        id: 'cart-2',
        product: MockData.products[3],
        variantId: 'v-04-l',
        size: 'L',
        color: 'Xanh Rêu',
        quantity: 2,
        isSelected: true,
      ));
    }
  }

  /// Them san pham vao gio (POST /api/v1/cart/items)
  Future<void> addToCart(ProductModel product, {String size = 'M', String color = 'Đen', int quantity = 1}) async {
    final existingIndex = _items.indexWhere(
      (item) => item.product.id == product.id && item.size == size && item.color == color,
    );

    String variantId = '${product.id}-$size-$color';
    // Tim variantId that neu product co variants
    for (var v in product.variants) {
      if (v.size == size && v.color == color) {
        variantId = v.id;
        break;
      }
    }

    if (existingIndex >= 0) {
      _items[existingIndex].quantity += quantity;
      if (_items[existingIndex].quantity > 20) {
        _items[existingIndex].quantity = 20;
      }
    } else {
      _items.insert(0, CartItemModel(
        id: 'cart-${DateTime.now().millisecondsSinceEpoch}',
        product: product,
        variantId: variantId,
        size: size,
        color: color,
        quantity: quantity,
        isSelected: true,
      ));
    }
    notifyListeners();

    // Dong bo backend POST /api/v1/cart/items neu variantId la UUID hop le
    if (_uuidRegex.hasMatch(variantId)) {
      try {
        final res = await _api.dio.post('/cart/items', data: {
          'variantId': variantId,
          'quantity': quantity,
        });
        if (res.statusCode == 201 && res.data['data'] != null) {
          final rawList = res.data['data'] as List;
          _items.clear();
          for (var item in rawList) {
            _items.add(CartItemModel.fromBackendJson(Map<String, dynamic>.from(item)));
          }
          notifyListeners();
        }
      } catch (_) {}
    }
  }

  /// Tang so luong (+1) (PUT /api/v1/cart/items/:variantId)
  Future<void> incrementQuantity(String cartItemId) async {
    final index = _items.indexWhere((i) => i.id == cartItemId);
    if (index >= 0 && _items[index].quantity < 20) {
      _items[index].quantity++;
      final item = _items[index];
      notifyListeners();

      if (_uuidRegex.hasMatch(item.variantId)) {
        try {
          await _api.dio.put('/cart/items/${item.variantId}', data: {
            'quantity': item.quantity,
          });
        } catch (_) {}
      }
    }
  }

  /// Giam so luong (-1) (PUT /api/v1/cart/items/:variantId hoac DELETE)
  Future<void> decrementQuantity(String cartItemId) async {
    final index = _items.indexWhere((i) => i.id == cartItemId);
    if (index >= 0) {
      if (_items[index].quantity > 1) {
        _items[index].quantity--;
        final item = _items[index];
        notifyListeners();

        if (_uuidRegex.hasMatch(item.variantId)) {
          try {
            await _api.dio.put('/cart/items/${item.variantId}', data: {
              'quantity': item.quantity,
            });
          } catch (_) {}
        }
      } else {
        removeItem(cartItemId);
      }
    }
  }

  /// Xoa mot mon khoi gio (DELETE /api/v1/cart/items/:variantId)
  Future<void> removeItem(String cartItemId) async {
    final index = _items.indexWhere((i) => i.id == cartItemId);
    if (index >= 0) {
      final variantId = _items[index].variantId;
      _items.removeAt(index);
      _checkVoucherEligibility();
      notifyListeners();

      if (_uuidRegex.hasMatch(variantId)) {
        try {
          await _api.dio.delete('/cart/items/$variantId');
        } catch (_) {}
      }
    }
  }

  /// Chon / Bo chon 1 mon
  void toggleItemSelected(String cartItemId) {
    final index = _items.indexWhere((i) => i.id == cartItemId);
    if (index >= 0) {
      _items[index].isSelected = !_items[index].isSelected;
      _checkVoucherEligibility();
      notifyListeners();
    }
  }

  /// Chon tat ca / Bo chon tat ca
  void toggleSelectAll() {
    final targetState = !isAllSelected;
    for (var item in _items) {
      item.isSelected = targetState;
    }
    _checkVoucherEligibility();
    notifyListeners();
  }

  /// Xoa cac mon da duoc tick chon sau khi dat hang thanh cong
  Future<void> clearSelectedItems() async {
    final toRemove = _items.where((i) => i.isSelected).toList();
    _items.removeWhere((i) => i.isSelected);
    _appliedVoucher = null;
    notifyListeners();

    for (var item in toRemove) {
      if (_uuidRegex.hasMatch(item.variantId)) {
        try {
          await _api.dio.delete('/cart/items/${item.variantId}');
        } catch (_) {}
      }
    }
  }

  /// Xoa sach gio hang (DELETE /api/v1/cart)
  Future<void> clearCart() async {
    _items.clear();
    _appliedVoucher = null;
    notifyListeners();

    try {
      await _api.dio.delete('/cart');
    } catch (_) {}
  }

  // =================== AP-VC1: ÁP DỤNG MÃ GIẢM GIÁ ===================

  String? applyVoucher(VoucherModel voucher) {
    if (selectedSubtotal < voucher.minOrderValue) {
      return 'Đơn hàng tối thiểu phải từ ${voucher.minOrderValue} đ để áp dụng mã này';
    }
    _appliedVoucher = voucher;
    notifyListeners();
    return null;
  }

  String? applyVoucherCode(String code) {
    final cleanCode = code.trim().toUpperCase();
    final voucher = MockData.vouchers.cast<VoucherModel?>().firstWhere(
      (v) => v?.code.toUpperCase() == cleanCode,
      orElse: () => null,
    );

    if (voucher == null) {
      return 'Mã giảm giá không tồn tại hoặc đã hết hạn';
    }
    return applyVoucher(voucher);
  }

  void removeVoucher() {
    _appliedVoucher = null;
    notifyListeners();
  }

  void _checkVoucherEligibility() {
    if (_appliedVoucher != null && selectedSubtotal < _appliedVoucher!.minOrderValue) {
      _appliedVoucher = null;
    }
  }
}
