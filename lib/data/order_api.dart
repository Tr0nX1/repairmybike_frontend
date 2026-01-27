import 'api_client.dart';
import '../models/order.dart';
import 'app_state.dart';

import '../utils/api_config.dart';



class OrderApi {
  final Dio _dio;
  final String baseUrl;

  OrderApi({Dio? dio, String? base})
      : _dio = dio ?? ApiClient().dio,
        baseUrl = base ?? apiBaseSpareParts;


  Future<Order> checkoutCash({
    required String sessionId,
    required String customerName,
    required String phone,
    required String address,
  }) async {
    final payload = {
      'session_id': sessionId,
      'customer_name': customerName,
      'phone': phone,
      'address': address,
    };
    try {
      final resp = await _dio.post('$baseUrl/cart/checkout/', data: payload);
      final body = resp.data;
      if (body is Map<String, dynamic>) {
        final orderCandidate = body['data'] ?? body['order'] ?? body;
        if (orderCandidate is Map<String, dynamic>) {
          return Order.fromJson(orderCandidate);
        }
        final err = body['message'] ?? body['error'] ?? 'Unexpected response';
        throw Exception(err);
      }
      throw Exception('Unexpected response shape for checkout');
    } on DioException catch (e) {
      final status = e.response?.statusCode;
      if (status == 404) {
        throw Exception('Order endpoint unavailable (404). Please try again later.');
      }
      final data = e.response?.data;
      var msg = 'Checkout failed';
      if (data is Map && data['message'] is String) msg = data['message'];
      if (data is Map && data['error'] is String) msg = data['error'];
      if (data is String && data.isNotEmpty) msg = data;
      throw Exception(msg);
    }
  }

  Future<Order> buyNow({
    required String sessionId,
    required int sparePartId,
    required int quantity,
    required String customerName,
    required String phone,
    required String address,
  }) async {
    final payload = {
      'session_id': sessionId,
      'spare_part_id': sparePartId,
      'quantity': quantity,
      'customer_name': customerName,
      'phone': phone,
      'address': address,
    };
    try {
      final resp = await _dio.post('$baseUrl/cart/buy_now/', data: payload);
      final body = resp.data;
      if (body is Map<String, dynamic>) {
        final orderCandidate = body['data'] ?? body['order'] ?? body;
        if (orderCandidate is Map<String, dynamic>) {
          return Order.fromJson(orderCandidate);
        }
        final err = body['message'] ?? body['error'] ?? 'Unexpected response';
        throw Exception(err);
      }
      throw Exception('Unexpected response shape for buy_now');
    } on DioException catch (e) {
      final status = e.response?.statusCode;
      if (status == 404) {
        throw Exception('Buy-now endpoint unavailable (404). Please try again later.');
      }
      final data = e.response?.data;
      var msg = 'Buy now failed';
      if (data is Map && data['message'] is String) msg = data['message'];
      if (data is Map && data['error'] is String) msg = data['error'];
      if (data is String && data.isNotEmpty) msg = data;
      throw Exception(msg);
    }
  }

  Future<List<Order>> listOrders({
    String? sessionId,
  }) async {
    // If we have a sessionId (Guest), use it.
    // If not, we MUST be authenticated to fetch user orders.
    if (sessionId == null && !AppState.isAuthenticated) {
      // Return empty list instead of crashing, or throw?
      // Frontend expects a list.
      return [];
    }
    
    return _fetchOrdersSafe(
      sessionId != null ? {'session_id': sessionId} : {},
      null,
    );
  }

  Future<List<Order>> _fetchOrdersSafe(
    Map<String, dynamic> params,
    Options? options,
  ) async {
    try {
      final resp = await _dio.get(
        '$baseUrl/orders/',
        queryParameters: params,
        options: options,
      );
      final body = resp.data;
      if (body is Map && body['data'] is List) {
        return (body['data'] as List)
            .whereType<Map<String, dynamic>>()
            .map(Order.fromJson)
            .toList();
      }
      if (body is List) {
        return body
            .whereType<Map<String, dynamic>>()
            .map(Order.fromJson)
            .toList();
      }
    } catch (e) {
      // Ignore errors (404/400) for individual fetching strategies
    }
    return [];
  }

  Future<bool> cancelOrder(int orderId) async {
    try {
      await _dio.post('$baseUrl/orders/$orderId/cancel/');
      return true;
    } catch (e) {
      return false;
    }
  }
}
