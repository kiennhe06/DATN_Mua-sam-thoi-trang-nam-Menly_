import 'package:flutter/material.dart';

/// Trang Gioi thieu thuong hieu Menly
class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Giới thiệu'),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 28),
            decoration: BoxDecoration(
              color: Colors.black87,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Column(
              children: [
                Text(
                  'MENLY',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 28,
                    letterSpacing: 3,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Thời trang nam hiện đại, lịch lãm và dễ mặc mỗi ngày',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white70, fontSize: 14, height: 1.4),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Về chúng tôi',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Menly là cửa hàng thời trang nam hướng tới phong cách tối giản, form dáng vừa vặn và chất liệu bền. '
            'Chúng tôi mang đến áo sơ mi, áo thun, quần jeans, quần tây và áo khoác phù hợp đi học, đi làm lẫn đi chơi.',
            style: TextStyle(fontSize: 14, color: Colors.grey.shade800, height: 1.5),
          ),
          const SizedBox(height: 20),
          _infoCard(
            icon: Icons.checkroom,
            title: 'Sản phẩm chọn lọc',
            body: 'Mỗi mẫu được chọn theo xu hướng nhưng vẫn dễ phối. Ưu tiên vải thoáng, đứng form và bền sau nhiều lần giặt.',
          ),
          _infoCard(
            icon: Icons.straighten,
            title: 'Size rõ ràng',
            body: 'Bảng size theo chiều cao – cân nặng giúp bạn chọn vừa hơn: Size M (50–62kg), L (63–72kg), XL (73–82kg).',
          ),
          _infoCard(
            icon: Icons.local_shipping_outlined,
            title: 'Giao hàng toàn quốc',
            body: 'Đơn tiêu chuẩn 25.000 đ, hỏa tốc 45.000 đ. Miễn phí vận chuyển khi đơn từ 499.000 đ.',
          ),
          const SizedBox(height: 8),
          Text(
            'Menly — mặc đẹp, mặc đúng, mặc mỗi ngày.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: Colors.grey.shade600, fontStyle: FontStyle.italic),
          ),
        ],
      ),
    );
  }

  Widget _infoCard({required IconData icon, required String title, required String body}) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.grey.shade100,
          child: Icon(icon, color: Colors.black87),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(body, style: TextStyle(fontSize: 13, color: Colors.grey.shade700, height: 1.4)),
        ),
        isThreeLine: true,
      ),
    );
  }
}
