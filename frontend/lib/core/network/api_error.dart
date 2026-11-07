import 'package:dio/dio.dart';

/// Doi mot loi ky thuat thanh cau tieng Viet cho nguoi dung doc.
///
/// Nguoi dung khong can biet DioException hay ma HTTP la gi; ho can biet chuyen
/// gi vua xay ra va phai lam gi tiep. Uu tien dung thong bao do chinh backend
/// tra ve vi no sat tinh huong nhat, chi khi khong co moi dung cau mac dinh.
String friendlyErrorMessage(
  Object error, {
  String fallback = 'Có lỗi xảy ra, vui lòng thử lại.',
}) {
  if (error is! DioException) return fallback;

  switch (error.type) {
    case DioExceptionType.connectionTimeout:
    case DioExceptionType.sendTimeout:
    case DioExceptionType.receiveTimeout:
    case DioExceptionType.transformTimeout:
      return 'Máy chủ phản hồi quá lâu. Kiểm tra kết nối mạng rồi thử lại.';
    case DioExceptionType.connectionError:
    case DioExceptionType.unknown:
      return 'Không kết nối được máy chủ. Kiểm tra kết nối mạng rồi thử lại.';
    case DioExceptionType.cancel:
      return 'Yêu cầu đã bị hủy.';
    case DioExceptionType.badCertificate:
      return 'Kết nối tới máy chủ không an toàn.';
    case DioExceptionType.badResponse:
      break;
  }

  final status = error.response?.statusCode;
  final serverMessage = _serverMessage(error.response?.data);

  switch (status) {
    case 400:
    case 422:
      return serverMessage ?? 'Thông tin gửi lên chưa hợp lệ.';
    case 401:
      return 'Bạn cần đăng nhập để tiếp tục.';
    case 403:
      return serverMessage ?? 'Tài khoản của bạn không có quyền làm việc này.';
    case 404:
      return serverMessage ?? 'Không tìm thấy dữ liệu.';
    case 409:
      return serverMessage ?? 'Thao tác không còn hợp lệ, hãy tải lại.';
    case 429:
      return 'Bạn thao tác hơi nhanh. Chờ một lát rồi thử lại.';
  }

  if (status != null && status >= 500) {
    return 'Máy chủ đang gặp sự cố. Vui lòng thử lại sau.';
  }

  return serverMessage ?? fallback;
}

/// Backend tra loi theo dang {"error": "..."} hoac {"message": "..."}.
String? _serverMessage(dynamic data) {
  if (data is! Map) return null;

  for (final key in const ['error', 'message']) {
    final value = data[key];
    if (value is String && value.trim().isNotEmpty) {
      return value.trim();
    }
    if (value is Map && value['message'] is String) {
      final nested = (value['message'] as String).trim();
      if (nested.isNotEmpty) return nested;
    }
  }
  return null;
}
