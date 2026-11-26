import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/utils/app_logger.dart';
import '../../data/models/review_model.dart';

/// Khu vuc ghi log cua danh gia.
const String _khuVuc = 'DanhGia';

/// Quan ly trang thai cho: review
class ReviewProvider extends ChangeNotifier {
  final ApiClient _api = ApiClient();

  final Map<String, List<ReviewModel>> _reviewsByProduct = {};
  final Map<String, ReviewModel> _reviewByOrderItem = {};

  final Set<String> _loadingProducts = <String>{};
  bool _isLoadingMine = false;

  bool isLoadingProductFor(String productId) =>
      _loadingProducts.contains(productId);
  bool get isLoadingMine => _isLoadingMine;

  List<ReviewModel> reviewsFor(String productId) =>
      _reviewsByProduct[productId] ?? const [];

  ReviewModel? reviewForOrderItem(String orderItemId) =>
      _reviewByOrderItem[orderItemId];

  bool hasReviewed(String orderItemId) =>
      _reviewByOrderItem.containsKey(orderItemId);

  Future<void> loadProductReviews(String productId) async {
    if (_loadingProducts.contains(productId)) return;
    _loadingProducts.add(productId);
    notifyListeners();

    try {
      final res = await _api.dio.get('/reviews/product/$productId');
      final raw = res.data['data'] ?? res.data;
      if (raw is List) {
        _reviewsByProduct[productId] = raw
            .map(
                (item) => ReviewModel.fromJson(Map<String, dynamic>.from(item)))
            .toList();
      }
    } catch (e) {
      // Giu du lieu hien co neu khong tai duoc danh gia
      AppLogger.canhBao(
        'Không tải được đánh giá của sản phẩm $productId',
        khuVuc: _khuVuc,
        loi: e,
      );
    } finally {
      _loadingProducts.remove(productId);
      notifyListeners();
    }
  }

  /// Hoi may chu xem nguoi dang dang nhap co duoc danh gia san pham nay khong.
  ///
  /// Dieu kien la da nhan duoc hang. Tra ve false khi chua dang nhap hoac goi
  /// that bai, de giao dien chon huong an toan la khong hien nut.
  Future<bool> checkCanReview(String productId) async {
    try {
      final res = await _api.dio.get('/reviews/can-review/$productId');
      final data = res.data is Map ? res.data['data'] : null;
      return data is Map && data['canReview'] == true;
    } catch (e) {
      // Tra ve false la an nut danh gia di. Loi mang va "khong duoc phep danh
      // gia" nhin tu ben ngoai giong het nhau, nen phai ghi lai de phan biet.
      AppLogger.canhBao(
        'Không kiểm tra được quyền đánh giá sản phẩm $productId, tạm coi là không được',
        khuVuc: _khuVuc,
        loi: e,
      );
      return false;
    }
  }

  Future<void> loadMine() async {
    _isLoadingMine = true;
    notifyListeners();

    try {
      final res = await _api.dio.get('/reviews/mine');
      final raw = res.data['data'] ?? res.data;
      if (raw is List) {
        _reviewByOrderItem.clear();
        for (final item in raw) {
          final review = ReviewModel.fromJson(Map<String, dynamic>.from(item));
          if (review.orderItemId.isNotEmpty) {
            _reviewByOrderItem[review.orderItemId] = review;
          }
        }
      }
    } catch (e) {
      // Bo qua loi mang, man hinh van cho phep thu lai
      AppLogger.canhBao(
        'Không tải được đánh giá của tôi',
        khuVuc: _khuVuc,
        loi: e,
      );
    } finally {
      _isLoadingMine = false;
      notifyListeners();
    }
  }

  Future<ReviewModel> submitReview({
    String? orderItemId,
    String? productId,
    required int rating,
    String? comment,
    List<XFile> images = const [],
  }) async {
    final form = FormData();
    if (orderItemId != null && orderItemId.isNotEmpty) {
      form.fields.add(MapEntry('orderItemId', orderItemId));
    }
    if (productId != null && productId.isNotEmpty) {
      form.fields.add(MapEntry('productId', productId));
    }
    form.fields.add(MapEntry('rating', rating.toString()));
    if (comment != null && comment.trim().isNotEmpty) {
      form.fields.add(MapEntry('comment', comment.trim()));
    }

    for (final image in images.take(5)) {
      final bytes = await image.readAsBytes();
      form.files.add(
        MapEntry(
            'images', MultipartFile.fromBytes(bytes, filename: image.name)),
      );
    }

    try {
      final res = await _api.dio.post(
        '/reviews',
        data: form,
        options: Options(contentType: 'multipart/form-data'),
      );
      final data = res.data['data'] ?? res.data;
      final review = ReviewModel.fromJson(Map<String, dynamic>.from(data));

      if (review.orderItemId.isNotEmpty) {
        _reviewByOrderItem[review.orderItemId] = review;
      }
      final productReviews =
          _reviewsByProduct[review.productId] ?? const <ReviewModel>[];
      _reviewsByProduct[review.productId] = [review, ...productReviews];
      notifyListeners();

      return review;
    } on DioException catch (e) {
      final data = e.response?.data;
      if (data is Map && data['error'] != null) {
        throw Exception(data['error'].toString());
      }
      throw Exception('Không thể gửi đánh giá. Vui lòng thử lại.');
    }
  }
}
