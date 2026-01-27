import 'cart_item.dart';

class Cart {
  final int? id;
  final int version;
  final List<CartItem> items;
  final int subtotal;
  final int tax;
  final int shippingFee;
  final int total;

  Cart({
    this.id,
    required this.version,
    required this.items,
    required this.subtotal,
    required this.tax,
    required this.shippingFee,
    required this.total,
  });

  factory Cart.empty() => Cart(
        id: null,
        version: 1,
        items: const [],
        subtotal: 0,
        tax: 0,
        shippingFee: 0,
        total: 0,
      );

  factory Cart.fromJson(Map<String, dynamic> json) {
    // Support wrapped payloads {data: {...}} or raw cart map
    final map = json.containsKey('data') && json['data'] is Map<String, dynamic>
        ? json['data'] as Map<String, dynamic>
        : json;
    final itemsList = (map['items'] ?? map['cart_items'] ?? []) as List?;
    final totalField = map['total'] ?? map['total_amount'];
    int toInt(dynamic v) {
      if (v is num) return v.toInt();
      if (v is String) {
        final d = double.tryParse(v);
        if (d != null) return d.round();
      }
      return 0;
    }
    return Cart(
      id: (map['id'] as num?)?.toInt(),
      version: (map['version'] as num?)?.toInt() ?? 1,
      items: (itemsList ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(CartItem.fromJson)
          .toList(),
      subtotal: toInt(totalField),
      tax: 0,
      shippingFee: 0,
      total: toInt(totalField),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'version': version,
      'items': items.map((e) => e.toJson()).toList(),
      'subtotal': subtotal,
      'tax': tax,
      'shipping_fee': shippingFee,
      'total': total,
    };
  }
}
