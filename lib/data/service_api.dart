import 'package:dio/dio.dart';
import 'api_client.dart';
import '../models/service.dart';



class ServiceApi {
  final Dio _dio;

  ServiceApi() : _dio = ApiClient().dio;


  Future<List<Service>> getServices({int? categoryId}) async {
    final res = await _dio.get(
      '/api/services/services/',
      queryParameters: categoryId != null
          ? {
              // assuming backend supports filtering by category id
              'service_category': categoryId,
            }
          : null,
    );
    final body = res.data;
    if (body is Map<String, dynamic>) {
      final error = body['error'] == true;
      if (error) {
        throw Exception(body['message'] ?? 'Failed to load services');
      }
      final data = body['data'];
      if (data is List) {
        final list = data
            .map((e) => Service.fromJson(e as Map<String, dynamic>))
            .toList();
        // If server didn't filter, and a categoryId was provided, filter locally
        if (categoryId != null) {
          return list.where((s) => s.serviceCategory == categoryId).toList();
        }
        return list;
      }
    }
    throw Exception('Unexpected response shape for services');
  }
}
