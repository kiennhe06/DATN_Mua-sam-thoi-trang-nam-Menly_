import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:menly_app/core/theme/app_colors.dart';
import 'package:menly_app/core/theme/app_spacing.dart';
import 'package:menly_app/core/theme/app_theme.dart';
import 'package:menly_app/core/widgets/app_buttons.dart';
import 'package:menly_app/features/cart/presentation/providers/cart_provider.dart';
import 'package:menly_app/features/voucher/presentation/providers/voucher_provider.dart';

/// Bottom Sheet chon hoac nhap ma giam gia khi dat hang (AP-VC1)
class VoucherSelectSheet extends StatefulWidget {
  const VoucherSelectSheet({super.key});

  @override
  State<VoucherSelectSheet> createState() => _VoucherSelectSheetState();
}

class _VoucherSelectSheetState extends State<VoucherSelectSheet> {
  final _codeController = TextEditingController();
  String? _errorMessage;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  void _applyInputCode(CartProvider cart, VoucherProvider voucherProv) {
    // Doc mau truoc khi dong sheet vi sau pop khong tra cuu theme duoc nua.
    final c = AppColors.of(context);
    setState(() => _errorMessage = null);
    final code = _codeController.text.trim();
    if (code.isEmpty) {
      setState(() => _errorMessage = 'Vui lòng nhập mã giảm giá');
      return;
    }

    // Chi ap dung voucher co that tu API (VoucherProvider)
    final voucher = voucherProv.findByCode(code);
    if (voucher == null) {
      setState(
          () => _errorMessage = 'Mã giảm giá không tồn tại hoặc đã hết hạn');
      return;
    }

    final error = cart.applyVoucher(voucher);
    if (error != null) {
      setState(() => _errorMessage = error);
    } else {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Đã áp dụng mã giảm giá thành công!'),
          backgroundColor: c.success,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final cart = context.watch<CartProvider>();
    final voucherProv = context.watch<VoucherProvider>();
    final vouchers = voucherProv.vouchers;

    return Container(
      padding: EdgeInsets.only(
        top: AppSpacing.xl,
        left: AppSpacing.lg,
        right: AppSpacing.lg,
        bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.xl,
      ),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.8,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Mã giảm giá Menly',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: c.textPrimary,
                ),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'Đóng',
                  style: TextStyle(
                    color: c.textMuted,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          // O nhap ma truc tiep
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _codeController,
                  textCapitalization: TextCapitalization.characters,
                  decoration: InputDecoration(
                    hintText: 'Nhập mã voucher (VD: WELCOME20, MENLY10)',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.sm,
                    ),
                    isDense: true,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              PrimaryButton(
                label: 'Áp dụng',
                expanded: false,
                height: 46,
                onPressed: () => _applyInputCode(cart, voucherProv),
              ),
            ],
          ),
          if (_errorMessage != null) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              _errorMessage!,
              style: TextStyle(color: c.danger, fontSize: 12),
            ),
          ],
          const SizedBox(height: AppSpacing.lg),
          Text(
            'Mã giảm giá khả dụng',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: c.textPrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          // Danh sach voucher
          Flexible(
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: vouchers.length,
              separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.md),
              itemBuilder: (ctx, index) {
                final v = vouchers[index];
                final isSelected = cart.appliedVoucher?.id == v.id;

                return InkWell(
                  onTap: () {
                    final err = cart.applyVoucher(v);
                    if (err != null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(err),
                          backgroundColor: c.danger,
                        ),
                      );
                    } else {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Đã áp dụng mã "${v.code}"!'),
                          backgroundColor: c.success,
                        ),
                      );
                    }
                  },
                  borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                  child: Container(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: isSelected ? c.primary : c.border,
                        width: isSelected ? 2 : 1,
                      ),
                      borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                      color: isSelected ? c.primarySoft : c.surface,
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.sm,
                            vertical: AppSpacing.xs,
                          ),
                          decoration: BoxDecoration(
                            color: c.primary.withValues(alpha: 0.1),
                            borderRadius:
                                BorderRadius.circular(AppTheme.radiusXs),
                          ),
                          child: Text(
                            v.discountType == 'percentage'
                                ? '${v.discountValue}%'
                                : '${v.discountValue ~/ 1000}k',
                            style: TextStyle(
                              color: c.primary,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    v.code,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                      color: c.textPrimary,
                                    ),
                                  ),
                                  if (isSelected)
                                    Container(
                                      margin: const EdgeInsets.only(
                                        left: AppSpacing.sm,
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: AppSpacing.xs,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: c.success,
                                        borderRadius: BorderRadius.circular(
                                          AppTheme.radiusXs,
                                        ),
                                      ),
                                      child: Text(
                                        'Đang dùng',
                                        style: TextStyle(
                                          color: c.onInk,
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 2),
                              Text(
                                v.title,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: c.textSecondary,
                                ),
                              ),
                              const SizedBox(height: AppSpacing.xs),
                              Text(
                                'Không giới hạn đơn tối thiểu • HSD: ${v.endDate.day}/${v.endDate.month}/${v.endDate.year}',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: c.textMuted,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          isSelected ? '✓' : '',
                          style: TextStyle(
                            color: c.primary,
                            fontWeight: FontWeight.bold,
                            fontSize: 20,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          if (cart.appliedVoucher != null) ...[
            const SizedBox(height: AppSpacing.md),
            SecondaryButton(
              label: 'Bỏ chọn mã giảm giá',
              height: 46,
              foreground: c.danger,
              onPressed: () {
                cart.removeVoucher();
                Navigator.pop(context);
              },
            ),
          ],
        ],
      ),
    );
  }
}
