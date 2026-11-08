import 'package:flutter/foundation.dart';
import '../../../../core/network/api_client.dart';
import 'package:menly_app/features/voucher/data/models/voucher_model.dart';

/// Provider quan ly Khuyen mai & Gom ma giam gia
/// Phu trach boi: Thanh Toan (TM10, AP-VC1)
/// Ket noi API: GET /api/v1/vouchers
class VoucherProvider extends ChangeNotifier {
  final ApiClient _api = ApiClient();
  List<VoucherModel> _vouchers = [];
  final Set<String> _collectedVoucherIds = {};
  bool _isLoading = false;
  String? _error;

  VoucherProvider({bool autoLoad = true}) {
    if (autoLoad) loadVouchers();
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
        final parsed = rawList is List
            ? rawList
                .map((item) =>
                    VoucherModel.fromJson(Map<String, dynamic>.from(item)))
                .toList()
            : <VoucherModel>[];

        _vouchers = parsed;
        _error = null;
      } else {
        // Truoc day cho nay thay bang mot danh sach ma giam gia bia san. Nguoi
        // dung thay ma khong co that, nhap vao thanh toan thi that bai ma khong
        // hieu vi sao. Thieu du lieu thi phai noi la thieu.
        _vouchers = [];
        _error = 'Không tải được mã giảm giá. Vui lòng thử lại.';
      }
    } catch (_) {
      _vouchers = [];
      _error = 'Không tải được mã giảm giá. Vui lòng thử lại.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Tim voucher theo ma
  VoucherModel? findByCode(String code) {
    final clean = code.trim().toUpperCase();
    try {
      return vouchers.firstWhere((v) => v.code.toUpperCase() == clean);
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
