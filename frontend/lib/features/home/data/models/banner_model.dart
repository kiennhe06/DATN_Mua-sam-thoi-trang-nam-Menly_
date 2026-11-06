/// Model cho Banner quang cao trang chu (AP-BN1)
class BannerModel {
  final String id;
  final String title;
  final String imageUrl;
  final String? linkUrl;
  final int sortOrder;
  final bool isActive;

  const BannerModel({
    required this.id,
    required this.title,
    required this.imageUrl,
    this.linkUrl,
    this.sortOrder = 0,
    this.isActive = true,
  });

  factory BannerModel.fromJson(Map<String, dynamic> json) {
    return BannerModel(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      imageUrl: json['image_url']?.toString() ?? '',
      linkUrl: json['link_url']?.toString(),
      sortOrder: json['sort_order'] is int ? json['sort_order'] : 0,
      isActive: json['is_active'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'image_url': imageUrl,
      'link_url': linkUrl,
      'sort_order': sortOrder,
      'is_active': isActive,
    };
  }
}

