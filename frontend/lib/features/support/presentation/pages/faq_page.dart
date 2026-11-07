import 'package:flutter/material.dart';
import 'package:menly_app/features/support/presentation/pages/contact_page.dart';
import 'package:menly_app/features/support/presentation/pages/policy_page.dart';

/// Trang Cau hoi thuong gap (FAQ) (TM05)
class FAQPage extends StatefulWidget {
  const FAQPage({super.key});

  @override
  State<FAQPage> createState() => _FAQPageState();
}

class _FAQPageState extends State<FAQPage> {
  String _searchQuery = '';

  final List<Map<String, dynamic>> _faqs = [
    {
      'category': 'Đặt hàng & Mua sắm',
      'items': [
        {
          'q': 'Làm thế nào để đặt hàng trên ứng dụng Menly?',
          'a': 'Bạn chỉ cần chọn sản phẩm yêu thích, chọn kích cỡ (size) và màu sắc, bấm "Thêm vào giỏ hàng" hoặc "Mua ngay". Sau đó vào giỏ hàng, áp dụng mã giảm giá (nếu có), điền địa chỉ nhận hàng và chọn phương thức thanh toán để hoàn tất.',
        },
        {
          'q': 'Tôi có thể thay đổi hoặc hủy đơn hàng sau khi đặt không?',
          'a': 'Bạn có thể chủ động bấm "Hủy đơn hàng" tại màn hình "Đơn của tôi" khi đơn hàng đang ở trạng thái "Chờ thanh toán" hoặc "Đang xử lý". Nếu đơn hàng đã chuyển sang trạng thái "Đang giao hàng", vui lòng liên hệ tổng đài để được hỗ trợ.',
        },
        {
          'q': 'Làm sao để biết kích cỡ (size) nào vừa vặn với tôi?',
          'a': 'Tại màn hình chi tiết sản phẩm, bạn có thể tham khảo bảng quy đổi kích cỡ chuẩn theo chiều cao và cân nặng của Menly (Size M: 50-62kg, Size L: 63-72kg, Size XL: 73-82kg).',
        },
      ],
    },
    {
      'category': 'Vận chuyển & Giao nhận',
      'items': [
        {
          'q': 'Thời gian giao hàng mất bao lâu?',
          'a': 'Thời gian giao hàng tiêu chuẩn là từ 1–2 ngày làm việc đối với khu vực nội thành (TP.HCM, Hà Nội) và 3–4 ngày làm việc đối với các tỉnh thành khác.',
        },
        {
          'q': 'Phí vận chuyển được tính như thế nào?',
          'a': 'Phí vận chuyển mặc định là 25.000 đ cho toàn quốc. Đặc biệt, Menly miễn phí vận chuyển cho các đơn hàng từ 300.000 đ khi áp dụng mã FREESHIP.',
        },
        {
          'q': 'Tôi có được kiểm tra hàng trước khi thanh toán không?',
          'a': 'Có. Menly hỗ trợ đồng kiểm khi nhận hàng. Bạn được quyền kiểm tra đúng mẫu mã, màu sắc và số lượng trước khi thanh toán tiền cho shipper.',
        },
      ],
    },
    {
      'category': 'Đổi trả & Hoàn tiền',
      'items': [
        {
          'q': 'Chính sách đổi trả hàng của Menly như thế nào?',
          'a': 'Menly hỗ trợ đổi trả sản phẩm trong vòng 7 ngày kể từ ngày nhận hàng với điều kiện sản phẩm còn nguyên tem mác, chưa qua giặt ủi và chưa có dấu hiệu sử dụng.',
        },
        {
          'q': 'Trường hợp nào được miễn phí đổi trả?',
          'a': 'Nếu sản phẩm bị lỗi do nhà sản xuất (rách chỉ, phai màu bất thường, giao sai kích thước hoặc màu sắc), Menly sẽ chịu 100% phí vận chuyển đổi trả hai chiều cho bạn.',
        },
      ],
    },
    {
      'category': 'Thanh toán & Mã giảm giá',
      'items': [
        {
          'q': 'Menly hỗ trợ những hình thức thanh toán nào?',
          'a': 'Menly hỗ trợ thanh toán khi nhận hàng (COD) và thanh toán trực tuyến qua cổng VNPay (Quét mã VNPAY-QR, Thẻ ATM nội địa, Thẻ quốc tế Visa/MasterCard).',
        },
        {
          'q': 'Cách áp dụng mã giảm giá khi đặt hàng?',
          'a': 'Tại màn hình Giỏ hàng hoặc Xác nhận đơn hàng, chạm vào mục "Chọn hoặc nhập mã giảm giá", nhập mã bạn có hoặc chọn trực tiếp mã voucher trong danh sách để được giảm giá ngay lập tức.',
        },
      ],
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Câu hỏi thường gặp (FAQ)'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Thanh tim kiem cau hoi
            Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Tìm kiếm câu hỏi thắc mắc...',
                  
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  filled: true,
                  fillColor: Colors.grey.shade100,
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                ),
                onChanged: (val) => setState(() => _searchQuery = val.toLowerCase().trim()),
              ),
            ),

            // Danh sach cau hoi theo chu de
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _faqs.length,
              itemBuilder: (ctx, i) {
                final category = _faqs[i]['category'] as String;
                final items = (_faqs[i]['items'] as List<Map<String, String>>).where((item) {
                  if (_searchQuery.isEmpty) return true;
                  return item['q']!.toLowerCase().contains(_searchQuery) ||
                      item['a']!.toLowerCase().contains(_searchQuery);
                }).toList();

                if (items.isEmpty) return const SizedBox.shrink();

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Text(
                        category,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                    Card(
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: Colors.grey.shade200),
                      ),
                      child: Column(
                        children: items.map((item) {
                          return Theme(
                            data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                            child: ExpansionTile(
                              
                              title: Text(
                                item['q']!,
                                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                              ),
                              children: [
                                Padding(
                                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                                  child: Text(
                                    item['a']!,
                                    style: TextStyle(fontSize: 13, color: Colors.grey.shade700, height: 1.4),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                );
              },
            ),

            // Hop thoai lien he ho tro
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  const Text('Bạn vẫn chưa tìm thấy câu trả lời?',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  const SizedBox(height: 6),
                  Text('Đội ngũ chăm sóc khách hàng Menly luôn sẵn sàng 24/7',
                      style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.black87,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        child: const Text('Hotline: 1900 6868'),
                        onPressed: () {
                          Navigator.push(context, MaterialPageRoute(builder: (_) => const ContactPage()));
                        },
                      ),
                      const SizedBox(width: 8),
                      TextButton(
                        onPressed: () {
                          Navigator.push(context, MaterialPageRoute(builder: (_) => const PolicyPage()));
                        },
                        child: const Text('Xem chính sách'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

