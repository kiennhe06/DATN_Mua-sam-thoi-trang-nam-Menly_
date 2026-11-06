import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_buttons.dart';
import '../../data/models/order_model.dart';

class OrderReturnRequestDialog {
  static Future<void> show({
    required BuildContext context,
    required OrderModel order,
  }) async {
    final c = AppColors.of(context);
    final reasonController = TextEditingController();
    String selectedReason = 'Sản phẩm không đúng mô tả';

    final reasons = [
      'Sản phẩm không đúng mô tả',
      'Sản phẩm bị lỗi do nhà sản xuất',
      'Giao sai size hoặc màu',
      'Không còn nhu cầu sử dụng',
      'Khác',
    ];

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Container(
              decoration: BoxDecoration(
                color: c.surface,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
              ),
              padding: EdgeInsets.fromLTRB(
                20,
                14,
                20,
                MediaQuery.of(context).padding.bottom + 20,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 52,
                        height: 5,
                        decoration: BoxDecoration(
                          color: c.border,
                          borderRadius: BorderRadius.circular(99),
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: c.primarySoft,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Icon(Icons.assignment_return_rounded, color: c.primary),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Yêu cầu trả hàng',
                                style: TextStyle(
                                  color: c.textPrimary,
                                  fontSize: 20,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Đơn ${order.code}',
                                style: TextStyle(
                                  color: c.textSecondary,
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: c.background,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: c.border),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline_rounded, color: c.primary, size: 18),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Vui lòng mô tả rõ lý do và tình trạng sản phẩm để shop xử lý nhanh hơn.',
                              style: TextStyle(
                                color: c.textSecondary,
                                fontSize: 12.5,
                                height: 1.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      'Lý do trả hàng',
                      style: TextStyle(
                        color: c.textPrimary,
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: reasons.map((reason) {
                        final isSelected = selectedReason == reason;
                        return ChoiceChip(
                          label: Text(
                            reason,
                            style: TextStyle(
                              color: isSelected ? c.onPrimary : c.textPrimary,
                              fontWeight: FontWeight.w600,
                              fontSize: 12.5,
                            ),
                          ),
                          selected: isSelected,
                          onSelected: (_) => setState(() => selectedReason = reason),
                          selectedColor: c.primary,
                          backgroundColor: c.background,
                          side: BorderSide(color: isSelected ? c.primary : c.border),
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      'Mô tả chi tiết',
                      style: TextStyle(
                        color: c.textPrimary,
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: reasonController,
                      maxLines: 5,
                      minLines: 4,
                      decoration: InputDecoration(
                        hintText: 'Ví dụ: Sản phẩm giao sai size, chất liệu khác với hình ảnh... ',
                        hintStyle: TextStyle(color: c.textMuted, fontSize: 13),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: c.primarySoft,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.image_outlined, color: c.primary, size: 20),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Bạn có thể đính kèm ảnh minh chứng khi cần xác thực tình trạng sản phẩm.',
                              style: TextStyle(
                                color: c.textSecondary,
                                fontSize: 12.5,
                                height: 1.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    PrimaryButton(
                      label: 'Gửi yêu cầu trả hàng',
                      onPressed: () {
                        final detail = reasonController.text.trim();
                        final finalReason = detail.isEmpty ? selectedReason : '$selectedReason: $detail';

                        if (!context.mounted) return;
                        Navigator.pop(sheetContext);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Yêu cầu trả hàng của bạn đã được ghi nhận.\nLý do: $finalReason'),
                            behavior: SnackBarBehavior.floating,
                            backgroundColor: c.primary,
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 10),
                    SecondaryButton(
                      label: 'Đóng',
                      onPressed: () => Navigator.pop(sheetContext),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
