import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../utils/api_config.dart';
import '../models/cart.dart';

class CartApi {
  final Dio _dio;
  final String baseUrl;

  CartApi({Dio? dio, String? base})
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

  Future<Cart> getCart({required String sessionId}) async {
    final resp = await _dio.get(
      '$baseUrl/cart/',
      queryParameters: {'session_id': sessionId},
    );
    final data = resp.data;
    if (data is Map<String, dynamic>) {
      final cartCandidate = data['data'] ?? data['cart'] ?? data;
      if (cartCandidate is Map<String, dynamic>) {
        return Cart.fromJson(cartCandidate);
      }
    }
    // Fallback empty cart
    return Cart.empty();
  }

  Future<Cart> addItem({
    required int partId,
    int quantity = 1,
    required String sessionId,
  }) async {
    final payload = {
      'session_id': sessionId,
      'spare_part_id': partId,
      'quantity': quantity,
    };
    final resp = await _dio.post(
      '$baseUrl/cart/add/',
      data: payload,
    );
    final data = resp.data;
    if (data is Map<String, dynamic>) {
      final cartCandidate = data['data'] ?? data['cart'] ?? data;
      if (cartCandidate is Map<String, dynamic>) {
        return Cart.fromJson(cartCandidate);
      }
    }
    return Cart.empty();
  }

  Future<Cart> updateItem({
    required int itemId,
    required int quantity,
    required String sessionId,
  }) async {
    final payload = {
      'session_id': sessionId,
      'item_id': itemId,
      'quantity': quantity,
    };
    final resp = await _dio.patch(
      '$baseUrl/cart/update_item/',
      data: payload,
    );
    final data = resp.data;
    if (data is Map<String, dynamic>) {
      final cartCandidate = data['data'] ?? data['cart'] ?? data;
      if (cartCandidate is Map<String, dynamic>) {
        return Cart.fromJson(cartCandidate);
      }
    }
    return Cart.empty();
  }

  Future<Cart> removeItem({
    required int itemId,
    required String sessionId,
  }) async {
    final resp = await _dio.delete(
      '$baseUrl/cart/remove_item/',
      queryParameters: {
        'session_id': sessionId,
        'item_id': itemId,
      },
    );
    final data = resp.data;
    if (data is Map<String, dynamic>) {
      final cartCandidate = data['data'] ?? data['cart'] ?? data;
      if (cartCandidate is Map<String, dynamic>) {
        return Cart.fromJson(cartCandidate);
      }
    }
    return Cart.empty();
  }

  Future<Cart> clear({required String sessionId}) async {
    final resp = await _dio.delete(
      '$baseUrl/cart/clear/',
      queryParameters: {'session_id': sessionId},
    );
    final data = resp.data;
    if (data is Map<String, dynamic>) {
      final cartCandidate = data['data'] ?? data['cart'] ?? data;
      if (cartCandidate is Map<String, dynamic>) {
        return Cart.fromJson(cartCandidate);
      }
    }
    return Cart.empty();
  }
}
