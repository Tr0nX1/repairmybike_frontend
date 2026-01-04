export 'package:dio/dio.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../utils/api_config.dart';
import 'app_state.dart';

class ApiClient {
  static final ApiClient _instance = ApiClient._internal();
  late final Dio dio;

  factory ApiClient() => _instance;

  ApiClient._internal() {
    dio = Dio(
      BaseOptions(
        baseUrl: backendBase,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 15),
      ),
    );

    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          // Automatically attach Authorization header if token exists
          final token = AppState.sessionToken;
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          
          if (kDebugMode) {
            debugPrint('➡️ ${options.method} ${options.uri}');
          }
          return handler.next(options);
        },
        onResponse: (response, handler) {
          if (kDebugMode) {
            debugPrint('✅ ${response.requestOptions.method} ${response.requestOptions.uri} -> ${response.statusCode}');
          }
          return handler.next(response);
        },
        onError: (DioException e, handler) {
          if (kDebugMode) {
            debugPrint('❌ ${e.requestOptions.method} ${e.requestOptions.uri} -> ${e.message} [${e.response?.statusCode}]');
          }
          // Global 401 handling could go here (e.g., triggering a logout or refresh)
          return handler.next(e);
        },
      ),
    );
  }
}
