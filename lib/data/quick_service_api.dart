import 'package:flutter/foundation.dart';
import 'api_client.dart';
import '../models/quick_service.dart';

class QuickServiceApi {
  final _client = ApiClient().dio;

  Future<QuickServiceConfig?> getConfig() async {
    try {
      if (kDebugMode) {
        debugPrint('DEBUG: QuickServiceApi.getConfig() calling api/quick-service/config/');
      }
      final response = await _client.get('api/quick-service/config/');
      if (kDebugMode) {
        debugPrint('DEBUG: QuickServiceApi.getConfig() response: ${response.data}');
      }
      
      final data = response.data;
      if (data is List) {
        if (data.isNotEmpty) {
          try {
            return QuickServiceConfig.fromJson(data.first as Map<String, dynamic>);
          } catch (e) {
            if (kDebugMode) {
              debugPrint('DEBUG: QuickServiceConfig.fromJson error: $e');
            }
          }
        }
      } else if (data is Map) {
        try {
          return QuickServiceConfig.fromJson(data as Map<String, dynamic>);
        } catch (e) {
          if (kDebugMode) {
            debugPrint('DEBUG: QuickServiceConfig.fromJson error: $e');
          }
        }
      }
      return null;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('DEBUG: QuickServiceApi.getConfig() global error: $e');
      }
      return null;
    }
  }

  Future<QuickServiceRequest?> createRequest(String phoneNumber) async {
    try {
      if (kDebugMode) {
        debugPrint('DEBUG: QuickServiceApi.createRequest() calling api/quick-service/requests/ for $phoneNumber');
      }
      final response = await _client.post('api/quick-service/requests/', data: {
        'phone_number': phoneNumber,
      });
      if (kDebugMode) {
        debugPrint('DEBUG: QuickServiceApi.createRequest() response: ${response.data}');
      }
      return QuickServiceRequest.fromJson(response.data);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('DEBUG: QuickServiceApi.createRequest() error: $e');
      }
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
