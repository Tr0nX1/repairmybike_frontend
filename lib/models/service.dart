class Service {
  final int id;
  final int serviceCategory; // category id
  final String categoryName;
  final String name;
  final String description;
  final String rating; // string per backend
  final int reviewsCount;
  final List<String> specifications; // normalized to strings
  final List<String> images; // normalized to strings
  final int price;
  final bool isFeatured;
  final DateTime createdAt;
  final DateTime updatedAt;

  Service({
    required this.id,
    required this.serviceCategory,
    required this.categoryName,
    required this.name,
    required this.description,
    required this.rating,
    required this.reviewsCount,
    required this.specifications,
    required this.images,
    required this.price,
    required this.isFeatured,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Service.fromJson(Map<String, dynamic> json) {
    return Service(
      id: (json['id'] as num).toInt(),
      serviceCategory: (json['service_category'] as num).toInt(),
      categoryName: json['category_name'] as String? ?? '',
      name: json['name'] as String,
      description: json['description'] as String? ?? '',
      rating: json['rating']?.toString() ?? '0.00',
      reviewsCount: (json['reviews_count'] as num?)?.toInt() ?? 0,
      specifications: ((json['specifications'] as List?) ?? const [])
          .map((e) => e?.toString() ?? '')
          .where((s) => s.isNotEmpty)
          .toList(),
      images: ((json['images'] as List?) ?? const [])
          .map((e) {
            if (e is Map) return (e['original'] ?? e['thumbnail'] ?? '').toString();
            return e?.toString() ?? '';
          })
          .where((s) => s.isNotEmpty)
          .toList(),
      price: (json['price'] as num?)?.toInt() ?? 0,
      isFeatured: json['is_featured'] == true,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }
}