class SparePartCategory {
  final int id;
  final String name;
  final String slug;
  final String? image;
  final int? partsCount;

  SparePartCategory({
    required this.id,
    required this.name,
    required this.slug,
    this.image,
    this.partsCount,
  });

  factory SparePartCategory.fromJson(Map<String, dynamic> json) {
    String? extractUrl(dynamic v) {
      if (v == null) return null;
      if (v is Map) return (v['original'] ?? v['thumbnail'])?.toString();
      return v.toString();
    }
    return SparePartCategory(
      id: (json['id'] as num).toInt(),
      name: json['name'] as String? ?? '',
      slug: json['slug'] as String? ?? '',
      image: extractUrl(json['image'] ?? json['cloudinary_url']),
      partsCount: (json['parts_count'] as num?)?.toInt(),
    );
  }
}
