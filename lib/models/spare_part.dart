class SparePartListItem {
  final int id;
  final String name;
  final String slug;
  final String sku;
  final int brandId;
  final String brandName;
  final int categoryId;
  final String categoryName;
  final String shortDescription;
  final num mrp;
  final num salePrice;
  final String currency;
  final bool inStock;
  final int stockQty;
  final int warrantyMonthsTotal;
  final int warrantyFreeMonths;
  final int warrantyProRataMonths;
  final num ratingAverage;
  final int ratingCount;
  final String? thumbnail;
  final List<String> images;
  final String? description;
  final Map<String, dynamic> specs;
  final Map<String, dynamic> dimensions;
  final String? brandLogoUrl;

  SparePartListItem({
    required this.id,
    required this.name,
    required this.slug,
    required this.sku,
    required this.brandId,
    required this.brandName,
    required this.categoryId,
    required this.categoryName,
    required this.shortDescription,
    required this.mrp,
    required this.salePrice,
    required this.currency,
    required this.inStock,
    required this.stockQty,
    required this.warrantyMonthsTotal,
    required this.warrantyFreeMonths,
    required this.warrantyProRataMonths,
    required this.ratingAverage,
    required this.ratingCount,
    this.thumbnail,
    this.images = const [],
    this.description,
    this.specs = const {},
    this.dimensions = const {},
    this.brandLogoUrl,
  });

  factory SparePartListItem.fromJson(Map<String, dynamic> json) {
    String? extractUrl(dynamic v) {
      if (v == null) return null;
      if (v is Map) return (v['original'] ?? v['thumbnail'])?.toString();
      return v.toString();
    }
    List<String> normalizeImages(dynamic v) {
      final list = (v as List?) ?? const [];
      return list.map((e) {
        if (e is Map) {
          return (e['original'] ?? e['thumbnail'] ?? e['image'] ?? e['url'] ?? '').toString();
        }
        return e?.toString() ?? '';
      }).where((s) => s.isNotEmpty).toList();
    }
    Map<String, dynamic> normalizeMap(dynamic v) {
      return (v as Map<String, dynamic>?) ?? <String, dynamic>{};
    }
    return SparePartListItem(
      id: (json['id'] as num).toInt(),
      name: json['name'] as String? ?? '',
      slug: json['slug'] as String? ?? '',
      sku: json['sku'] as String? ?? '',
      brandId: (json['brand'] as num).toInt(),
      brandName: json['brand_name'] as String? ?? '',
      categoryId: (json['category'] as num).toInt(),
      categoryName: json['category_name'] as String? ?? '',
      shortDescription: json['short_description'] as String? ?? '',
      mrp: (json['mrp'] is num) ? json['mrp'] as num : num.tryParse(json['mrp']?.toString() ?? '0') ?? 0,
      salePrice: (json['sale_price'] is num) ? json['sale_price'] as num : num.tryParse(json['sale_price']?.toString() ?? '0') ?? 0,
      currency: json['currency'] as String? ?? 'INR',
      inStock: (json['in_stock'] as bool?) ?? true,
      stockQty: (json['stock_qty'] as num?)?.toInt() ?? 0,
      warrantyMonthsTotal: (json['warranty_months_total'] as num?)?.toInt() ?? 0,
      warrantyFreeMonths: (json['warranty_free_months'] as num?)?.toInt() ?? 0,
      warrantyProRataMonths: (json['warranty_pro_rata_months'] as num?)?.toInt() ?? 0,
      ratingAverage: (json['rating_average'] is num)
          ? json['rating_average'] as num
          : num.tryParse(json['rating_average']?.toString() ?? '0') ?? 0,
      ratingCount: (json['rating_count'] as num?)?.toInt() ?? 0,
      thumbnail: extractUrl(json['thumbnail'] ?? json['cloudinary_url']),
      images: normalizeImages(json['images'] ?? json['gallery'] ?? json['image_urls']),
      description: json['description'] as String?,
      specs: normalizeMap(json['specs'] ?? json['specifications'] ?? json['attributes']),
      dimensions: normalizeMap(json['dimensions']),
      brandLogoUrl: extractUrl(json['brand_logo'] ?? json['brand_logo_url'] ?? json['brand_cloudinary_url']),
    );
  }
}