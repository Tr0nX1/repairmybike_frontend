import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show debugPrint;
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
      ) {
    assert(() {
      _dio.interceptors.add(
        LogInterceptor(request: true, responseBody: false, error: true),
      );
      _dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (o, h) {
            debugPrint('➡️ ${o.method} ${o.uri}');
            h.next(o);
          },
          onResponse: (r, h) {
            debugPrint(
              '✅ ${r.requestOptions.method} ${r.requestOptions.uri} -> ${r.statusCode}',
            );
            h.next(r);
          },
          onError: (e, h) {
            debugPrint(
              '❌ ${e.requestOptions.method} ${e.requestOptions.uri} -> ${e.message}',
            );
            h.next(e);
          },
        ),
      );
      return true;
    }());
  }

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
