import 'package:menly_app/features/product/data/models/product_model.dart';

class SuggestedProductItem {
  final String id;
  final String name;
  final int price;
  final String? thumbnailUrl;
  final String? slug;

  const SuggestedProductItem({
    required this.id,
    required this.name,
    required this.price,
    this.thumbnailUrl,
    this.slug,
  });

  factory SuggestedProductItem.fromJson(Map<String, dynamic> json) {
    return SuggestedProductItem(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      price: (json['price'] is num) ? (json['price'] as num).toInt() : 0,
      thumbnailUrl: json['thumbnailUrl']?.toString() ?? json['thumbnail_url']?.toString(),
      slug: json['slug']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'price': price,
        'thumbnail_url': thumbnailUrl,
        'slug': slug,
      };

  ProductModel toProductModel() {
    return ProductModel(
      id: id,
      name: name,
      slug: slug ?? 'san-pham',
      description: 'Sản phẩm cao cấp được tư vấn bởi Menly AI Stylist.',
      price: price,
      thumbnailUrl: thumbnailUrl ?? '',
      categoryId: '',
      categoryName: 'Menly Collection',
    );
  }
}

typedef AiSuggestedProduct = SuggestedProductItem;

class ChatMessageModel {
  final String id;
  final String senderType; // 'staff' | 'user'
  final String senderName;
  final String content;
  final DateTime createdAt;
  final bool isStaff;
  final List<SuggestedProductItem>? suggestedProducts;

  const ChatMessageModel({
    required this.id,
    required this.senderType,
    required this.senderName,
    required this.content,
    required this.createdAt,
    required this.isStaff,
    this.suggestedProducts,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'sender_type': senderType,
        'sender_name': senderName,
        'content': content,
        'created_at': createdAt.toIso8601String(),
        'is_staff': isStaff,
        if (suggestedProducts != null)
          'suggested_products':
              suggestedProducts!.map((p) => p.toJson()).toList(),
      };

  factory ChatMessageModel.fromJson(Map<String, dynamic> json) {
    return ChatMessageModel(
      id: json['id']?.toString() ?? '',
      senderType: json['sender_type']?.toString() ??
          (json['is_staff'] == true ? 'staff' : 'user'),
      senderName: json['sender_name']?.toString() ?? '',
      content: json['content']?.toString() ?? '',
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '') ??
          DateTime.now(),
      isStaff: json['is_staff'] == true || json['sender_type'] == 'staff',
      suggestedProducts: json['suggested_products'] is List
          ? (json['suggested_products'] as List)
              .map((p) => SuggestedProductItem.fromJson(
                  Map<String, dynamic>.from(p as Map)))
              .toList()
          : null,
    );
  }

  // Getters tương thích
  String get text => content;
  DateTime get timestamp => createdAt;
  bool get isUser => !isStaff;
}

typedef AiChatMessage = ChatMessageModel;

class AiChatResponse {
  final String reply;
  final List<SuggestedProductItem> suggestedProducts;

  const AiChatResponse({
    required this.reply,
    this.suggestedProducts = const [],
  });
}
