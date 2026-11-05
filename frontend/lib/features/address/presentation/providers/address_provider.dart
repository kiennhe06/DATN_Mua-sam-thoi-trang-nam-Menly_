import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/network/api_client.dart';
import '../../../../models/address_model.dart';

/// Provider quan ly So dia chi giao hang
/// Phu trach boi: Thanh Toan (AP-DC1)
/// Ket noi backend: GET/POST/PUT/DELETE /api/v1/addresses, PATCH /api/v1/addresses/:id/default
class AddressProvider extends ChangeNotifier {
  final ApiClient _api = ApiClient();
  List<AddressModel> _addresses = [];
  AddressModel? _selectedAddress;
  bool _isLoading = false;

  AddressProvider() {
    loadAddresses();
  }

  List<AddressModel> get addresses => _addresses;
  AddressModel? get selectedAddress => _selectedAddress ?? defaultAddress;
  bool get isLoading => _isLoading;

  /// Lay dia chi mac dinh
  AddressModel? get defaultAddress {
    try {
      return _addresses.firstWhere((a) => a.isDefault);
    } catch (_) {
      return _addresses.isNotEmpty ? _addresses.first : null;
    }
  }

  /// Chon dia chi de dat hang (AP-DC1)
  void selectAddress(AddressModel address) {
    _selectedAddress = address;
    notifyListeners();
  }

  /// Them dia chi moi (POST /api/v1/addresses)
  Future<void> addAddress(AddressModel newAddr) async {
    if (newAddr.isDefault || _addresses.isEmpty) {
      _addresses = _addresses.map((a) => a.copyWith(isDefault: false)).toList();
    }
    _addresses.insert(0, newAddr);
    notifyListeners();
    await _saveToLocal();

    // Dong bo backend
    try {
      final res = await _api.dio.post('/addresses', data: newAddr.toJson());
      if (res.statusCode == 201 && res.data['data'] != null) {
        final saved = AddressModel.fromJson(res.data['data']);
        final idx = _addresses.indexWhere((a) => a.id == newAddr.id);
        if (idx >= 0) _addresses[idx] = saved;
        notifyListeners();
        await _saveToLocal();
      }
    } catch (_) {}
  }

  /// Cap nhat dia chi (PUT /api/v1/addresses/:id)
  Future<void> updateAddress(AddressModel updated) async {
    final index = _addresses.indexWhere((a) => a.id == updated.id);
    if (index >= 0) {
      if (updated.isDefault) {
        _addresses =
            _addresses.map((a) => a.copyWith(isDefault: false)).toList();
      }
      _addresses[index] = updated;
      if (_selectedAddress?.id == updated.id) {
        _selectedAddress = updated;
      }
      notifyListeners();
      await _saveToLocal();

      try {
        await _api.dio.put('/addresses/${updated.id}', data: updated.toJson());
      } catch (_) {}
    }
  }

  /// Dat lam dia chi mac dinh (PATCH /api/v1/addresses/:id/default)
  Future<void> setDefaultAddress(String addressId) async {
    _addresses = _addresses.map((a) {
      return a.copyWith(isDefault: a.id == addressId);
    }).toList();
    notifyListeners();
    await _saveToLocal();

    try {
      await _api.dio.patch('/addresses/$addressId/default');
    } catch (_) {}
  }

  /// Xoa dia chi (DELETE /api/v1/addresses/:id)
  Future<void> deleteAddress(String addressId) async {
    _addresses.removeWhere((a) => a.id == addressId);
    if (_selectedAddress?.id == addressId) {
      _selectedAddress = defaultAddress;
    }
    // Neu xoa mat dia chi mac dinh thi lay thang dau tien lam mac dinh
    if (_addresses.isNotEmpty && !_addresses.any((a) => a.isDefault)) {
      _addresses[0] = _addresses[0].copyWith(isDefault: true);
    }
    notifyListeners();
    await _saveToLocal();

    try {
      await _api.dio.delete('/addresses/$addressId');
    } catch (_) {}
  }

  /// Load tu Backend API (GET /api/v1/addresses) voi fallback SharedPreferences
  Future<void> loadAddresses() async {
    _isLoading = true;
    notifyListeners();

    try {
      final res = await _api.dio.get('/addresses');
      if (res.statusCode == 200 && res.data['data'] != null) {
        final list = res.data['data'] as List;
        if (list.isNotEmpty) {
          _addresses = list
              .map((item) =>
                  AddressModel.fromJson(Map<String, dynamic>.from(item)))
              .toList();
          _isLoading = false;
          notifyListeners();
          await _saveToLocal();
          return;
        }
      }
    } catch (_) {
      // Fallback local
    }

    // Fallback SharedPreferences (dia chi that nguoi dung da luu tren may, khong phai mock)
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = prefs.getString('saved_addresses');
      if (jsonStr != null && jsonStr.isNotEmpty) {
        final List list = jsonDecode(jsonStr);
        _addresses = list.map((item) => AddressModel.fromJson(item)).toList();
      } else {
        _addresses = [];
      }
    } catch (_) {
      _addresses = [];
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> _saveToLocal() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = _addresses.map((a) => a.toJson()).toList();
      await prefs.setString('saved_addresses', jsonEncode(list));
    } catch (_) {}
  }
}
