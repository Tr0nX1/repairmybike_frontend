import 'package:dio/dio.dart';
import '../utils/api_config.dart';

class SavedServicesApi {
  final Dio _dio = Dio();

  String get _baseUrl => '${resolveBackendBase()}/api/services';

  Future<List<int>> getSavedServiceIds(String sessionToken) async {
    try {
      final response = await _dio.get(
        '$_baseUrl/saved-services/',
        options: Options(
          headers: {
            'Authorization': 'Token $sessionToken',
            'Content-Type': 'application/json',
          },
        ),
      );

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
        options: Options(
          headers: {
            'Authorization': 'Token $sessionToken',
            'Content-Type': 'application/json',
          },
        ),
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
        options: Options(
          headers: {
            'Authorization': 'Token $sessionToken',
            'Content-Type': 'application/json',
          },
        ),
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}
