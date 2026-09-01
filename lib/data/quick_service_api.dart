import 'package:flutter/foundation.dart';
import 'api_client.dart';
import 'app_state.dart';
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

  Future<QuickServiceRequest?> createRequest({
    required String phoneNumber,
    String? name,
    String? vehicleNumber,
    String? vehicleManufacturer,
    String? vehicleModel,
  }) async {
    try {
      final reqName = (name != null && name.trim().isNotEmpty)
          ? name.trim()
          : (AppState.fullName != null && AppState.fullName!.trim().isNotEmpty
              ? AppState.fullName!.trim()
              : 'Guest Customer');

      final reqPhone = phoneNumber.trim().isNotEmpty
          ? phoneNumber.trim()
          : (AppState.phoneNumber != null && AppState.phoneNumber!.trim().isNotEmpty
              ? AppState.phoneNumber!.trim()
              : '');

      if (reqPhone.isEmpty) {
        if (kDebugMode) {
          debugPrint('DEBUG: QuickServiceApi.createRequest error: Phone number is required');
        }
        return null;
      }

      final payload = <String, dynamic>{
        'name': reqName,
        'phone_number': reqPhone,
      };

      if (vehicleNumber != null && vehicleNumber.trim().isNotEmpty) {
        payload['vehicle_number'] = vehicleNumber.trim();
      }
      if (vehicleManufacturer != null && vehicleManufacturer.trim().isNotEmpty) {
        payload['vehicle_manufacturer'] = vehicleManufacturer.trim();
      }
      if (vehicleModel != null && vehicleModel.trim().isNotEmpty) {
        payload['vehicle_model'] = vehicleModel.trim();
      }

      if (kDebugMode) {
        debugPrint('DEBUG: QuickServiceApi.createRequest payload: $payload');
      }

      final response = await _client.post('api/quick-service/requests/', data: payload);
      if (kDebugMode) {
        debugPrint('DEBUG: QuickServiceApi.createRequest response [${response.statusCode}]: ${response.data}');
      }

      if ((response.statusCode == 200 || response.statusCode == 201) && response.data is Map<String, dynamic>) {
        return QuickServiceRequest.fromJson(response.data as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('DEBUG: QuickServiceApi.createRequest error: $e');
      }
      return null;
    }
  }

  Future<List<QuickServiceRequest>> getHistory() async {
    try {
      if (kDebugMode) {
        debugPrint('DEBUG: QuickServiceApi.getHistory() calling api/quick-service/requests/');
      }
      final response = await _client.get('api/quick-service/requests/');
      final data = response.data;
      List rawList = [];
      if (data is Map && data.containsKey('results')) {
        rawList = data['results'] as List;
      } else if (data is List) {
        rawList = data;
      }
      
      return rawList
          .map((item) => QuickServiceRequest.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('DEBUG: QuickServiceApi.getHistory error: $e');
      }
      return [];
    }
  }
}
