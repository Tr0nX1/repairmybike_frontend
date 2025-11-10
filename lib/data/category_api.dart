import 'package:dio/dio.dart';
import '../models/category.dart';
import '../utils/api_config.dart';

class CategoryApi {
  final Dio _dio;

  CategoryApi()
      : _dio = Dio(
          BaseOptions(
            baseUrl: backendBase,
            connectTimeout: const Duration(seconds: 10),
            receiveTimeout: const Duration(seconds: 15),
          ),
        );

  Future<List<Category>> getCategories() async {
    final res = await _dio.get('/api/services/service-categories/');
    final body = res.data;

    if (body is Map<String, dynamic>) {
      final error = body['error'] == true;
      if (error) {
        throw Exception(body['message'] ?? 'Failed to load categories');
      }
      final data = body['data'];
      if (data is List) {
        return data
            .map((e) => Category.fromJson(e as Map<String, dynamic>))
            .toList();
      }
    }
    throw Exception('Unexpected response shape for categories');
  }
}