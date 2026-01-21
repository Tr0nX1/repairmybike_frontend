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
    return SparePartBrand(
      id: (json['id'] as num).toInt(),
      name: json['name'] as String? ?? '',
      slug: json['slug'] as String? ?? '',
      logo: json['cloudinary_url'] as String? ?? json['logo'] as String?,
    );
  }
}