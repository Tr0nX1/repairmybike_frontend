import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../models/order.dart';
import '../utils/api_config.dart';

class OrderApi {
  final Dio _dio;
  final String baseUrl;

  OrderApi({Dio? dio, String? base})
      : _dio = dio ?? Dio(
          BaseOptions(
            baseUrl: backendBase,
            connectTimeout: const Duration(seconds: 10),
            receiveTimeout: const Duration(seconds: 15),
          ),
        ),
        baseUrl = base ?? apiBaseSpareParts {
    assert(() {
      _dio.interceptors.add(LogInterceptor(request: true, responseBody: false, error: true));
      _dio.interceptors.add(InterceptorsWrapper(
        onRequest: (o, h) {
          debugPrint('➡️ ${o.method} ${o.uri}');
          h.next(o);
        },
        onResponse: (r, h) {
          debugPrint('✅ ${r.requestOptions.method} ${r.requestOptions.uri} -> ${r.statusCode}');
          h.next(r);
        },
        onError: (e, h) {
          debugPrint('❌ ${e.requestOptions.method} ${e.requestOptions.uri} -> ${e.message}');
          h.next(e);
        },
      ));
      return true;
    }());
  }

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

  Future<List<Order>> listOrders({required String sessionId}) async {
    final resp = await _dio.get('$baseUrl/orders/', queryParameters: {'session_id': sessionId});
    final body = resp.data;
    if (body is Map && body['data'] is List) {
      return (body['data'] as List)
          .whereType<Map<String, dynamic>>()
          .map(Order.fromJson)
          .toList();
    }
    if (body is List) {
      return body.whereType<Map<String, dynamic>>().map(Order.fromJson).toList();
    }
    return [];
  }
}
