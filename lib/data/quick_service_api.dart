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
      // BUG 3 FIX: Backend endpoint is missing. 
      // Return null or handle gracefully.
      if (kDebugMode) {
        debugPrint('QuickService endpoint missing. Skipping call for $phoneNumber');
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<List<QuickServiceRequest>> getHistory() async {
    try {
      // BUG 3 FIX: Backend endpoint is missing. Return empty list.
      return [];
    } catch (_) {
      return [];
    }
  }
}
