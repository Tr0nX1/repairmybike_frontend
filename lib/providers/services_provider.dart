import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/category_api.dart';
import '../models/category.dart';
import '../data/service_api.dart';
import '../models/service.dart';

final categoryApiProvider = Provider<CategoryApi>((ref) => CategoryApi());

final serviceCategoriesProvider = FutureProvider<List<Category>>((ref) async {
  final api = ref.read(categoryApiProvider);
  ref.keepAlive();
  return api.getCategories();
});

final serviceApiProvider = Provider<ServiceApi>((ref) => ServiceApi());

final servicesByCategoryProvider =
    FutureProvider.family<List<Service>, int>((ref, categoryId) async {
  final api = ref.read(serviceApiProvider);
  ref.keepAlive();
  return api.getServices(categoryId: categoryId);
});

final allServicesProvider = FutureProvider<List<Service>>((ref) async {
  final api = ref.read(serviceApiProvider);
  ref.keepAlive();
  return api.getServices();
});
