import '../utils/api_config.dart';
import 'app_state.dart';
import 'api_client.dart';
import 'package:flutter/foundation.dart';

class NotificationsApi {
  final Dio _dio = ApiClient().dio;
  final String baseUrl = backendBase;

  Future<List<Map<String, dynamic>>> getNotificationHistory() async {
    if (AppState.sessionToken == null) return [];

    try {
      final response = await _dio.get(
        'api/notifications/history/',
      );

      if (response.statusCode == 200) {
        final List data = response.data;
        return data.cast<Map<String, dynamic>>();
      }
      return [];
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error fetching notification history: $e');
      }
      return [];
    }
  }
}
