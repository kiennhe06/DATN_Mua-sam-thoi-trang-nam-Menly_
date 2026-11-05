import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Lop goi API chung toi backend Menly.
class ApiClient {
  static final ApiClient _instance = ApiClient._internal();
  factory ApiClient() => _instance;

  late final Dio _dio;
  Dio get dio => _dio;

  ApiClient._internal() {
    const configuredApiUrl = String.fromEnvironment('API_BASE_URL');
    String baseUrl = configuredApiUrl.isNotEmpty
        ? configuredApiUrl
        : 'http://10.0.2.2:5000/api/v1';
    if (configuredApiUrl.isEmpty &&
        (kIsWeb ||
            (!kIsWeb &&
                (Platform.isWindows ||
                    Platform.isLinux ||
                    Platform.isMacOS)))) {
      baseUrl = 'http://localhost:5000/api/v1';
    }

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
          return handler.next(options);
        },
      ),
    );
  }
}
