class CartItem {
  final int id;
  final int productId;
  final String name;
  final String brandName;
  final int price;
  final int quantity;
  final String? imageUrl;

  CartItem({
    required this.id,
    required this.productId,
    required this.name,
    required this.brandName,
    required this.price,
    required this.quantity,
    this.imageUrl,
  });

  factory CartItem.fromJson(Map<String, dynamic> json) {
    final idVal = (json['item_id'] as num?)?.toInt() ?? (json['id'] as num?)?.toInt() ?? 0;
    final prodVal = (json['product_id'] as num?)?.toInt() ?? (json['spare_part'] as num?)?.toInt() ?? (json['spare_part_id'] as num?)?.toInt() ?? 0;
    int toInt(dynamic v) {
      if (v is num) return v.toInt();
      if (v is String) {
        final d = double.tryParse(v);
        if (d != null) return d.round();
      }
      return 0;
    }
    String? extractUrl(dynamic media) {
      if (media == null) return null;
      if (media is String) return media;
      if (media is Map) return (media['thumbnail'] ?? media['original'] ?? media['url']) as String?;
      return null;
    }
    final priceVal = toInt(json['unit_price'] ?? json['price']);
    return CartItem(
      id: idVal,
      productId: prodVal,
      name: json['part_name'] as String? ?? (json['name'] as String? ?? ''),
      brandName: json['brand_name'] as String? ?? (json['brand'] as String? ?? ''),
      price: priceVal,
      quantity: (json['qty'] as num?)?.toInt() ?? (json['quantity'] as num?)?.toInt() ?? 1,
      imageUrl: extractUrl(json['image'] ?? json['image_url']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'item_id': id,
      'product_id': productId,
      'name': name,
      'brand_name': brandName,
      'unit_price': price,
      'qty': quantity,
      'image_url': imageUrl,
    };
  }
}
