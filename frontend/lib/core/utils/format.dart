/// Formats a number with dot separators, e.g. 1200000 -> "1.200.000"
String formatNumber(num amount) {
  final s = amount.abs().toStringAsFixed(0);
  final buf = StringBuffer();
  for (int i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) buf.write('.');
    buf.write(s[i]);
  }
  final sign = amount < 0 ? '-' : '';
  return '$sign${buf.toString()}';
}

/// Formats a number with VND suffix, e.g. 1200000 -> "1.200.000 đ"
String formatPrice(num amount) {
  return '${formatNumber(amount)} đ';
}

/// Formats an integer or double VND amount as "1.200.000đ".
String formatVnd(num amount) {
  return '${formatNumber(amount)}đ';
}
