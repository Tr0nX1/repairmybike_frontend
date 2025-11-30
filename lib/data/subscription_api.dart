import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../models/subscription.dart';
import '../utils/api_config.dart';

class SubscriptionApi {
  final Dio _dio;

  SubscriptionApi()
      : _dio = Dio(
          BaseOptions(
            baseUrl: backendBase,
            connectTimeout: const Duration(seconds: 10),
            receiveTimeout: const Duration(seconds: 15),
          ),
        ) {
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

  Future<List<SubscriptionPlan>> getPlans() async {
    final res = await _dio.get('/api/subscriptions/plans/');
    final body = res.data;
    // Handle plain list (typical DRF) or wrapped {data: [...]} response
    if (body is List) {
      return body
          .whereType<Map<String, dynamic>>()
          .map(SubscriptionPlan.fromJson)
          .toList();
    }
    if (body is Map<String, dynamic>) {
      final error = body['error'] == true;
      if (error) {
        throw Exception(body['message'] ?? 'Failed to load plans');
      }
      final listCandidate = body['data'] ?? body['results'] ?? body['plans'];
      if (listCandidate is List) {
        return listCandidate
            .whereType<Map<String, dynamic>>()
            .map(SubscriptionPlan.fromJson)
            .toList();
      }
    }
    throw Exception('Unexpected response shape for plans');
  }

  Future<SubscriptionItem> createSubscription({
    required int planId,
    String? contactPhone,
    String? contactEmail,
    int? userId,
    bool autoRenew = true,
  }) async {
    final payload = {
      'plan': planId,
      if (contactPhone != null && contactPhone.isNotEmpty) 'contact_phone': contactPhone,
      if (contactEmail != null && contactEmail.isNotEmpty) 'contact_email': contactEmail,
      if (userId != null) 'user': userId,
      'auto_renew': autoRenew,
    };
    final res = await _dio.post('/api/subscriptions/subscriptions/', data: payload);
    final body = res.data;
    if (body is Map<String, dynamic>) {
      // If wrapped {data: {...}} or direct object
      final error = body['error'] == true;
      if (error) {
        throw Exception(body['message'] ?? 'Failed to create subscription');
      }
      final objCandidate = body['data'] ?? body;
      if (objCandidate is Map<String, dynamic>) {
        return SubscriptionItem.fromJson(objCandidate);
      }
    }
    throw Exception('Unexpected response shape for subscription');
  }

  Future<List<SubscriptionItem>> getSubscriptionsByPhone(String phone) async {
    final res = await _dio.get(
      '/api/subscriptions/subscriptions/',
      // Backend filter field is 'phone' (maps to contact_phone in queryset)
      queryParameters: {'phone': phone},
    );
    final body = res.data;
    // Support plain list, paginated {results: [...]}, or wrapped {data: [...]}
    if (body is List) {
      return body
          .whereType<Map<String, dynamic>>()
          .map(SubscriptionItem.fromJson)
          .toList();
    }
    if (body is Map<String, dynamic>) {
      final error = body['error'] == true;
      if (error) {
        throw Exception(body['message'] ?? 'Failed to fetch subscriptions');
      }
      final listCandidate = body['data'] ?? body['results'];
      if (listCandidate is List) {
        return listCandidate
            .whereType<Map<String, dynamic>>()
            .map(SubscriptionItem.fromJson)
            .toList();
      }
    }
    throw Exception('Unexpected response shape for subscriptions list');
  }

  Future<SubscriptionItem> updateSubscriptionMetadata(int subscriptionId, Map<String, dynamic> metadata) async {
    final payload = {
      'metadata': metadata,
    };
    final res = await _dio.patch('/api/subscriptions/subscriptions/$subscriptionId/', data: payload);
    final body = res.data;
    if (body is Map<String, dynamic>) {
      final error = body['error'] == true;
      if (error) {
        throw Exception(body['message'] ?? 'Failed to update subscription');
      }
      final objCandidate = body['data'] ?? body;
      if (objCandidate is Map<String, dynamic>) {
        return SubscriptionItem.fromJson(objCandidate);
      }
    }
    throw Exception('Unexpected response shape for subscription update');
  }
}
