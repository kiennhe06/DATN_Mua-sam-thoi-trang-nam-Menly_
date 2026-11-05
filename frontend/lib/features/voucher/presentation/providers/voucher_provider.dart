import 'package:flutter/foundation.dart';
import '../../../../core/network/api_client.dart';
import '../../../../models/voucher_model.dart';

/// Provider quan ly Khuyen mai & Gom ma giam gia
/// Phu trach boi: Thanh Toan (TM10, AP-VC1)
/// Ket noi API: GET /api/v1/vouchers
class VoucherProvider extends ChangeNotifier {
  final ApiClient _api = ApiClient();
  List<VoucherModel> _vouchers = [];
  final Set<String> _collectedVoucherIds = {};
  bool _isLoading = false;
  String? _error;

  VoucherProvider() {
    loadVouchers();
  }

  List<VoucherModel> get vouchers => _vouchers;
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Tai danh sach ma giam gia tu Backend API (GET /api/v1/vouchers)
  Future<void> loadVouchers() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final res = await _api.dio.get('/vouchers');
      if (res.statusCode == 200 && res.data != null) {
        final rawList = res.data['data'] ?? res.data;
        _vouchers = rawList is List
            ? rawList
                .map((item) =>
                    VoucherModel.fromJson(Map<String, dynamic>.from(item)))
                .toList()
            : <VoucherModel>[];
      } else {
        _vouchers = [];
        _error = 'Không tải được danh sách mã giảm giá';
      }
    } catch (_) {
      _vouchers = [];
      _error = 'Không tải được danh sách mã giảm giá. Vui lòng thử lại.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Tim voucher theo ma
  VoucherModel? findByCode(String code) {
    final clean = code.trim().toUpperCase();
    try {
      return _vouchers.firstWhere((v) => v.code.toUpperCase() == clean);
    } catch (_) {
      return null;
    }
  }

  /// Kiem tra da luu voucher chua
  bool isCollected(String voucherId) =>
      _collectedVoucherIds.contains(voucherId);

  /// Thu thap / Luu voucher (TM10)
  void collectVoucher(String voucherId) {
    _collectedVoucherIds.add(voucherId);
    notifyListeners();
  }
}
