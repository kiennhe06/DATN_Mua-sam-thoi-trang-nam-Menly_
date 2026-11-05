import 'package:flutter/material.dart';

enum VNPayPaymentCategory {
  all,
  qr,
  atm,
  intl,
}

class VNPayBank {
  final String code;
  final String name;
  final String fullName;
  final String category; // 'qr' | 'atm' | 'intl'
  final bool isSandboxRecommended;
  final Color primaryColor;

  const VNPayBank({
    required this.code,
    required this.name,
    required this.fullName,
    required this.category,
    this.isSandboxRecommended = false,
    required this.primaryColor,
  });
}

/// Danh sách ngân hàng & phương thức hỗ trợ bởi VNPay Sandbox
final List<VNPayBank> kVNPayBankList = [
  // --- Sandbox Khuyên dùng ---
  const VNPayBank(
    code: 'NCB',
    name: 'NCB',
    fullName: 'Ngân hàng Quốc Dân (Demo Thử Nghiệm)',
    category: 'atm',
    isSandboxRecommended: true,
    primaryColor: Color(0xFF005AAB),
  ),

  // --- VNPAY QR ---
  const VNPayBank(
    code: 'VNPAYQR',
    name: 'VNPAY-QR',
    fullName: 'Quét mã QR qua ứng dụng Ngân hàng / Ví',
    category: 'qr',
    primaryColor: Color(0xFFE11B22),
  ),

  // --- Ngân hàng nội địa ATM ---
  const VNPayBank(
    code: 'VIETCOMBANK',
    name: 'Vietcombank',
    fullName: 'Ngân hàng TMCP Ngoại Thương Việt Nam',
    category: 'atm',
    primaryColor: Color(0xFF007A33),
  ),
  const VNPayBank(
    code: 'VIETINBANK',
    name: 'VietinBank',
    fullName: 'Ngân hàng TMCP Công Thương Việt Nam',
    category: 'atm',
    primaryColor: Color(0xFF005BAA),
  ),
  const VNPayBank(
    code: 'BIDV',
    name: 'BIDV',
    fullName: 'Ngân hàng TMCP Đầu tư và Phát triển VN',
    category: 'atm',
    primaryColor: Color(0xFF0A3B7B),
  ),
  const VNPayBank(
    code: 'AGRIBANK',
    name: 'Agribank',
    fullName: 'Ngân hàng Nông nghiệp & Phát triển Nông thôn',
    category: 'atm',
    primaryColor: Color(0xFF8B1D2C),
  ),
  const VNPayBank(
    code: 'TECHCOMBANK',
    name: 'Techcombank',
    fullName: 'Ngân hàng TMCP Kỹ Thương Việt Nam',
    category: 'atm',
    primaryColor: Color(0xFFED1C24),
  ),
  const VNPayBank(
    code: 'MBBANK',
    name: 'MBBank',
    fullName: 'Ngân hàng TMCP Quân Đội',
    category: 'atm',
    primaryColor: Color(0xFF00386B),
  ),
  const VNPayBank(
    code: 'ACB',
    name: 'ACB',
    fullName: 'Ngân hàng TMCP Á Châu',
    category: 'atm',
    primaryColor: Color(0xFF004F9F),
  ),
  const VNPayBank(
    code: 'VPBANK',
    name: 'VPBank',
    fullName: 'Ngân hàng TMCP Việt Nam Thịnh Vượng',
    category: 'atm',
    primaryColor: Color(0xFF008853),
  ),
  const VNPayBank(
    code: 'TPBANK',
    name: 'TPBank',
    fullName: 'Ngân hàng TMCP Tiên Phong',
    category: 'atm',
    primaryColor: Color(0xFF5B2D82),
  ),
  const VNPayBank(
    code: 'SACOMBANK',
    name: 'Sacombank',
    fullName: 'Ngân hàng TMCP Sài Gòn Thương Tín',
    category: 'atm',
    primaryColor: Color(0xFF00529C),
  ),
  const VNPayBank(
    code: 'HDBANK',
    name: 'HDBank',
    fullName: 'Ngân hàng TMCP Phát triển TP.HCM',
    category: 'atm',
    primaryColor: Color(0xFFD3202A),
  ),

  // --- Thẻ quốc tế ---
  const VNPayBank(
    code: 'VISA',
    name: 'VISA',
    fullName: 'Thẻ thanh toán quốc tế Visa',
    category: 'intl',
    primaryColor: Color(0xFF1A1F71),
  ),
  const VNPayBank(
    code: 'MASTERCARD',
    name: 'MasterCard',
    fullName: 'Thẻ thanh toán quốc tế MasterCard',
    category: 'intl',
    primaryColor: Color(0xFFEB001B),
  ),
  const VNPayBank(
    code: 'JCB',
    name: 'JCB',
    fullName: 'Thẻ thanh toán quốc tế JCB',
    category: 'intl',
    primaryColor: Color(0xFF0E4C92),
  ),
];
