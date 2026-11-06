/// Model danh muc san pham Menly tu backend
class CategoryModel {
  final String id;
  final String name;
  final String slug;
  final int sortOrder;

  const CategoryModel({
    required this.id,
    required this.name,
    required this.slug,
    this.sortOrder = 0,
  });

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      slug: json['slug']?.toString() ?? '',
      sortOrder: (json['sort_order'] is num) ? (json['sort_order'] as num).toInt() : 0,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'slug': slug,
    'sort_order': sortOrder,
  };
}

