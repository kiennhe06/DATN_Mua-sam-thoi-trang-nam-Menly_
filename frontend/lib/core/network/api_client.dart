import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../utils/app_logger.dart';

/// Khu vuc ghi log cua tang goi API.
const String _khuVuc = 'API';

/// Ghi lai mot lan goi API that bai.
///
/// Chi ghi duong dan, ma loi va thong bao. KHONG ghi header va KHONG ghi
/// than request: header co 'Authorization: Bearer ...', con than request co
/// mat khau luc dang nhap va dia chi nha luc dat hang. Log nam lai trong may
/// nen cho gi vao day la coi nhu de lo cai do.
void _ghiLoiGoiApi(DioException error) {
  final duongDan = '${error.requestOptions.method} ${error.requestOptions.path}';
  final maLoi = error.response?.statusCode;

  if (maLoi != null) {
    AppLogger.canhBao(
      'Gọi API lỗi $maLoi: $duongDan',
      khuVuc: _khuVuc,
      loi: error.message,
    );
    return;
  }

  // Khong co ma loi nghia la khong noi duoc toi may chu: mat mang, sai dia
  // chi, hoac qua han cho. Day la nhom loi hay gap nhat luc chay tren may that
  // ma truoc gio khong de lai dau vet nao.
  AppLogger.loi(
    'Không gọi được máy chủ: $duongDan (${error.type.name})',
    khuVuc: _khuVuc,
    loi: error.error ?? error.message,
    stackTrace: error.stackTrace,
  );
}

/// Lop goi API chung toi backend Menly.
class ApiClient {
  static final ApiClient _instance = ApiClient._internal();
  factory ApiClient() => _instance;

  /// Cho phep cau hinh dia chi backend that khi chay tren may that:
  /// flutter run --dart-define=API_BASE_URL=http://192.168.1.10:5000/api/v1
  static const String _envBaseUrl = String.fromEnvironment('API_BASE_URL');

  late final Dio _dio;
  Dio get dio => _dio;

  late final String baseUrl;

  /// Goc may chu (scheme + host + port), dung de tao lien ket chia se that.
  String get origin {
    final uri = Uri.parse(baseUrl);
    return '${uri.scheme}://${uri.authority}';
  }

  ApiClient._internal() {
    var url = _envBaseUrl.trim();
    if (url.isEmpty) {
      url = 'http://10.0.2.2:5000/api/v1';
      if (kIsWeb ||
          (!kIsWeb &&
              (Platform.isWindows ||
                  Platform.isLinux ||
                  Platform.isMacOS))) {
        url = 'http://localhost:5000/api/v1';
      }
    }
    baseUrl = url.endsWith('/') ? url.substring(0, url.length - 1) : url;

    _dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 8),
      receiveTimeout: const Duration(seconds: 8),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ));

    // Tu dong gan Bearer Token vao Header khi nguoi dung da dang nhap
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          try {
            final prefs = await SharedPreferences.getInstance();
            final token =
                prefs.getString('access_token') ?? prefs.getString('token');
            if (token != null && token.isNotEmpty) {
              options.headers['Authorization'] = 'Bearer $token';
            }
          } catch (e, s) {
            // Doc duoc token hay khong thi request van di tiep, chi la di khi
            // chua dang nhap. Nhung phai ghi lai: neu kho luu tru hong thi moi
            // man can dang nhap deu bao 401 ma khong ai hieu tai sao.
            AppLogger.loi(
              'Không đọc được token đã lưu, gửi request không kèm đăng nhập',
              khuVuc: _khuVuc,
              loi: e,
              stackTrace: s,
            );
          }
          if (options.data is FormData) {
            options.headers.remove('Content-Type');
            options.headers.remove('content-type');
          }
          return handler.next(options);
        },
        onError: (DioException error, handler) async {
          if (error.response?.statusCode == 401) {
            try {
              final prefs = await SharedPreferences.getInstance();
              final refreshToken = prefs.getString('refresh_token');
              if (refreshToken != null && refreshToken.isNotEmpty) {
                // Gọi làm mới access token với Dio độc lập để tránh vòng lặp
                final refreshDio = Dio(BaseOptions(
                  baseUrl: baseUrl,
                  connectTimeout: const Duration(seconds: 5),
                  receiveTimeout: const Duration(seconds: 5),
                ));
                final res = await refreshDio.post('/auth/refresh-token', data: {
                  'refreshToken': refreshToken,
                });
                if (res.statusCode == 200 && res.data?['data']?['accessToken'] != null) {
                  final newAccessToken = res.data['data']['accessToken'].toString();
                  final newRefreshToken = res.data['data']['refreshToken']?.toString() ?? refreshToken;
                  await prefs.setString('access_token', newAccessToken);
                  await prefs.setString('refresh_token', newRefreshToken);

                  // Thử lại request ban đầu với token mới
                  final retryOptions = error.requestOptions;
                  retryOptions.headers['Authorization'] = 'Bearer $newAccessToken';
                  final retryResponse = await _dio.fetch(retryOptions);
                  return handler.resolve(retryResponse);
                }
              }
            } catch (e) {
              // Refresh that bai (het han hoan toan). Ghi lai de phan biet
              // "token het han that" voi "may chu refresh dang hong".
              AppLogger.canhBao(
                'Làm mới token thất bại, người dùng sẽ bị đăng xuất',
                khuVuc: _khuVuc,
                loi: e,
              );
            }
          }

          _ghiLoiGoiApi(error);
          return handler.next(error);
        },
      ),
    );
  }
}
