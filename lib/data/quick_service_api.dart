import 'api_client.dart';
import '../models/quick_service.dart';

class QuickServiceApi {
  final _client = ApiClient().dio;

  Future<QuickServiceConfig?> getConfig() async {
    try {
      print('DEBUG: QuickServiceApi.getConfig() calling api/quick-service/config/');
      final response = await _client.get('api/quick-service/config/');
      print('DEBUG: QuickServiceApi.getConfig() response: ${response.data}');
      
      if (response.data is List) {
        final list = (response.data as List).cast<Map<String, dynamic>>();
        if (list.isNotEmpty) {
          return QuickServiceConfig.fromJson(list.first);
        }
      } else if (response.data is Map) {
         return QuickServiceConfig.fromJson(response.data as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      print('DEBUG: QuickServiceApi.getConfig() error: $e');
      return null;
    }
  }

  Future<QuickServiceRequest?> createRequest(String phoneNumber) async {
    try {
      print('DEBUG: QuickServiceApi.createRequest() calling api/quick-service/requests/ for $phoneNumber');
      final response = await _client.post('api/quick-service/requests/', data: {
        'phone_number': phoneNumber,
      });
      print('DEBUG: QuickServiceApi.createRequest() response: ${response.data}');
      return QuickServiceRequest.fromJson(response.data);
    } catch (e) {
      print('DEBUG: QuickServiceApi.createRequest() error: $e');
      return null;
    }
  }

  Future<List<QuickServiceRequest>> getHistory() async {
    try {
      final response = await _client.get('api/quick-service/requests/');
      final list = (response.data as List).cast<Map<String, dynamic>>();
      return list.map((e) => QuickServiceRequest.fromJson(e)).toList();
    } catch (_) {
      return [];
    }
  }
}
