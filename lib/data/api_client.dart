export 'package:dio/dio.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../utils/api_config.dart';
import 'app_state.dart';

class ApiClient {
  static final ApiClient _instance = ApiClient._internal();
  late final Dio dio;
  bool _isRefreshing = false;

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
          } else {
            // Attach Guest ID for unauthenticated users
            final guestId = AppState.guestId;
            if (guestId != null && guestId.isNotEmpty) {
              options.headers['X-Guest-ID'] = guestId;
            }
          }
          
          if (kDebugMode) {
            debugPrint('➡️ ${options.method} ${options.uri}');
            // Debug: Print auth header to verify token is being sent
            if (options.headers['Authorization'] != null) {
              final authHeader = options.headers['Authorization'] as String;
              final tokenPreview = authHeader.length > 30 
                  ? '${authHeader.substring(0, 30)}...' 
                  : authHeader;
              debugPrint('   🔑 Auth: $tokenPreview');
            } else {
              debugPrint('   ⚠️  No auth header');
            }
          }
          return handler.next(options);
        },
        onResponse: (response, handler) {
          if (kDebugMode) {
            debugPrint('✅ ${response.requestOptions.method} ${response.requestOptions.uri} -> ${response.statusCode}');
          }
          return handler.next(response);
        },
        onError: (DioException e, handler) async {
          if (kDebugMode) {
            debugPrint('❌ ${e.requestOptions.method} ${e.requestOptions.uri} -> ${e.message} [${e.response?.statusCode}]');
          }
          

          // Handle 403 Forbidden - Invalid Token / Environment Mismatch
          // If we send a token that the backend hates (e.g. wrong environment/project), it returns 403.
          // We must clear the bad token so the app can redirect to login.
          if (e.response?.statusCode == 403) {
            if (kDebugMode) {
              debugPrint('⛔ 403 Forbidden detected. Clearing invalid auth state...');
            }

            // 1. Clear invalid auth state locally
            await AppState.clearAuth();
            
            // 2. Propagate error so UI (e.g. FlashPage) knows to redirect
            return handler.next(e);
          }

          // Handle 401 Unauthorized - attempt token refresh
          if (e.response?.statusCode == 401 && !_isRefreshing) {
            final refreshToken = AppState.refreshToken;
            
            // Only attempt refresh if we have a refresh token
            if (refreshToken != null && refreshToken.isNotEmpty) {
              _isRefreshing = true;
              
              try {
                if (kDebugMode) {
                  debugPrint('🔄 Attempting token refresh...');
                }
                
                // Call refresh endpoint
                final refreshResponse = await dio.post(
                  'api/auth/token/refresh/',
                  data: {'refresh_token': refreshToken},
                );
                
                final data = refreshResponse.data;
                if (data is Map<String, dynamic>) {
                  final newSessionToken = data['session_token'] as String?;
                  final newRefreshToken = data['refresh_token'] as String?;
                  
                  if (newSessionToken != null) {
                    // Update AppState with new tokens
                    await AppState.setAuth(
                      phone: AppState.phoneNumber ?? '',
                      session: newSessionToken,
                      refresh: newRefreshToken ?? refreshToken,
                    );
                    
                    if (kDebugMode) {
                      debugPrint('✅ Token refreshed successfully');
                    }
                    
                    // Retry the original request with new token
                    final opts = Options(
                      method: e.requestOptions.method,
                      headers: {
                        ...e.requestOptions.headers,
                        'Authorization': 'Bearer $newSessionToken',
                      },
                    );
                    
                    final retryResponse = await dio.request(
                      e.requestOptions.path,
                      options: opts,
                      data: e.requestOptions.data,
                      queryParameters: e.requestOptions.queryParameters,
                    );
                    
                    _isRefreshing = false;
                    return handler.resolve(retryResponse);
                  }
                }
              } catch (refreshError) {
                if (kDebugMode) {
                  debugPrint('❌ Token refresh failed: $refreshError');
                }
                _isRefreshing = false;
                
                // Clear auth state on refresh failure
                await AppState.clearAuth();
              }
              
              _isRefreshing = false;
            }
          }
          
          return handler.next(e);
        },
      ),
    );
  }
}
