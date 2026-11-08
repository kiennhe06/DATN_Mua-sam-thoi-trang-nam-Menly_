import 'dart:convert';
import 'package:dio/dio.dart';
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
    bool clearAvatar = false,
  }) {
    return UserModel(
      id: id,
      email: email,
      fullName: fullName ?? this.fullName,
      phone: phone ?? this.phone,
      avatarUrl: clearAvatar ? null : avatarUrl ?? this.avatarUrl,
      role: role,
    );
  }

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      fullName: json['full_name']?.toString() ??
          json['fullName']?.toString() ??
          'Khách hàng Menly',
      phone: json['phone']?.toString(),
      avatarUrl:
          json['avatar_url']?.toString() ?? json['avatarUrl']?.toString(),
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
  String? _profileUpdateError;

  UserModel? get user => _user;
  bool get isLoggedIn => _user != null;
  bool get isLoading => _isLoading;
  String? get profileUpdateError => _profileUpdateError;

  Future<void> init() async {
    await loadProfile();
  }

  Future<void> loadProfile() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('access_token');

      // Ho so trong bo nho dem chi la ban sao de hien nhanh, no khong thay the
      // duoc phien dang nhap. Khong co token thi dung coi la da dang nhap, neu
      // khong man hinh se hien ten nguoi dung trong khi moi yeu cau deu bi 401.
      if (token == null || token.isEmpty) {
        await _clearSession(prefs);
        return;
      }

      final userStr = prefs.getString('user_profile');
      if (userStr != null) {
        _user = UserModel.fromJson(jsonDecode(userStr));
        notifyListeners();
      }

      try {
        final res = await _api.dio.get('/auth/me');
        if (res.statusCode == 200 &&
            res.data != null &&
            res.data['data'] != null) {
          _user = UserModel.fromJson(res.data['data']);
          await prefs.setString('user_profile', jsonEncode(_user!.toJson()));
          notifyListeners();
        }
      } on DioException catch (error) {
        final status = error.response?.statusCode;
        if (status == 401 || status == 403) {
          // Token het han hoac bi thu hoi: phai dang xuat that su, de nguoi dung
          // biet ma dang nhap lai thay vi loay hoay khong them duoc vao gio.
          await _clearSession(prefs);
          return;
        }
        // Loi mang hoac may chu: giu ho so dem de app con dung duoc tam thoi.
      }
      // Bo sung ten hoac so dien thoai tu bo nho dem neu profile server chua kip dong bo
      if (_user != null) {
        final cachedName = prefs.getString('saved_user_name');
        final cachedPhone = prefs.getString('saved_user_phone');
        bool changed = false;
        String newName = _user!.fullName;
        String? newPhone = _user!.phone;
        if ((newName.isEmpty || newName == 'Khách hàng Menly') && cachedName != null && cachedName.isNotEmpty) {
          newName = cachedName;
          changed = true;
        }
        if ((newPhone == null || newPhone.isEmpty) && cachedPhone != null && cachedPhone.isNotEmpty) {
          newPhone = cachedPhone;
          changed = true;
        }
        if (changed) {
          _user = _user!.copyWith(fullName: newName, phone: newPhone);
          await prefs.setString('user_profile', jsonEncode(_user!.toJson()));
          notifyListeners();
        }
      }
      // Khi chua co token: de _user = null (khach), khong bia user demo
    } catch (_) {}
  }

  Future<bool> updateProfile({
    required String fullName,
    required String phone,
    String? avatarUrl,
  }) async {
    if (_user == null) {
      _profileUpdateError = 'Vui lòng đăng nhập để cập nhật hồ sơ';
      return false;
    }
    _isLoading = true;
    _profileUpdateError = null;
    notifyListeners();

    try {
      final updatedUser = _user!.copyWith(
        fullName: fullName.trim(),
        phone: phone.trim(),
        avatarUrl: avatarUrl?.trim(),
        clearAvatar: avatarUrl != null && avatarUrl.trim().isEmpty,
      );

      final profileData = <String, String>{
        'full_name': updatedUser.fullName,
        'phone': updatedUser.phone ?? '',
      };
      if (avatarUrl != null) {
        profileData['avatar_url'] = avatarUrl.trim();
      }
      await _api.dio.put('/profile', data: profileData);

      _user = updatedUser;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_profile', jsonEncode(_user!.toJson()));
      _isLoading = false;
      notifyListeners();
      return true;
    } on DioException catch (error) {
      final response = error.response?.data;
      _profileUpdateError = response is Map && response['error'] is String
          ? response['error'] as String
          : 'Không thể cập nhật hồ sơ. Vui lòng kiểm tra kết nối và thử lại.';
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (error) {
      _profileUpdateError = 'Không thể lưu thông tin hồ sơ: $error';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await _clearSession(prefs);
  }

  /// Moi thu luu tren may gan voi MOT nguoi dung cu the.
  ///
  /// Truoc day dang xuat chi xoa ba khoa phien dang nhap, con gio hang, dia chi,
  /// don hang, lich su tim kiem thi de nguyen. Nguoi dang nhap sau tren cung mot
  /// may se thay du lieu cua nguoi truoc.
  static const List<String> perUserKeys = [
    'access_token',
    'refresh_token',
    'user_profile',
    'cached_cart_items',
    'cached_orders',
    'saved_addresses',
    'last_ship_name',
    'last_ship_phone',
    'last_ship_address',
    'saved_user_name',
    'saved_user_phone',
    'recently_viewed_ids',
    'search_history',
  ];

  /// Xoa sach dau vet phien dang nhap va bao giao dien ve trang thai khach.
  Future<void> _clearSession(SharedPreferences prefs) async {
    for (final key in perUserKeys) {
      await prefs.remove(key);
    }
    _user = null;
    notifyListeners();
  }

  /// Cap nhat thong tin nguoi dung ngay sau khi dang nhap thanh cong,
  /// luu ca vao bo nho va SharedPreferences de khong bi mat phien khi chuyen tab.
  Future<void> setUserFromLogin(UserModel user) async {
    // Don du lieu con sot cua nguoi dung truoc tren may nay. Can lam ca o day
    // chu khong chi luc dang xuat: neu ung dung bi tat dot ngot thi lan dang
    // nhap sau se khong co buoc dang xuat nao chay ca.
    await _clearPreviousUserStorage();
    _user = user;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_profile', jsonEncode(user.toJson()));
  }

  /// Xoa du lieu cua nguoi dung truoc nhung giu lai phien dang nhap vua tao.
  Future<void> _clearPreviousUserStorage() async {
    const sessionKeys = {'access_token', 'refresh_token', 'user_profile'};
    final prefs = await SharedPreferences.getInstance();
    for (final key in perUserKeys) {
      if (sessionKeys.contains(key)) continue;
      await prefs.remove(key);
    }
  }
}
