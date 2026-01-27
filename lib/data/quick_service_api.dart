import 'api_client.dart';
import '../models/quick_service.dart';

class QuickServiceApi {
  final _client = ApiClient().dio;

  Future<QuickServiceConfig?> getConfig() async {
    try {
      final response = await _client.get('api/quick-service/config/');
      final list = (response.data as List).cast<Map<String, dynamic>>();
      if (list.isNotEmpty) {
        return QuickServiceConfig.fromJson(list.first);
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<QuickServiceRequest?> createRequest(String phoneNumber) async {
    try {
      final response = await _client.post('api/quick-service/requests/', data: {
        'phone_number': phoneNumber,
      });
      return QuickServiceRequest.fromJson(response.data);
    } catch (_) {
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
