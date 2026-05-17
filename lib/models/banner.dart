class BannerItem {
  final int id;
  final String title;
  final String imageUrl;
  final String? linkUrl;
  final bool isActive;
  final int displayOrder;

  BannerItem({
    required this.id,
    required this.title,
    required this.imageUrl,
    this.linkUrl,
    required this.isActive,
    required this.displayOrder,
  });

  factory BannerItem.fromJson(Map<String, dynamic> json) {
    return BannerItem(
      id: json['id'] as int,
      title: json['title'] as String,
      // The backend returns absolute URL in final_image_url
      imageUrl: (json['final_image_url'] ?? json['image_url'] ?? json['image']) as String,
      linkUrl: json['link_url'] as String?,
      isActive: json['is_active'] as bool? ?? true,
      displayOrder: json['display_order'] as int? ?? 0,
    );
  }
}
