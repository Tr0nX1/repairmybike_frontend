class CartItem {
  final int itemId;
  final int productId;
  final String name;
  final String brandName;
  final int unitPrice; // in minor units (e.g., INR paise) if backend uses ints
  final int quantity;
  final String? imageUrl;

  CartItem({
    required this.itemId,
    required this.productId,
    required this.name,
    required this.brandName,
    required this.unitPrice,
    required this.quantity,
    this.imageUrl,
  });

  factory CartItem.fromJson(Map<String, dynamic> json) {
    return CartItem(
      itemId: (json['item_id'] ?? json['id'] as num).toInt(),
      productId: (json['product_id'] ?? json['spare_part_id'] as num).toInt(),
      name: json['name'] as String? ?? '',
      brandName: json['brand_name'] as String? ?? (json['brand'] as String? ?? ''),
      unitPrice: (json['unit_price'] ?? json['price'] as num?)?.toInt() ?? 0,
      quantity: (json['qty'] ?? json['quantity'] as num?)?.toInt() ?? 1,
      imageUrl: json['image_url'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'item_id': itemId,
      'product_id': productId,
      'name': name,
      'brand_name': brandName,
      'unit_price': unitPrice,
      'qty': quantity,
      'image_url': imageUrl,
    };
  }
}