import 'package:flutter/material.dart';

/// Helper tiện ích cho SnackBar trong toàn ứng dụng MenShop.
/// Giảm thời gian hiển thị mặc định xuống 1500ms (1.5 giây)
/// và tự động ẩn SnackBar cũ để tránh hiện tượng xếp hàng chờ đợi.
class AppSnackBar {
  AppSnackBar._();

  /// Thời gian hiển thị mặc định của SnackBar trong toàn app (1.5 giây)
  static const Duration defaultDuration = Duration(milliseconds: 500);

  /// Tạo một đối tượng SnackBar với duration 1.5s mặc định
  static SnackBar create({
    required Widget content,
    Color? backgroundColor,
    Duration duration = defaultDuration,
    SnackBarBehavior behavior = SnackBarBehavior.floating,
    ShapeBorder? shape,
    SnackBarAction? action,
  }) {
    return SnackBar(
      content: content,
      backgroundColor: backgroundColor,
      duration: duration,
      behavior: behavior,
      shape:
          shape ??
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      action: action,
    );
  }

  /// Hiển thị SnackBar nhanh chóng và tự động dọn dẹp SnackBar cũ
  static void show(
    BuildContext context, {
    required String message,
    Color? backgroundColor,
    Duration duration = defaultDuration,
    IconData? icon,
    SnackBarAction? action,
  }) {
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        content: icon != null
            ? Row(
                children: [
                  Icon(icon, color: Colors.white, size: 20),
                  const SizedBox(width: 8),
                  Expanded(child: Text(message)),
                ],
              )
            : Text(message),
        backgroundColor: backgroundColor,
        duration: duration,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        action: action,
      ),
    );
  }
}
