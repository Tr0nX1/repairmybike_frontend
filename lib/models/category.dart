class Category {
  final int id;
  final String name;
  final String description;
  final String icon; // emoji string
  final String? image;
  final int serviceCount;
  final DateTime createdAt;
  final DateTime updatedAt;

  Category({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    this.image,
    required this.serviceCount,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Category.fromJson(Map<String, dynamic> json) {
    String? extractUrl(dynamic val) {
      if (val == null) return null;
      if (val is String) return val;
      if (val is Map) return val['thumbnail'] as String? ?? val['original'] as String?;
      return null;
    }

    return Category(
      id: (json['id'] as num).toInt(),
      name: json['name'] as String,
      description: json['description'] as String? ?? '',
      icon: json['icon'] as String? ?? '🔧',
      image: extractUrl(json['image']),
      serviceCount: (json['service_count'] as num?)?.toInt() ?? 0,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }
}