class SparePartBrand {
  final int id;
  final String name;
  final String slug;

  SparePartBrand({
    required this.id,
    required this.name,
    required this.slug,
  });

  factory SparePartBrand.fromJson(Map<String, dynamic> json) {
    return SparePartBrand(
      id: (json['id'] as num).toInt(),
      name: json['name'] as String? ?? '',
      slug: json['slug'] as String? ?? '',
    );
  }
}