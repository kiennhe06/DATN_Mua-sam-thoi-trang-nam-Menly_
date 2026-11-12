import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import 'about_page.dart';
import 'package:menly_app/features/order/data/models/shipping_policy_model.dart';
import 'package:menly_app/features/order/data/services/shipping_policy_service.dart';

/// Trang Chinh sach mua hang, van chuyen, doi tra va bao mat
class PolicyPage extends StatefulWidget {
  const PolicyPage({super.key});

  @override
  State<PolicyPage> createState() => _PolicyPageState();
}

class _PolicyPageState extends State<PolicyPage> {
  /// Bang gia giao hang lay tu API, khong go cung trong trang chinh sach.
  ShippingPolicyModel? _bangGiaGiaoHang;

  @override
  void initState() {
    super.initState();
    ShippingPolicyService.instance.tai().then((bangGia) {
      if (!mounted) return;
      setState(() => _bangGiaGiaoHang = bangGia);
    });
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Scaffold(
      backgroundColor: c.background,
      appBar: AppBar(
        title: const Text('Chính sách'),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          Text(
            'Các chính sách áp dụng khi mua sắm tại Menly.',
            style: TextStyle(fontSize: 14, color: c.textSecondary, height: 1.4),
          ),
          const SizedBox(height: AppSpacing.md),
          _section(
            context,
            title: 'Chính sách mua hàng',
            body:
                'Bạn chọn sản phẩm, size và màu, thêm vào giỏ rồi thanh toán COD hoặc VNPay. '
                'Đơn ở trạng thái Chờ thanh toán hoặc Đang xử lý có thể hủy trong mục Đơn của tôi. '
                'Đơn Đang giao cần liên hệ hotline 1900 6868.',
          ),
          _section(
            context,
            title: 'Chính sách vận chuyển',
            body: _bangGiaGiaoHang == null
                ? 'Biểu phí giao hàng đang được cập nhật, bạn xem phí chính xác ở bước thanh toán. '
                    'Nội thành Hà Nội / TP.HCM / Đà Nẵng khoảng 1–2 ngày; tỉnh khác 3–4 ngày. '
                    'Menly hỗ trợ đồng kiểm khi nhận hàng.'
                : '${_bangGiaGiaoHang!.moTaPhiGiaoHang} '
                    'Nội thành Hà Nội / TP.HCM / Đà Nẵng khoảng 1–2 ngày; tỉnh khác 3–4 ngày. '
                    'Menly hỗ trợ đồng kiểm khi nhận hàng.',
          ),
          _section(
            context,
            title: 'Chính sách đổi trả',
            body:
                'Đổi trả trong 7 ngày kể từ ngày nhận hàng nếu còn tem mác, chưa giặt ủi và chưa qua sử dụng. '
                'Lỗi nhà sản xuất, giao sai size hoặc màu: Menly chịu phí vận chuyển hai chiều.',
          ),
          _section(
            context,
            title: 'Chính sách bảo mật',
            body:
                'Menly chỉ dùng thông tin tài khoản, địa chỉ và đơn hàng để xử lý mua sắm và hỗ trợ. '
                'Không chia sẻ dữ liệu cho bên thứ ba ngoài đối tác vận chuyển và cổng thanh toán. '
                'Bạn có thể yêu cầu cập nhật hoặc xóa thông tin qua email support@menly.vn.',
          ),
        ],
      ),
    );
  }

  Widget _section(BuildContext context, {required String title, required String body}) {
    final c = AppColors.of(context);
    return SupportCard(
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: title.contains('mua hàng'),
          title: Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 15,
              color: c.textPrimary,
            ),
          ),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                0,
                AppSpacing.lg,
                AppSpacing.lg,
              ),
              child: Text(
                body,
                style: TextStyle(
                  fontSize: 14,
                  color: c.textSecondary,
                  height: 1.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
