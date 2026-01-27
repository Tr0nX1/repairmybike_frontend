import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/spare_parts_api.dart';
import '../models/spare_part.dart';
import '../models/spare_part_category.dart';
import '../models/spare_part_brand.dart';

final sparePartsApiProvider = Provider<SparePartsApi>((ref) => SparePartsApi());

final sparePartCategoriesProvider = FutureProvider.autoDispose<List<SparePartCategory>>((ref) async {
  final api = ref.read(sparePartsApiProvider);
  return api.getCategories();
});

final sparePartBrandsProvider = FutureProvider.autoDispose<List<SparePartBrand>>((ref) async {
  final api = ref.read(sparePartsApiProvider);
  return api.getBrands();
});

class PartsFilter {
  final int? categoryId;
  final int? brandId;
  final bool? inStock;
  final String? search;
  
  const PartsFilter({this.categoryId, this.brandId, this.inStock, this.search});
  
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PartsFilter &&
          runtimeType == other.runtimeType &&
          categoryId == other.categoryId &&
          brandId == other.brandId &&
          inStock == other.inStock &&
          search == other.search;

  @override
  int get hashCode =>
      categoryId.hashCode ^
      brandId.hashCode ^
      inStock.hashCode ^
      search.hashCode;
}

final sparePartsByFilterProvider = FutureProvider.autoDispose.family<List<SparePartListItem>, PartsFilter>((ref, filter) async {
  final api = ref.read(sparePartsApiProvider);
  return api.getParts(
    categoryId: filter.categoryId,
    brandId: filter.brandId,
    inStock: filter.inStock,
    search: filter.search,
  );
});

final addToCartProvider = FutureProvider.autoDispose.family<Map<String, dynamic>, ({int partId, int quantity})>((ref, args) async {
  final api = ref.read(sparePartsApiProvider);
  return api.addToCart(partId: args.partId, quantity: args.quantity);
});