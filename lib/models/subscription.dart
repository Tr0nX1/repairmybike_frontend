class Benefit {
  final int id;
  final String text;
  final bool isActive;

  Benefit({
    required this.id,
    required this.text,
    required this.isActive,
  });

  factory Benefit.fromJson(Map<String, dynamic> json) {
    return Benefit(
      id: (json['id'] as num).toInt(),
      text: json['text'] as String? ?? '',
      isActive: (json['is_active'] as bool?) ?? true,
    );
  }
}

class IncludedServiceDetail {
  final int id;
  final String name;
  final String? category;

  IncludedServiceDetail({
    required this.id,
    required this.name,
    this.category,
  });

  factory IncludedServiceDetail.fromJson(Map<String, dynamic> json) {
    return IncludedServiceDetail(
      id: (json['id'] as num).toInt(),
      name: json['name'] as String? ?? '',
      category: json['category'] as String?,
    );
  }
}

class SubscriptionPlan {
  final int id;
  final String name;
  final String slug;
  final String description;
  final String? imageUrl;
  final Map<String, dynamic> benefits; // Legacy JSON
  final List<Benefit> benefitsList; // New structured benefits
  final List<String> services; // Legacy JSON
  final List<IncludedServiceDetail> includedServicesDetails; // New structured services
  final num? originalPrice;
  final num price;
  final String currency;
  final String billingPeriod;
  final int includedVisits;
  final bool active;
  final String? tier; // 'basic' or 'premium' when applicable
  final String? razorpayPlanId;
  final String? createdAt;
  final String? updatedAt;

  SubscriptionPlan({
    required this.id,
    required this.name,
    required this.slug,
    required this.description,
    this.imageUrl,
    required this.benefits,
    required this.benefitsList,
    required this.services,
    required this.includedServicesDetails,
    this.originalPrice,
    required this.price,
    required this.currency,
    required this.billingPeriod,
    required this.includedVisits,
    required this.active,
    this.tier,
    this.razorpayPlanId,
    this.createdAt,
    this.updatedAt,
  });

  factory SubscriptionPlan.fromJson(Map<String, dynamic> json) {
    return SubscriptionPlan(
      id: (json['id'] as num).toInt(),
      name: json['name'] as String? ?? '',
      slug: json['slug'] as String? ?? '',
      description: json['description'] as String? ?? '',
      imageUrl: json['image'] as String?,
      benefits: (json['benefits'] as Map<String, dynamic>?) ?? <String, dynamic>{},
      benefitsList: ((json['benefits_list'] as List?) ?? const [])
          .map((e) => Benefit.fromJson(e as Map<String, dynamic>))
          .toList(),
      services: ((json['services'] as List?) ?? const [])
          .map((e) => e?.toString() ?? '')
          .where((s) => s.isNotEmpty)
          .toList(),
      includedServicesDetails: ((json['included_services_details'] as List?) ?? const [])
          .map((e) => IncludedServiceDetail.fromJson(e as Map<String, dynamic>))
          .toList(),
      originalPrice: (json['original_price'] is num)
          ? json['original_price'] as num
          : num.tryParse(json['original_price']?.toString() ?? ''),
      price: (json['price'] is num)
          ? json['price'] as num
          : num.tryParse(json['price']?.toString() ?? '0') ?? 0,
      currency: json['currency'] as String? ?? 'INR',
      billingPeriod: json['billing_period'] as String? ?? 'monthly',
      includedVisits: (json['included_visits'] as num?)?.toInt() ?? 0,
      active: (json['active'] as bool?) ?? true,
      tier: json['tier'] as String?,
      razorpayPlanId: json['razorpay_plan_id'] as String?,
      createdAt: json['created_at']?.toString(),
      updatedAt: json['updated_at']?.toString(),
    );
  }
}

class SubscriptionItem {
  final int id;
  final int planId;
  final String? planName;
  final int? userId;
  final String? contactEmail;
  final String? contactPhone;
  final String status;
  final bool isActive;
  final bool autoRenew;
  final String startDate;
  final String? endDate;
  final String? nextBillingDate;
  final String? razorpaySubscriptionId;
  final int visitsConsumed;
  final int remainingVisits;
  final Map<String, dynamic> metadata;

  SubscriptionItem({
    required this.id,
    required this.planId,
    this.planName,
    this.userId,
    this.contactEmail,
    this.contactPhone,
    required this.status,
    required this.isActive,
    required this.autoRenew,
    required this.startDate,
    this.endDate,
    this.nextBillingDate,
    this.razorpaySubscriptionId,
    required this.visitsConsumed,
    required this.remainingVisits,
    required this.metadata,
  });

  factory SubscriptionItem.fromJson(Map<String, dynamic> json) {
    // Derive isActive if backend field not present
    bool deriveActive() {
      final status = json['status'] as String? ?? 'pending';
      final end = json['end_date']?.toString();
      if (status == 'expired') return false;
      if (end == null || end.isEmpty) return true;
      // Simple string compare won't work; assume presence implies active unless expired
      return status != 'expired';
    }
    return SubscriptionItem(
      id: (json['id'] as num).toInt(),
      planId: (json['plan'] as num).toInt(),
      planName: json['plan_name'] as String?,
      userId: (json['user'] as num?)?.toInt(),
      contactEmail: json['contact_email'] as String?,
      contactPhone: json['contact_phone'] as String?,
      status: json['status'] as String? ?? 'pending',
      isActive: (json['is_active'] as bool?) ?? deriveActive(),
      autoRenew: (json['auto_renew'] as bool?) ?? true,
      startDate: json['start_date']?.toString() ?? '',
      endDate: json['end_date']?.toString(),
      nextBillingDate: json['next_billing_date']?.toString(),
      razorpaySubscriptionId: json['razorpay_subscription_id'] as String?,
      visitsConsumed: (json['visits_consumed'] as num?)?.toInt() ?? 0,
      remainingVisits: (json['remaining_visits'] as num?)?.toInt() ?? 0,
      metadata: (json['metadata'] as Map<String, dynamic>?) ?? <String, dynamic>{},
    );
  }
}