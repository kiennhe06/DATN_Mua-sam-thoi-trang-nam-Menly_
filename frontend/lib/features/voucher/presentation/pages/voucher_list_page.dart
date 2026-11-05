import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/voucher_provider.dart';

/// Trang khuyen mai gom ma giam gia Menly (TM10)
class VoucherListPage extends StatelessWidget {
  const VoucherListPage({super.key});

  @override
  Widget build(BuildContext context) {
    final voucherProv = context.watch<VoucherProvider>();
    final vouchers = voucherProv.vouchers;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Kho Voucher & Khuyến Mãi'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Banner khuyen mai dau trang
            Container(
              width: double.infinity,
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.15),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.amber,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'ƯU ĐÃI ĐẶC QUYỀN MENLY',
                      style: TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Săn Mã Giảm Giá Cực Sốc\nLên Đến 100.000 Đ',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Thu thập voucher và áp dụng ngay tại bước thanh toán',
                    style: TextStyle(color: Colors.grey.shade300, fontSize: 13),
                  ),
                ],
              ),
            ),

            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                'Mã giảm giá đang diễn ra',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),

            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemCount: vouchers.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (ctx, i) {
                final v = vouchers[i];
                final isCollected = voucherProv.isCollected(v.id);

                return Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.grey.shade200),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      // Ben trai voucher: Icon va loai giam
                      Container(
                        width: 100,
                        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 8),
                        decoration: BoxDecoration(
                          color: v.discountType == 'percentage'
                              ? Colors.deepOrange.shade50
                              : Colors.blue.shade50,
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(14),
                            bottomLeft: Radius.circular(14),
                          ),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [

                            Text(
                              v.discountType == 'percentage'
                                  ? 'GIẢM ${v.discountValue}%'
                                  : 'GIẢM ${v.discountValue ~/ 1000}K',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                color: v.discountType == 'percentage'
                                    ? Colors.deepOrange
                                    : Colors.blue.shade800,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Ben phai voucher: Thong tin chi tiet
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: Colors.grey.shade100,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      v.code,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                        letterSpacing: 0.8,
                                      ),
                                    ),
                                  ),
                                  IconButton(
                                    constraints: const BoxConstraints(),
                                    padding: EdgeInsets.zero,
                                    icon: const Text("Sao chép", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.blueGrey)),
                                    tooltip: 'Sao chép mã',
                                    onPressed: () {
                                      Clipboard.setData(ClipboardData(text: v.code));
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text('Đã sao chép mã: ${v.code}'),
                                          duration: const Duration(seconds: 2),
                                        ),
                                      );
                                    },
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                v.title,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Không giới hạn đơn tối thiểu',
                                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'HSD: ${v.endDate.day}/${v.endDate.month}/${v.endDate.year}',
                                    style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                                  ),
                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: isCollected ? Colors.grey.shade300 : Colors.black87,
                                      foregroundColor: isCollected ? Colors.grey.shade700 : Colors.white,
                                      elevation: 0,
                                      visualDensity: VisualDensity.compact,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                                    ),
                                    onPressed: isCollected
                                        ? null
                                        : () {
                                            voucherProv.collectVoucher(v.id);
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(
                                                content: Text('Đã lưu mã ${v.code} vào ví voucher của bạn!'),
                                                backgroundColor: Colors.green,
                                              ),
                                            );
                                          },
                                    child: Text(isCollected ? 'Đã lưu' : 'Lưu mã'),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
