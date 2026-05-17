import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'network/secure_api_client.dart';
import '../models/notification.dart';

final notificationsApiProvider = Provider<NotificationsApi>((ref) {
  final client = ref.watch(secureApiClientProvider);
  return NotificationsApi(client);
});

class NotificationsApi {
  final Dio _client;
  NotificationsApi(this._client);

  Future<List<NotificationItem>> getNotifications({int page = 1}) async {
    try {
      final response = await _client.get('/api/notifications/', queryParameters: {'page': page});
      List<dynamic> list = [];
      if (response.data is List) {
        list = response.data;
      } else if (response.data is Map && response.data['results'] is List) {
        list = response.data['results'];
      }
      
      return list.map((e) => NotificationItem.fromJson(e as Map<String, dynamic>)).toList();
    } catch (e) {
      return [];
    }
  }

  Future<void> markAsRead(int id) async {
    try {
      await _client.post('/api/notifications/$id/mark-read/');
    } catch (e) {
      // log error
    }
  }

  Future<void> markAllRead() async {
    try {
      await _client.post('/api/notifications/mark-all-read/');
    } catch (e) {
      // log error
    }
  }
  
  // Legacy support for backward compatibility if needed
  Future<List<Map<String, dynamic>>> getNotificationHistory() async {
     try {
      final response = await _client.get('/api/notifications/');
      if (response.data is List) return List<Map<String, dynamic>>.from(response.data);
      if (response.data is Map && response.data['results'] is List) return List<Map<String, dynamic>>.from(response.data['results']);
      return [];
    } catch (e) {
      return [];
    }
  }
}
