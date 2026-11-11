import 'package:menly_app/core/network/api_client.dart';
import 'package:menly_app/features/order/data/models/shipping_policy_model.dart';

/// Noi duy nhat trong app giu bang gia giao hang.
///
/// Goi API mot lan roi dung lai ket qua cho moi man hinh (gio hang, thanh
/// toan, hoi dap, chinh sach), nen khong man nao con tu viet con so phi ship.
class ShippingPolicyService {
  ShippingPolicyService._();

  static final ShippingPolicyService instance = ShippingPolicyService._();

  final ApiClient _api = ApiClient();
  ShippingPolicyModel? _daTai;
  Future<ShippingPolicyModel?>? _dangTai;

  /// Bang gia dang co trong bo nho, null khi chua tai duoc lan nao.
  ShippingPolicyModel? get daTai => _daTai;

  /// Tai bang gia. Cac lan goi trung nhau dung chung mot request dang chay.
  Future<ShippingPolicyModel?> tai({bool lamMoi = false}) {
    if (!lamMoi && _daTai != null) return Future.value(_daTai);
    return _dangTai ??= _goiApi().whenComplete(() => _dangTai = null);
  }

  Future<ShippingPolicyModel?> _goiApi() async {
    try {
      final res = await _api.dio.get('/orders/shipping-policy');
      final data = res.data?['data'];
      if (data is Map) {
        _daTai = ShippingPolicyModel.fromJson(Map<String, dynamic>.from(data));
        return _daTai;
      }
    } catch (_) {
      // Mat mang thi giu bang gia cu (neu co) va tra ve null de man hinh
      // tu an phan phi ship thay vi hien mot con so doan mo.
    }
    return _daTai;
  }
}
