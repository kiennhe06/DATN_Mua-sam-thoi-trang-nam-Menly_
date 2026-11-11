import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_theme.dart';
import 'package:menly_app/features/order/data/models/shipping_policy_model.dart';
import 'package:menly_app/features/order/data/services/shipping_policy_service.dart';

/// Tieu de muc dung chung cho cac trang ho tro (gioi thieu, FAQ, lien he,
/// chinh sach) de bon trang co cung mot kieu chu va cung khoang cach.
class SupportSectionTitle extends StatelessWidget {
  final String text;

  const SupportSectionTitle(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: c.textPrimary,
        ),
      ),
    );
  }
}

/// The noi dung dung chung cho cac trang ho tro. Dat o day vi day la trang
/// khong phu thuoc trang nao khac trong nhom, ba trang con lai cung dung.
class SupportCard extends StatelessWidget {
  final Widget child;

  /// Dem trong the. De trong khi ben trong da la ListTile hoac ExpansionTile.
  final EdgeInsetsGeometry? padding;

  const SupportCard({super.key, required this.child, this.padding});

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(color: c.border),
      ),
      child: padding == null ? child : Padding(padding: padding!, child: child),
    );
  }
}

/// Trang Gioi thieu thuong hieu Menly
class AboutPage extends StatefulWidget {
  const AboutPage({super.key});

  @override
  State<AboutPage> createState() => _AboutPageState();
}

class _AboutPageState extends State<AboutPage> {
  /// Bang gia giao hang lay tu API, khong go cung trong trang gioi thieu.
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
        title: const Text('Giới thiệu'),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.xxxl,
            ),
            decoration: BoxDecoration(
              color: c.inkCard,
              borderRadius: BorderRadius.circular(AppTheme.radiusCard),
            ),
            child: Column(
              children: [
                Text(
                  'MENLY',
                  style: TextStyle(
                    color: c.onInk,
                    fontWeight: FontWeight.w900,
                    fontSize: 28,
                    letterSpacing: 3,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Thời trang nam hiện đại, lịch lãm và dễ mặc mỗi ngày',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: c.onInk.withValues(alpha: 0.75),
                    fontSize: 14,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          const SupportSectionTitle('Về chúng tôi'),
          Text(
            'Menly là cửa hàng thời trang nam hướng tới phong cách tối giản, form dáng vừa vặn và chất liệu bền. '
            'Chúng tôi mang đến áo sơ mi, áo thun, quần jeans, quần tây và áo khoác phù hợp đi học, đi làm lẫn đi chơi.',
            style: TextStyle(fontSize: 14, color: c.textSecondary, height: 1.5),
          ),
          const SizedBox(height: AppSpacing.xl),
          _infoCard(
            context,
            title: 'Sản phẩm chọn lọc',
            body: 'Mỗi mẫu được chọn theo xu hướng nhưng vẫn dễ phối. Ưu tiên vải thoáng, đứng form và bền sau nhiều lần giặt.',
          ),
          _infoCard(
            context,
            title: 'Size rõ ràng',
            body: 'Bảng size theo chiều cao – cân nặng giúp bạn chọn vừa hơn: Size M (50–62kg), L (63–72kg), XL (73–82kg).',
          ),
          _infoCard(
            context,
            title: 'Giao hàng toàn quốc',
            body: _bangGiaGiaoHang?.moTaPhiGiaoHang ??
                'Biểu phí giao hàng đang được cập nhật, bạn xem phí chính xác ở bước thanh toán.',
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Menly — mặc đẹp, mặc đúng, mặc mỗi ngày.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: c.textMuted,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoCard(
    BuildContext context, {
    required String title,
    required String body,
  }) {
    final c = AppColors.of(context);
    return SupportCard(
      child: ListTile(
        title: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 14,
            color: c.textPrimary,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: AppSpacing.xs),
          child: Text(
            body,
            style: TextStyle(
              fontSize: 13,
              color: c.textSecondary,
              height: 1.4,
            ),
          ),
        ),
      ),
    );
  }
}
