import 'dart:convert';

class ReviewModel {
  final String id;
  final String userId;
  final String userName;
  final String? userAvatar;
  final String productId;
  final String orderItemId;
  final int rating;
  final String comment;
  final List<String> images;
  final String? replyComment;
  final DateTime? replyAt;
  final DateTime createdAt;

  const ReviewModel({
    required this.id,
    required this.userId,
    required this.userName,
    this.userAvatar,
    required this.productId,
    required this.orderItemId,
    required this.rating,
    required this.comment,
    this.images = const [],
    this.replyComment,
    this.replyAt,
    required this.createdAt,
  });

  factory ReviewModel.fromJson(Map<String, dynamic> json) {
    return ReviewModel(
      id: json['id']?.toString() ?? '',
      userId: json['user_id']?.toString() ?? '',
      userName: (json['user_name'] ?? json['full_name'] ?? 'Khách hàng Menly')
          .toString(),
      userAvatar: json['user_avatar']?.toString(),
      productId: json['product_id']?.toString() ?? '',
      orderItemId: json['order_item_id']?.toString() ?? '',
      rating: (json['rating'] is num) ? (json['rating'] as num).toInt() : 5,
      comment: json['comment']?.toString() ?? '',
      images: _parseImages(json['images']),
      replyComment: json['reply_comment']?.toString(),
      replyAt: json['reply_at'] != null
          ? DateTime.tryParse(json['reply_at'].toString())
          : null,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  static List<String> _parseImages(dynamic raw) {
    if (raw is List) {
      return raw
          .map((item) => item.toString())
          .where((url) => url.isNotEmpty)
          .toList();
    }
    if (raw is String && raw.trim().isNotEmpty) {
      try {
        final decoded = jsonDecode(raw);
        if (decoded is List) {
          return decoded
              .map((item) => item.toString())
              .where((url) => url.isNotEmpty)
              .toList();
        }
      } catch (_) {}
    }
    return const [];
  }
}
