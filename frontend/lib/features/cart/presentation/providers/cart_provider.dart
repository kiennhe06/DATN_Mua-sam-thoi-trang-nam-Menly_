import 'package:flutter/foundation.dart';
import 'package:menly_app/core/network/api_client.dart';
import 'package:menly_app/features/cart/data/models/cart_item_model.dart';
import 'package:menly_app/features/product/data/models/product_model.dart';
import 'package:menly_app/features/voucher/data/models/voucher_model.dart';

/// Provider quan ly Gio hang va Ap dung ma giam gia
/// Ket noi truc tiep cac API backend moi nhat (AP-GH1, AP-VC1):
/// - GET /api/v1/cart (Xem chi tiet gio hang tu may chu)
/// - POST /api/v1/cart/items (Them san pham vao gio hang)
/// - PUT /api/v1/cart/items/:variantId (Cap nhat so luong mon)
/// - DELETE /api/v1/cart/items/:variantId (Xoa 1 mon)
/// - DELETE /api/v1/cart (Xoa ca gio hang)
/// - POST /api/v1/orders/shipping-fee (Tinh phi ship tu backend)
class CartProvider extends ChangeNotifier {
  final ApiClient _api = ApiClient();
  final List<CartItemModel> _items = [];
  VoucherModel? _appliedVoucher;
  final int _baseShippingFee = 25000;
  int? _shippingFeeFromApi;
  String? _shippingNote;
  bool _isLoading = false;

  final RegExp _uuidRegex = RegExp(
      r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$');

  CartProvider() {
    loadCartFromApi();
  }

  List<CartItemModel> get items => _items;
  VoucherModel? get appliedVoucher => _appliedVoucher;
  bool get isLoading => _isLoading;
  String? get shippingNote => _shippingNote;

  /// Tong so san pham trong gio
  int get totalItemCount => _items.fold(0, (sum, item) => sum + item.quantity);

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

  /// Phi van chuyen (ket hop API backend /orders/shipping-fee)
  int get shippingFee {
    if (selectedItems.isEmpty) return 0;
    if (_shippingFeeFromApi != null) return _shippingFeeFromApi!;

    // Chinh sach freeship chuan: don tu 499k hoac ma FREESHIP tu 300k
    final code = _appliedVoucher?.code.toUpperCase() ?? '';
    if (selectedSubtotal >= 499000 ||
        (code.contains('FREESHIP') || code.startsWith('FS'))) {
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

  /// Tinh phi van chuyen tu Backend API: POST /api/v1/orders/shipping-fee (ho tro ca mua ngay customSubtotal)
  Future<void> calculateShippingFeeApi(
      {String province = '',
      String shippingMethod = 'standard',
      int? customSubtotal}) async {
    final subtotal = customSubtotal ?? selectedSubtotal;
    if (subtotal <= 0 && selectedItems.isEmpty) {
      _shippingFeeFromApi = 0;
      _shippingNote = null;
      notifyListeners();
      return;
    }

    try {
      final res = await _api.dio.post('/orders/shipping-fee', data: {
        'subtotal': subtotal,
        if (province.isNotEmpty) 'province': province,
        'shippingMethod': shippingMethod,
        if (_appliedVoucher != null) 'voucherCode': _appliedVoucher!.code,
      });

      if (res.statusCode == 200 &&
          res.data != null &&
          res.data['data'] != null) {
        final data = res.data['data'];
        if (data['shippingFee'] is num) {
          _shippingFeeFromApi = (data['shippingFee'] as num).toInt();
        }
        _shippingNote = data['note']?.toString();
        notifyListeners();
      }
    } catch (_) {
      // Khong tinh duoc phi ship tu backend -> dung chinh sach local trong getter shippingFee
      _shippingFeeFromApi = null;
      notifyListeners();
    }
  }

  // =================== AP-GH1: KẾT NỐI API BACKEND GIỎ HÀNG ===================

  /// Goi API GET /api/v1/cart de dong bo gio hang tu may chu
  Future<void> loadCartFromApi() async {
    _isLoading = true;
    notifyListeners();

    try {
      final res = await _api.dio.get('/cart');
      if (res.statusCode == 200 && res.data != null) {
        final cartData = res.data['data'] ?? res.data;
        final rawItems = cartData['items'] ?? cartData;

        if (rawItems is List) {
          _items.clear();
          for (var item in rawItems) {
            _items.add(
                CartItemModel.fromBackendJson(Map<String, dynamic>.from(item)));
          }
        }
      }
    } catch (_) {
      // Giu nguyen gio hang hien tai khi loi mang hoac chua dang nhap
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Them san pham vao gio (POST /api/v1/cart/items)
  Future<void> addToCart(ProductModel product,
      {String size = 'M', String color = 'Đen', int quantity = 1}) async {
    final existingIndex = _items.indexWhere(
      (item) =>
          item.product.id == product.id &&
          item.size == size &&
          item.color == color,
    );

    String variantId = '';
    if (product.variants.isNotEmpty) {
      try {
        final matched = product.variants
            .firstWhere((v) => v.size == size && v.color == color);
        variantId = matched.id;
      } catch (_) {
        variantId = product.variants.first.id;
      }
    }

    if (existingIndex >= 0) {
      _items[existingIndex].quantity += quantity;
      if (_items[existingIndex].quantity > 20) {
        _items[existingIndex].quantity = 20;
      }
    } else {
      _items.insert(
          0,
          CartItemModel(
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
            _items.add(
                CartItemModel.fromBackendJson(Map<String, dynamic>.from(item)));
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
        await removeItem(cartItemId);
      }
    }
  }

  /// Xoa 1 mon khoi gio (DELETE /api/v1/cart/items/:variantId)
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
    _shippingFeeFromApi = null;
    _shippingNote = null;
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
    _shippingFeeFromApi = null;
    _shippingNote = null;
    notifyListeners();

    try {
      await _api.dio.delete('/cart');
    } catch (_) {}
  }

  // =================== AP-VC1: ÁP DỤNG MÃ GIẢM GIÁ ===================

  String? applyVoucher(VoucherModel voucher) {
    // Khong gioi han so tien don hang de ap dung voucher
    _appliedVoucher = voucher;
    notifyListeners();
    return null;
  }

  Future<void> updateQuantity(String cartItemId, int newQty) async {
    if (newQty <= 0) {
      await removeItem(cartItemId);
      return;
    }
    final index = _items.indexWhere((i) => i.id == cartItemId);
    if (index >= 0) {
      _items[index].quantity = newQty > 20 ? 20 : newQty;
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

  void toggleItemSelection(String cartItemId) {
    final index = _items.indexWhere((i) => i.id == cartItemId);
    if (index >= 0) {
      _items[index].isSelected = !_items[index].isSelected;
      notifyListeners();
    }
  }

  void removeVoucher() {
    _appliedVoucher = null;
    notifyListeners();
  }

  void _checkVoucherEligibility() {
    // Khong gioi han so tien don hang
  }
}
