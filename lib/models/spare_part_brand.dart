class SparePartBrand {
  final int id;
  final String name;
  final String slug;

  final String? logo;

  SparePartBrand({
    required this.id,
    required this.name,
    required this.slug,
    this.logo,
  });

  factory SparePartBrand.fromJson(Map<String, dynamic> json) {
    String? extractUrl(dynamic v) {
      if (v == null) return null;
      if (v is Map) return (v['original'] ?? v['thumbnail'])?.toString();
      return v.toString();
    }

    return SparePartBrand(
      id: (json['id'] as num).toInt(),
      name: json['name'] as String? ?? '',
      slug: json['slug'] as String? ?? '',
      logo: extractUrl(json['logo'] ?? json['cloudinary_url']),
    );
  }
}