class QuickServiceConfig {
  final int id;
  final String title;
  final String rulesHtml;
  final double basePrice;
  final String supportPhone;

  QuickServiceConfig({
    required this.id,
    required this.title,
    required this.rulesHtml,
    required this.basePrice,
    required this.supportPhone,
  });

  factory QuickServiceConfig.fromJson(Map<String, dynamic> json) {
    return QuickServiceConfig(
      id: json['id'],
      title: json['title'],
      rulesHtml: json['rules_html'],
      basePrice: double.tryParse(json['base_price'].toString()) ?? 0.0,
      supportPhone: json['support_phone']?.toString() ?? '',
    );
  }
}

class QuickServiceRequest {
  final int id;
  final String phoneNumber;
  final String status;
  final String? staffNotes;
  final String? servicesGrabbed;
  final double totalAmount;
  final DateTime createdAt;
  final DateTime updatedAt;

  QuickServiceRequest({
    required this.id,
    required this.phoneNumber,
    required this.status,
    this.staffNotes,
    this.servicesGrabbed,
    required this.totalAmount,
    required this.createdAt,
    required this.updatedAt,
  });

  factory QuickServiceRequest.fromJson(Map<String, dynamic> json) {
    return QuickServiceRequest(
      id: json['id'],
      phoneNumber: json['phone_number'],
      status: json['status'],
      staffNotes: json['staff_notes'],
      servicesGrabbed: json['services_grabbed'],
      totalAmount: double.tryParse(json['total_amount'].toString()) ?? 0.0,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }
}
