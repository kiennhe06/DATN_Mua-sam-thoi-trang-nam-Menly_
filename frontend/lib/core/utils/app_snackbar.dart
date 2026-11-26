import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_theme.dart';

/// Helper tiện ích cho SnackBar trong toàn ứng dụng MenShop.
///
/// Luôn gọi qua đây thay vì `ScaffoldMessenger.showSnackBar` trực tiếp. Gọi
/// thẳng sẽ lấy mặc định của Flutter là **4 giây và xếp hàng chờ nhau**: thêm
/// 4 món vào giỏ là có 16 giây thông báo nằm đè dưới đáy màn hình, bấm nút
/// thanh toán không được vì SnackBar ăn luôn cú chạm trong vùng của nó.
class AppSnackBar {
  AppSnackBar._();

  /// Thời gian hiển thị mặc định: đủ đọc một câu ngắn rồi biến mất.
  static const Duration defaultDuration = Duration(milliseconds: 1500);

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
          RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusSm),
          ),
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
    final c = AppColors.of(context);
    final messenger = ScaffoldMessenger.of(context);
    // removeCurrentSnackBar bo ngay lap tuc, con hideCurrentSnackBar con chay
    // hoat anh tat roi moi den cai moi. Bam them hang lien tay thi cai sau
    // phai doi cai truoc dong xong, nhin nhu app bi khuc khuyu.
    messenger.removeCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        content: icon != null
            ? Row(
                children: [
                  Icon(icon, color: c.onInk, size: 20),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(child: Text(message)),
                ],
              )
            : Text(message),
        backgroundColor: backgroundColor,
        duration: duration,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusSm),
        ),
        action: action,
      ),
    );
  }
}
