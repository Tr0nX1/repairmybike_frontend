
class OrderItem {
  final int productId;
  final String name;
  final String sku;
  final int unitPrice;
  final int quantity;
  final int lineTotal;

  OrderItem({
    required this.productId,
    required this.name,
    required this.sku,
    required this.unitPrice,
    required this.quantity,
    required this.lineTotal,
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    int toInt(dynamic v) {
      if (v is num) return v.toInt();
      if (v is String) {
        final d = double.tryParse(v);
        if (d != null) return d.round();
      }
      return 0;
    }
    return OrderItem(
      productId: (json['spare_part'] as num?)?.toInt() ?? (json['spare_part_id'] as num?)?.toInt() ?? (json['product_id'] as num?)?.toInt() ?? 0,
      name: json['part_name'] as String? ?? (json['name'] as String? ?? ''),
      sku: json['sku'] as String? ?? '',
      unitPrice: toInt(json['unit_price'] ?? json['price']),
      quantity: (json['quantity'] as num?)?.toInt() ?? (json['qty'] as num?)?.toInt() ?? 1,
      lineTotal: toInt(json['total_price'] ?? json['line_total']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'spare_part_id': productId,
      'name': name,
      'unit_price': unitPrice,
      'quantity': quantity,
      'line_total': lineTotal,
    };
  }
}

class Order {
  final int id;
  final String sessionId;
  final String status;
  final String paymentMethod;
  final String paymentStatus;
  final String currency;
  final int total;
  final String customerName;
  final String phone;
  final String address;
  
  // Tracking fields
  final String? trackingNumber;
  final String? courierName;
  final DateTime? estimatedDelivery;
  final DateTime? deliveredAt;

  final List<OrderItem> items;

  Order({
    required this.id,
    required this.sessionId,
    required this.status,
    required this.paymentMethod,
    required this.paymentStatus,
    required this.currency,
    required this.total,
    required this.customerName,
    required this.phone,
    required this.address,
    this.trackingNumber,
    this.courierName,
    this.estimatedDelivery,
    this.deliveredAt,
    required this.items,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    final map = json.containsKey('data') && json['data'] is Map<String, dynamic>
        ? json['data'] as Map<String, dynamic>
        : json;
    final itemsList = (map['items'] ?? []) as List?;
    int toInt(dynamic v) {
      if (v is num) return v.toInt();
      if (v is String) {
        final d = double.tryParse(v);
        if (d != null) return d.round();
      }
      return 0;
    }
    return Order(
      id: (map['id'] as num).toInt(),
      sessionId: map['session_id'] as String? ?? '',
      status: map['status'] as String? ?? 'created',
      paymentMethod: map['payment_method'] as String? ?? 'cash',
      paymentStatus: map['payment_status'] as String? ?? 'cash_due',
      currency: map['currency'] as String? ?? 'INR',
      total: toInt(map['amount_total'] ?? map['total']),
      customerName: map['customer_name'] as String? ?? '',
      phone: map['phone'] as String? ?? '',
      address: map['address'] as String? ?? '',
      
      trackingNumber: map['tracking_number'] as String?,
      courierName: map['courier_name'] as String?,
      estimatedDelivery: map['estimated_delivery'] != null 
          ? DateTime.tryParse(map['estimated_delivery']) 
          : null,
      deliveredAt: map['delivered_at'] != null 
          ? DateTime.tryParse(map['delivered_at']) 
          : null,

      items: (itemsList ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(OrderItem.fromJson)
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'session_id': sessionId,
      'status': status,
      'payment_method': paymentMethod,
      'payment_status': paymentStatus,
      'currency': currency,
      'amount_total': total,
      'customer_name': customerName,
      'phone': phone,
      'address': address,
      'items': items.map((e) => e.toJson()).toList(),
    };
  }
}
