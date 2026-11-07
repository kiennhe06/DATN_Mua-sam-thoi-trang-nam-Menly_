import 'package:flutter/material.dart';
import '../../../support/presentation/pages/about_page.dart';
import '../../../support/presentation/pages/contact_page.dart';
import '../../../support/presentation/pages/faq_page.dart';
import '../../../support/presentation/pages/policy_page.dart';

class HomeInfoFooter extends StatelessWidget {
  const HomeInfoFooter({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      padding: const EdgeInsets.fromLTRB(12, 14, 12, 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          const Text(
            'MENLY FASHION',
            style: TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 13,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'Thương hiệu thời trang nam cao cấp',
            style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 6),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 2,
            children: [
              TextButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AboutPage()),
                ),
                child: const Text('Giới thiệu', style: TextStyle(fontSize: 12)),
              ),
              TextButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ContactPage()),
                ),
                child: const Text('Liên hệ', style: TextStyle(fontSize: 12)),
              ),
              TextButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const PolicyPage()),
                ),
                child: const Text('Chính sách', style: TextStyle(fontSize: 12)),
              ),
              TextButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const FAQPage()),
                ),
                child: const Text('Hỏi đáp', style: TextStyle(fontSize: 12)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

