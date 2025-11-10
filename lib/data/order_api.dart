import 'package:dio/dio.dart';
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
        baseUrl = base ?? apiBaseSpareParts;

  Future<Order> checkoutCash({
    required String shippingAddress,
    required String phone,
    String? cartKey,
    String? sessionToken,
    String? idempotencyKey,
  }) async {
    final payload = {
      'shipping_address': shippingAddress,
      'phone': phone,
      'payment_method': 'cash',
    };
    final resp = await _dio.post(
      '$baseUrl/cart/checkout/',
      data: payload,
      options: Options(headers: {
        if (cartKey != null && cartKey.isNotEmpty) 'Cart-Key': cartKey,
        if (sessionToken != null && sessionToken.isNotEmpty)
          'Authorization': 'Bearer $sessionToken',
        if (idempotencyKey != null && idempotencyKey.isNotEmpty)
          'Idempotency-Key': idempotencyKey,
      }),
    );
    final body = resp.data;
    if (body is Map<String, dynamic>) {
      final orderCandidate = body['data'] ?? body['order'] ?? body;
      if (orderCandidate is Map<String, dynamic>) {
        return Order.fromJson(orderCandidate);
      }
    }
    throw Exception('Unexpected response shape for checkout');
  }
}