class SparePartCategory {
  final int id;
  final String name;
  final String slug;
  final int? partsCount;

  SparePartCategory({
    required this.id,
    required this.name,
    required this.slug,
    this.partsCount,
  });

  factory SparePartCategory.fromJson(Map<String, dynamic> json) {
    return SparePartCategory(
      id: (json['id'] as num).toInt(),
      name: json['name'] as String? ?? '',
      slug: json['slug'] as String? ?? '',
      partsCount: (json['parts_count'] as num?)?.toInt(),
    );
  }
}