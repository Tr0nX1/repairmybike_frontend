import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/subscription_api.dart';
import '../models/subscription.dart';

final subscriptionApiProvider = Provider<SubscriptionApi>((ref) => SubscriptionApi());

final subscriptionPlansProvider = FutureProvider<List<SubscriptionPlan>>((ref) async {
  final api = ref.read(subscriptionApiProvider);
  return api.getPlans();
});

final mySubscriptionsProvider = FutureProvider<List<SubscriptionItem>>((ref) async {
  final api = ref.read(subscriptionApiProvider);
  return api.getMySubscriptions();
});