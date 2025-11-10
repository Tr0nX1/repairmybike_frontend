import 'cart_item.dart';

class OrderItem {
  final int productId;
  final String name;
  final int unitPrice;
  final int quantity;
  final int lineTotal;

  OrderItem({
    required this.productId,
    required this.name,
    required this.unitPrice,
    required this.quantity,
    required this.lineTotal,
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      productId: (json['product_id'] ?? json['spare_part_id'] as num).toInt(),
      name: json['name'] as String? ?? '',
      unitPrice: (json['unit_price'] ?? json['price'] as num?)?.toInt() ?? 0,
      quantity: (json['qty'] ?? json['quantity'] as num?)?.toInt() ?? 1,
      lineTotal: (json['line_total'] as num?)?.toInt() ??
          (((json['unit_price'] ?? json['price'] as num?)?.toInt() ?? 0) * ((json['qty'] ?? json['quantity'] as num?)?.toInt() ?? 1)),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'product_id': productId,
      'name': name,
      'unit_price': unitPrice,
      'qty': quantity,
      'line_total': lineTotal,
    };
  }
}

class Order {
  final int id;
  final String orderCode;
  final String status; // pending_cash, confirmed, fulfilled, cancelled
  final String paymentMethod; // "cash"
  final int subtotal;
  final int tax;
  final int shippingFee;
  final int total;
  final String? shippingAddress;
  final String? phone;
  final List<OrderItem> items;

  Order({
    required this.id,
    required this.orderCode,
    required this.status,
    required this.paymentMethod,
    required this.subtotal,
    required this.tax,
    required this.shippingFee,
    required this.total,
    this.shippingAddress,
    this.phone,
    required this.items,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    final map = json.containsKey('data') && json['data'] is Map<String, dynamic>
        ? json['data'] as Map<String, dynamic>
        : json;
    final itemsList = (map['items'] ?? []) as List?;
    return Order(
      id: (map['id'] as num).toInt(),
      orderCode: map['order_code'] as String? ?? (map['code'] as String? ?? ''),
      status: map['status'] as String? ?? 'pending_cash',
      paymentMethod: map['payment_method'] as String? ?? 'cash',
      subtotal: (map['subtotal'] as num?)?.toInt() ?? 0,
      tax: (map['tax'] as num?)?.toInt() ?? 0,
      shippingFee: (map['shipping_fee'] as num?)?.toInt() ?? 0,
      total: (map['total'] as num?)?.toInt() ?? 0,
      shippingAddress: map['shipping_address'] as String?,
      phone: map['phone'] as String?,
      items: (itemsList ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(OrderItem.fromJson)
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'order_code': orderCode,
      'status': status,
      'payment_method': paymentMethod,
      'subtotal': subtotal,
      'tax': tax,
      'shipping_fee': shippingFee,
      'total': total,
      'shipping_address': shippingAddress,
      'phone': phone,
      'items': items.map((e) => e.toJson()).toList(),
    };
  }
}