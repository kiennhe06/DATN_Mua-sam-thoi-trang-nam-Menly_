import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/network/api_client.dart';

class UserModel {
  final String id;
  final String email;
  final String fullName;
  final String? phone;
  final String? avatarUrl;
  final String role;

  UserModel({
    required this.id,
    required this.email,
    required this.fullName,
    this.phone,
    this.avatarUrl,
    this.role = 'customer',
  });

  UserModel copyWith({
    String? fullName,
    String? phone,
    String? avatarUrl,
  }) {
    return UserModel(
      id: id,
      email: email,
      fullName: fullName ?? this.fullName,
      phone: phone ?? this.phone,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      role: role,
    );
  }

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      fullName: json['full_name']?.toString() ?? json['fullName']?.toString() ?? 'Khách hàng Menly',
      phone: json['phone']?.toString(),
      avatarUrl: json['avatar_url']?.toString() ?? json['avatarUrl']?.toString(),
      role: json['role']?.toString() ?? 'customer',
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'email': email,
    'full_name': fullName,
    'phone': phone,
    'avatar_url': avatarUrl,
    'role': role,
  };
}

class AuthProvider extends ChangeNotifier {
  final ApiClient _api = ApiClient();
  UserModel? _user;
  bool _isLoading = false;

  UserModel? get user => _user;
  bool get isLoggedIn => _user != null;
  bool get isLoading => _isLoading;

  Future<void> init() async {
    await loadProfile();
  }

  Future<void> loadProfile() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userStr = prefs.getString('user_profile');
      if (userStr != null) {
        _user = UserModel.fromJson(jsonDecode(userStr));
        notifyListeners();
      }

      final token = prefs.getString('access_token');
      if (token != null) {
        try {
          final res = await _api.dio.get('/auth/me');
          if (res.statusCode == 200 && res.data != null && res.data['data'] != null) {
            _user = UserModel.fromJson(res.data['data']);
            await prefs.setString('user_profile', jsonEncode(_user!.toJson()));
            notifyListeners();
          }
        } catch (_) {}
      } else if (_user == null) {
        // Mac dinh ho so mau
        _user = UserModel(
          id: 'user-demo',
          email: 'demo@menly.vn',
          fullName: 'Phạm Đức Kiên',
          phone: '0973735876',
          avatarUrl: 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=300&auto=format&fit=crop&q=80',
        );
        notifyListeners();
      }
    } catch (_) {}
  }

  Future<bool> updateProfile({
    required String fullName,
    required String phone,
    String? avatarUrl,
  }) async {
    if (_user == null) return false;
    _isLoading = true;
    notifyListeners();

    try {
      _user = _user!.copyWith(
        fullName: fullName.trim(),
        phone: phone.trim(),
        avatarUrl: avatarUrl?.trim(),
      );

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_profile', jsonEncode(_user!.toJson()));

      try {
        await _api.dio.put('/auth/profile', data: {
          'full_name': _user!.fullName,
          'phone': _user!.phone,
          'avatar_url': _user!.avatarUrl,
        });
      } catch (_) {}

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (_) {
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('access_token');
    await prefs.remove('refresh_token');
    await prefs.remove('user_profile');
    _user = null;
    notifyListeners();
  }

  void setUserFromLogin(UserModel user) async {
    _user = user;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_profile', jsonEncode(user.toJson()));
    notifyListeners();
  }
}
