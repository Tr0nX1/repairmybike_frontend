import 'package:dio/dio.dart';
import '../models/cart.dart';
import '../utils/api_config.dart';

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
        baseUrl = base ?? apiBaseSpareParts;

  Future<Cart> getCart({String? cartKey, String? sessionToken}) async {
    final resp = await _dio.get(
      '$baseUrl/cart/',
      options: Options(headers: {
        if (cartKey != null && cartKey.isNotEmpty) 'Cart-Key': cartKey,
        if (sessionToken != null && sessionToken.isNotEmpty)
          'Authorization': 'Bearer $sessionToken',
      }),
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
    String? cartKey,
    String? sessionToken,
  }) async {
    final payload = {
      'spare_part_id': partId,
      'quantity': quantity,
    };
    final resp = await _dio.post(
      '$baseUrl/cart/add/',
      data: payload,
      options: Options(headers: {
        if (cartKey != null && cartKey.isNotEmpty) 'Cart-Key': cartKey,
        if (sessionToken != null && sessionToken.isNotEmpty)
          'Authorization': 'Bearer $sessionToken',
      }),
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
    String? cartKey,
    String? sessionToken,
  }) async {
    final payload = {'quantity': quantity};
    final resp = await _dio.patch(
      '$baseUrl/cart/items/$itemId/',
      data: payload,
      options: Options(headers: {
        if (cartKey != null && cartKey.isNotEmpty) 'Cart-Key': cartKey,
        if (sessionToken != null && sessionToken.isNotEmpty)
          'Authorization': 'Bearer $sessionToken',
      }),
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
    String? cartKey,
    String? sessionToken,
  }) async {
    final resp = await _dio.delete(
      '$baseUrl/cart/items/$itemId/',
      options: Options(headers: {
        if (cartKey != null && cartKey.isNotEmpty) 'Cart-Key': cartKey,
        if (sessionToken != null && sessionToken.isNotEmpty)
          'Authorization': 'Bearer $sessionToken',
      }),
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