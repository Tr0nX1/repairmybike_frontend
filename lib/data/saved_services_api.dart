import 'package:dio/dio.dart';
import 'api_client.dart';


class SavedServicesApi {
  final Dio _dio = ApiClient().dio;

  String get _baseUrl => 'api/services';


  Future<List<Map<String, dynamic>>> getSavedServices(String sessionToken) async {
    try {
      final response = await _dio.get('$_baseUrl/saved-services/');


      if (response.statusCode == 200 && response.data['error'] == false) {
        final List data = response.data['data'];
        return List<Map<String, dynamic>>.from(data);
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  Future<List<int>> getSavedServiceIds(String sessionToken) async {
    try {
      final response = await _dio.get('$_baseUrl/saved-services/');


      if (response.statusCode == 200 && response.data['error'] == false) {
        final List data = response.data['data'];
        return data.map<int>((item) => item['service']['id'] as int).toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  Future<bool> saveService(int serviceId, String sessionToken) async {
    try {
      final response = await _dio.post(
        '$_baseUrl/saved-services/',
        data: {'service_id': serviceId},
      );
      return response.statusCode == 201;
    } catch (e) {
      return false;
    }
  }

  Future<bool> removeService(int serviceId, String sessionToken) async {
    try {
      final response = await _dio.post(
        '$_baseUrl/saved-services/remove/',
        data: {'service_id': serviceId},
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}
