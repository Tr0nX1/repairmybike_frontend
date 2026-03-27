import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/service.dart';
import '../models/spare_part.dart';
import '../models/subscription.dart';
import '../data/service_api.dart';
import '../data/spare_parts_api.dart';
import '../data/subscription_api.dart';

class LandingData {
  final List<Service> services;
  final List<SparePartListItem> spareParts;
  final List<SubscriptionPlan> plans;

  LandingData({
    required this.services,
    required this.spareParts,
    required this.plans,
  });
}

final landingDataProvider = FutureProvider<LandingData>((ref) async {
  final serviceApi = ServiceApi();
  final sparePartsApi = SparePartsApi();
  final subscriptionApi = SubscriptionApi();

  // Fetch all concurrently
  final results = await Future.wait([
    serviceApi.getServices(),
    sparePartsApi.getParts(),
    subscriptionApi.getPlans(),
  ]);

  final allServices = results[0] as List<Service>;
  final allParts = results[1] as List<SparePartListItem>;
  final allPlans = results[2] as List<SubscriptionPlan>;

  return LandingData(
    // Take top 4 featured services, or just top 4
    services: allServices.where((s) => s.isFeatured).take(4).toList().isNotEmpty 
        ? allServices.where((s) => s.isFeatured).take(4).toList() 
        : allServices.take(4).toList(),
    // Take top 4 parts
    spareParts: allParts.take(4).toList(),
    // Take all active plans
    plans: allPlans.where((p) => p.active).toList(),
  );
});
