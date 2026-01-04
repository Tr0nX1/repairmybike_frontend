import 'package:dio/dio.dart';
import 'api_client.dart';
import '../models/spare_part.dart';
import '../models/spare_part_category.dart';
import '../models/spare_part_brand.dart';

import '../utils/api_config.dart';


class SparePartsApi {
  final Dio _dio;
  final String baseUrl;

  SparePartsApi({Dio? dio, String? base})
      : _dio = dio ?? ApiClient().dio,
        baseUrl = base ?? apiBaseSpareParts;


  Future<List<SparePartListItem>> getParts({int? categoryId, int? brandId, bool? inStock, String? search}) async {
    final params = <String, dynamic>{};
    if (categoryId != null) params['category'] = categoryId;
    if (brandId != null) params['brand'] = brandId;
    if (inStock != null) params['in_stock'] = inStock;
    if (search != null && search.isNotEmpty) {
      // support both 'search' and 'q'
      params['search'] = search;
      params['q'] = search;
    }
    final resp = await _dio.get('$baseUrl/parts/', queryParameters: params);
    final data = resp.data;
    if (data is List) {
      return data.map((e) => SparePartListItem.fromJson(e as Map<String, dynamic>)).toList();
    }
    if (data is Map && data['data'] is List) {
      return (data['data'] as List)
          .whereType<Map<String, dynamic>>()
          .map(SparePartListItem.fromJson)
          .toList();
    }
    if (data is Map && data['results'] is List) {
      return (data['results'] as List)
          .whereType<Map<String, dynamic>>()
          .map(SparePartListItem.fromJson)
          .toList();
    }
    return [];
  }

  Future<List<SparePartCategory>> getCategories() async {
    final resp = await _dio.get('$baseUrl/categories/');
    final data = resp.data;
    if (data is List) {
      return data.map((e) => SparePartCategory.fromJson(e as Map<String, dynamic>)).toList();
    }
    if (data is Map && data['data'] is List) {
      return (data['data'] as List)
          .whereType<Map<String, dynamic>>()
          .map(SparePartCategory.fromJson)
          .toList();
    }
    if (data is Map && data['results'] is List) {
      return (data['results'] as List)
          .whereType<Map<String, dynamic>>()
          .map(SparePartCategory.fromJson)
          .toList();
    }
    return [];
  }

  Future<List<SparePartBrand>> getBrands() async {
    final resp = await _dio.get('$baseUrl/brands/');
    final data = resp.data;
    if (data is List) {
      return data.map((e) => SparePartBrand.fromJson(e as Map<String, dynamic>)).toList();
    }
    if (data is Map && data['data'] is List) {
      return (data['data'] as List)
          .whereType<Map<String, dynamic>>()
          .map(SparePartBrand.fromJson)
          .toList();
    }
    if (data is Map && data['results'] is List) {
      return (data['results'] as List)
          .whereType<Map<String, dynamic>>()
          .map(SparePartBrand.fromJson)
          .toList();
    }
    return [];
  }

  Future<Map<String, dynamic>> addToCart({required int partId, int quantity = 1}) async {
    final payload = {
      'session_id': DateTime.now().millisecondsSinceEpoch.toString(),
      'spare_part_id': partId,
      'quantity': quantity,
    };
    final resp = await _dio.post('$baseUrl/cart/add/', data: payload);
    final data = resp.data;
    if (data is Map<String, dynamic>) return data;
    return {'success': true};
  }
}
