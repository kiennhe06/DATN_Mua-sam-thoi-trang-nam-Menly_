import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:menly_app/core/theme/app_colors.dart';
import 'package:menly_app/core/theme/app_spacing.dart';
import 'package:menly_app/core/theme/app_theme.dart';
import 'package:menly_app/core/widgets/app_buttons.dart';
import 'package:menly_app/core/widgets/state_views.dart';
import '../providers/voucher_provider.dart';
import 'package:menly_app/features/notification/presentation/providers/notification_provider.dart';

/// Trang khuyen mai gom ma giam gia Menly (TM10)
class VoucherListPage extends StatefulWidget {
  const VoucherListPage({super.key});

  @override
  State<VoucherListPage> createState() => _VoucherListPageState();
}

class _VoucherListPageState extends State<VoucherListPage> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final voucherProv = context.watch<VoucherProvider>();
    final vouchers = voucherProv.vouchers;
    final query = _searchController.text.trim().toLowerCase();

    final filteredVouchers = vouchers.where((v) {
      if (query.isEmpty) return true;
      return v.code.toLowerCase().contains(query) || v.title.toLowerCase().contains(query);
    }).toList();

    final activeCount = vouchers.where((v) => v.isActive).length;
    final savedCount = voucherProv.vouchers.where((v) => voucherProv.isCollected(v.id)).length;
    final expiringSoon = vouchers.where((v) => v.endDate.difference(DateTime.now()).inDays <= 7).length;

    return Scaffold(
      backgroundColor: c.background,
      appBar: AppBar(
        title: const Text('Kho Voucher'),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: () => voucherProv.loadVouchers(),
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => voucherProv.loadVouchers(),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.lg,
            AppSpacing.lg,
            AppSpacing.xxl,
          ),
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.xl),
              decoration: BoxDecoration(
                color: c.inkCard,
                borderRadius: BorderRadius.circular(AppTheme.radiusXl),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.md,
                            vertical: AppSpacing.xs,
                          ),
                          decoration: BoxDecoration(
                            color: c.onInk.withValues(alpha: 0.18),
                            borderRadius:
                                BorderRadius.circular(AppTheme.radiusPill),
                          ),
                          child: Text(
                            'FLASH SALE MENLY',
                            style: TextStyle(
                              color: c.onInk,
                              fontWeight: FontWeight.bold,
                              fontSize: 10,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Text(
                          'Mã giảm giá hấp dẫn',
                          style: TextStyle(
                            color: c.onInk,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            height: 1.2,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          'Giảm tối đa 100.000đ cho các đơn hàng mới.',
                          style: TextStyle(
                            color: c.onInk.withValues(alpha: 0.75),
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: c.onInk.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(AppTheme.radiusXl),
                    ),
                    child: Icon(
                      Icons.local_offer_rounded,
                      color: c.onInk,
                      size: 36,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Row(
              children: [
                Expanded(
                  child: _SummaryCard(
                    label: 'Đang có',
                    value: '$activeCount',
                    color: c.primary,
                    icon: Icons.discount_rounded,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: _SummaryCard(
                    label: 'Đã lưu',
                    value: '$savedCount',
                    color: c.success,
                    icon: Icons.bookmark_rounded,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: _SummaryCard(
                    label: 'Sắp hết',
                    value: '$expiringSoon',
                    color: c.danger,
                    icon: Icons.timer_rounded,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xl),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              decoration: BoxDecoration(
                color: c.surface,
                borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                border: Border.all(color: c.border),
              ),
              child: Row(
                children: [
                  Icon(Icons.search_rounded, color: c.textSecondary),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      onChanged: (_) => setState(() {}),
                      decoration: const InputDecoration(
                        hintText: 'Tìm mã hoặc tên voucher',
                        border: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        contentPadding:
                            EdgeInsets.symmetric(vertical: AppSpacing.lg),
                      ),
                    ),
                  ),
                  if (_searchController.text.trim().isNotEmpty)
                    GestureDetector(
                      onTap: () {
                        _searchController.clear();
                        setState(() {});
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(AppSpacing.xs),
                        child: Icon(
                          Icons.close_rounded,
                          color: c.textSecondary,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            Text(
              'Mã giảm giá đang diễn ra',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: c.textPrimary,
                  ),
            ),
            const SizedBox(height: AppSpacing.md),
            if (voucherProv.isLoading && vouchers.isEmpty)
              const LoadingView()
            else if (voucherProv.error != null)
              StatusView(
                icon: Icons.error_outline_rounded,
                title: voucherProv.error!,
                danger: true,
              )
            else if (filteredVouchers.isEmpty)
              const StatusView(
                icon: Icons.local_offer_outlined,
                title: 'Không tìm thấy mã voucher phù hợp.',
              )
            else
              ...filteredVouchers.map((v) => _VoucherCard(v: v)),
          ],
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final IconData icon;

  const _SummaryCard({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(
        vertical: AppSpacing.lg,
        horizontal: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(color: c.border),
      ),
      child: Column(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(height: AppSpacing.sm),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: c.textPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(fontSize: 11, color: c.textSecondary),
          ),
        ],
      ),
    );
  }
}

class _VoucherCard extends StatelessWidget {
  final dynamic v;

  const _VoucherCard({required this.v});

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final isCollected = context.read<VoucherProvider>().isCollected(v.id);
    final isPercentage = v.discountType == 'percentage';
    // Giam theo phan tram va giam tien mat dung hai mau khac nhau de phan biet.
    final kindColor = isPercentage ? c.primary : c.success;

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.lg),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusXl),
        border: Border.all(color: c.border),
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              width: 118,
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: kindColor.withValues(alpha: 0.1),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(AppTheme.radiusXl),
                  bottomLeft: Radius.circular(AppTheme.radiusXl),
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    isPercentage
                        ? Icons.percent_rounded
                        : Icons.attach_money_rounded,
                    color: kindColor,
                    size: 26,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    isPercentage
                        ? '${v.discountValue}% OFF'
                        : '${v.discountValue ~/ 1000}K',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                      color: kindColor,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            v.title,
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              color: c.textPrimary,
                              fontSize: 15,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.sm,
                            vertical: AppSpacing.xs,
                          ),
                          decoration: BoxDecoration(
                            color: kindColor.withValues(alpha: 0.12),
                            borderRadius:
                                BorderRadius.circular(AppTheme.radiusPill),
                          ),
                          child: Text(
                            isPercentage ? 'Giảm %' : 'Giảm tiền',
                            style: TextStyle(
                              color: kindColor,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm,
                        vertical: AppSpacing.xs,
                      ),
                      decoration: BoxDecoration(
                        color: c.surfaceVariant,
                        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                      ),
                      child: Text(
                        v.code,
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.8,
                          color: c.textPrimary,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      'Đơn tối thiểu ${_formatCurrency(v.minOrderValue)}đ • HSD ${_formatDate(v.endDate)}',
                      style: TextStyle(fontSize: 12, color: c.textSecondary),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Row(
                      children: [
                        Expanded(
                          child: SecondaryButton(
                            label: 'Sao chép',
                            icon: Icons.copy_all_rounded,
                            height: 42,
                            onPressed: () {
                              Clipboard.setData(ClipboardData(text: v.code));
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Đã sao chép: ${v.code}'),
                                  duration: const Duration(seconds: 2),
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        PrimaryButton(
                          label: isCollected ? 'Đã lưu' : 'Lưu mã',
                          expanded: false,
                          height: 42,
                          onPressed: isCollected
                              ? null
                              : () {
                                  context
                                      .read<VoucherProvider>()
                                      .collectVoucher(v.id);
                                  context
                                      .read<NotificationProvider>()
                                      .addNotification(
                                        title: 'Đã lưu voucher ${v.code}',
                                        body:
                                            'Bạn đã lưu thành công ưu đãi ${v.title}. Hãy áp dụng tại bước thanh toán để nhận giảm giá!',
                                        type: 'promo',
                                        data: {
                                          'code': v.code,
                                          'voucherId': v.id,
                                        },
                                      );
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        'Đã lưu mã ${v.code} vào ví của bạn',
                                      ),
                                      backgroundColor: c.success,
                                    ),
                                  );
                                },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatCurrency(int value) => value.toString().replaceAllMapped(
        RegExp(r'\B(?=(\d{3})+(?!\d))'),
        (Match m) => ',',
      );

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
}
