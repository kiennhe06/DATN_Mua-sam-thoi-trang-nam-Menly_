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

  /// Danh sach ma giam gia he thong tieu chuan
  static final List<VoucherModel> _fallbackVouchers = [
    VoucherModel(
      id: 'vouch-1',
      code: 'MENLY10',
      title: 'Giảm 10% tối đa 50.000 đ',
      discountType: 'percentage',
      discountValue: 10,
      minOrderValue: 200000,
      maxDiscount: 50000,
      endDate: DateTime.now().add(const Duration(days: 30)),
    ),
    VoucherModel(
      id: 'vouch-2',
      code: 'MENLY50',
      title: 'Giảm 50.000 đ cho đơn từ 400.000 đ',
      discountType: 'fixed_amount',
      discountValue: 50000,
      minOrderValue: 400000,
      endDate: DateTime.now().add(const Duration(days: 30)),
    ),
    VoucherModel(
      id: 'vouch-3',
      code: 'FREESHIP',
      title: 'Miễn phí vận chuyển toàn quốc (đơn từ 300.000 đ)',
      discountType: 'fixed_amount',
      discountValue: 25000,
      minOrderValue: 300000,
      endDate: DateTime.now().add(const Duration(days: 30)),
    ),
    VoucherModel(
      id: 'vouch-4',
      code: 'WELCOME20',
      title: 'Giảm 20.000 đ cho khách hàng mới',
      discountType: 'fixed_amount',
      discountValue: 20000,
      minOrderValue: 150000,
      endDate: DateTime.now().add(const Duration(days: 60)),
    ),
  ];

  VoucherProvider() {
    _vouchers = List.from(_fallbackVouchers);
    loadVouchers();
  }

  List<VoucherModel> get vouchers => _vouchers;
  bool get isLoading => _isLoading;

  /// Tai danh sach ma giam gia tu Backend API (GET /api/v1/vouchers)
  Future<void> loadVouchers() async {
    _isLoading = true;
    notifyListeners();

    try {
      final res = await _api.dio.get('/vouchers');
      if (res.statusCode == 200 && res.data != null) {
        final rawList = res.data['data'] ?? res.data;
        if (rawList is List && rawList.isNotEmpty) {
          _vouchers = rawList
              .map((item) => VoucherModel.fromJson(Map<String, dynamic>.from(item)))
              .toList();
        }
      }
    } catch (_) {
      // Giu danh sach fallback khi backend chua hoan thien router vouchers
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
  bool isCollected(String voucherId) => _collectedVoucherIds.contains(voucherId);

  /// Thu thap / Luu voucher (TM10)
  void collectVoucher(String voucherId) {
    _collectedVoucherIds.add(voucherId);
    notifyListeners();
  }
}
