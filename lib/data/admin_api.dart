import 'api_client.dart';

class AdminApi {
  final ApiClient _client = ApiClient();

  /// CMS: Get app banners
  Future<Map<String, dynamic>> getBanners() async {
    // Placeholder endpoint, as backend app for banners is not yet implemented
    try {
      final response = await _client.dio.get('api/cms/banners/');
      return response.data;
    } catch (e) {
      return {'error': false, 'data': []}; // Fallback for UI testing
    }
  }

  /// CMS: Broadcast Push Notification
  Future<Map<String, dynamic>> broadcastNotification(Map<String, dynamic> data) async {
    try {
      final response = await _client.dio.post('api/notifications/broadcast/', data: data);
      return response.data;
    } catch (e) {
      rethrow;
    }
  }

  /// Staff Management: List all staff from directory
  Future<Map<String, dynamic>> getStaffDirectory() async {
    try {
      final response = await _client.dio.get('api/auth/staff-directory/');
      return response.data;
    } catch (e) {
      rethrow;
    }
  }

  /// Pricing: Update service pricing
  Future<Map<String, dynamic>> updateServicePricing(int pricingId, double newPrice) async {
    try {
      final response = await _client.dio.patch(
        'api/services/pricing/$pricingId/',
        data: {'price': newPrice},
      );
      return response.data;
    } catch (e) {
      rethrow;
    }
  }

  /// Audit: Fetch system activity logs
  Future<Map<String, dynamic>> getActivityLogs({String? actionType, int? userId}) async {
    try {
      final response = await _client.dio.get(
        'api/staff/logs/',
        queryParameters: {
          if (actionType != null) 'action_type': actionType,
          if (userId != null) 'user_id': userId,
        },
      );
      return response.data;
    } catch (e) {
      rethrow;
    }
  }
}
