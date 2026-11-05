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

  static List<VoucherModel> get fallbackVouchers => [
    VoucherModel(
      id: 'fallback_welcome_10',
      code: 'WELCOME10',
      title: 'Giảm 10% cho đơn đầu tiên',
      discountType: 'percentage',
      discountValue: 10,
      minOrderValue: 200000,
      maxDiscount: 50000,
      endDate: DateTime.now().add(const Duration(days: 90)),
      isActive: true,
    ),
    VoucherModel(
      id: 'fallback_sale_50k',
      code: 'SALE50K',
      title: 'Giảm 50k cho đơn từ 300k',
      discountType: 'fixed_amount',
      discountValue: 50000,
      minOrderValue: 300000,
      endDate: DateTime.now().add(const Duration(days: 60)),
      isActive: true,
    ),
    VoucherModel(
      id: 'fallback_menly_20',
      code: 'MENLY20',
      title: 'Giảm 20% tối đa 100k',
      discountType: 'percentage',
      discountValue: 20,
      minOrderValue: 500000,
      maxDiscount: 100000,
      endDate: DateTime.now().add(const Duration(days: 60)),
      isActive: true,
    ),
    VoucherModel(
      id: 'fallback_freeship',
      code: 'FREESHIP',
      title: 'Miễn phí vận chuyển',
      discountType: 'fixed_amount',
      discountValue: 25000,
      minOrderValue: 0,
      endDate: DateTime.now().add(const Duration(days: 90)),
      isActive: true,
    ),
  ];

  VoucherProvider({bool autoLoad = true}) {
    if (autoLoad) loadVouchers();
  }

  List<VoucherModel> get vouchers => _vouchers.isEmpty ? fallbackVouchers : _vouchers;
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

        _vouchers = parsed.isNotEmpty ? parsed : fallbackVouchers;
        _error = null;
      } else {
        _vouchers = fallbackVouchers;
        _error = null;
      }
    } catch (_) {
      _vouchers = fallbackVouchers;
      _error = null;
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
