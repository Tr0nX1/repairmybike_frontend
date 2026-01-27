import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/category_api.dart';
import '../models/category.dart';
import '../data/service_api.dart';
import '../models/service.dart';

final categoryApiProvider = Provider<CategoryApi>((ref) => CategoryApi());

final categoriesProvider = FutureProvider<List<Category>>((ref) async {
  final api = ref.read(categoryApiProvider);
  return api.getCategories();
});

// Service providers
final serviceApiProvider = Provider<ServiceApi>((ref) => ServiceApi());

final servicesByCategoryProvider =
    FutureProvider.family<List<Service>, int>((ref, categoryId) async {
  final api = ref.read(serviceApiProvider);
  return api.getServices(categoryId: categoryId);
});

final allServicesProvider = FutureProvider<List<Service>>((ref) async {
  final api = ref.read(serviceApiProvider);
  return api.getServices();
});
