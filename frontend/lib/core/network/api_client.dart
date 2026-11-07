import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
          } catch (_) {}
          if (options.data is FormData) {
            options.headers.remove('Content-Type');
            options.headers.remove('content-type');
          }
          return handler.next(options);
        },
      ),
    );
  }
}
