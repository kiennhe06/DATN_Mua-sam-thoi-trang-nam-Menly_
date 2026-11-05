import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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
        const SnackBar(
          content: Text('Đã áp dụng mã giảm giá thành công!'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();
    final voucherProv = context.watch<VoucherProvider>();
    final vouchers = voucherProv.vouchers;

    return Container(
      padding: EdgeInsets.only(
        top: 20,
        left: 16,
        right: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
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
              const Text(
                'Mã giảm giá Menly',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Đóng',
                    style: TextStyle(
                        color: Colors.grey, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 12),
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
                        borderRadius: BorderRadius.circular(8)),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    isDense: true,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black87,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                onPressed: () => _applyInputCode(cart, voucherProv),
                child: const Text('Áp dụng'),
              ),
            ],
          ),
          if (_errorMessage != null) ...[
            const SizedBox(height: 6),
            Text(
              _errorMessage!,
              style: const TextStyle(color: Colors.red, fontSize: 12),
            ),
          ],
          const SizedBox(height: 16),
          const Text(
            'Mã giảm giá khả dụng',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          const SizedBox(height: 8),
          // Danh sach voucher
          Flexible(
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: vouchers.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (ctx, index) {
                final v = vouchers[index];
                final isSelected = cart.appliedVoucher?.id == v.id;

                return InkWell(
                  onTap: () {
                    final err = cart.applyVoucher(v);
                    if (err != null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                            content: Text(err), backgroundColor: Colors.red),
                      );
                    } else {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Đã áp dụng mã "${v.code}"!'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    }
                  },
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: isSelected
                            ? Colors.deepOrange
                            : Colors.grey.shade300,
                        width: isSelected ? 2 : 1,
                      ),
                      borderRadius: BorderRadius.circular(10),
                      color: isSelected ? Colors.amber.shade50 : Colors.white,
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.orange.shade100,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            v.discountType == 'percentage'
                                ? '${v.discountValue}%'
                                : '${v.discountValue ~/ 1000}k',
                            style: const TextStyle(
                                color: Colors.deepOrange,
                                fontWeight: FontWeight.bold,
                                fontSize: 13),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    v.code,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 15),
                                  ),
                                  if (isSelected)
                                    Container(
                                      margin: const EdgeInsets.only(left: 8),
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: Colors.green,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: const Text('Đang dùng',
                                          style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold)),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 2),
                              Text(v.title,
                                  style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.grey.shade800)),
                              const SizedBox(height: 4),
                              Text(
                                'Không giới hạn đơn tối thiểu • HSD: ${v.endDate.day}/${v.endDate.month}/${v.endDate.year}',
                                style: TextStyle(
                                    fontSize: 11, color: Colors.grey.shade600),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          isSelected ? '✓' : '',
                          style: const TextStyle(
                              color: Colors.deepOrange,
                              fontWeight: FontWeight.bold,
                              fontSize: 20),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          if (cart.appliedVoucher != null) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red,
                  side: const BorderSide(color: Colors.red),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: () {
                  cart.removeVoucher();
                  Navigator.pop(context);
                },
                child: const Text('Bỏ chọn mã giảm giá'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
