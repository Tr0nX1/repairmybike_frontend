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
    // Defensive cleanup of the backend URL to prevent common typos
    var cleanedBase = backendBase.trim().replaceAll('..', '.');
    
    // Ensure baseUrl always ends with / for proper path concatenation
    final normalizedBase = cleanedBase.endsWith('/') 
        ? cleanedBase 
        : '$cleanedBase/';
    
    if (kDebugMode) {
      debugPrint('🌐 Initializing ApiClient with Base URL: $normalizedBase');
      // If still seeing double dots, log hex to see hidden chars
      if (normalizedBase.contains('..')) {
        debugPrint('⚠️ Detected persistent double dot! Hex: ${normalizedBase.codeUnits.map((e) => e.toRadixString(16)).join(" ")}');
      }
    }

    dio = Dio(
      BaseOptions(
        baseUrl: normalizedBase,
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
      ),
    );

    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          // Check token expiry proactively
          final path = options.path;
          final isAuthEndpoint = path.contains('auth/token') || path.contains('auth/otp');

          if (!isAuthEndpoint && AppState.isSessionExpired) {
            final refreshToken = AppState.refreshToken;
            if (refreshToken != null && refreshToken.isNotEmpty) {
              try {
                if (kDebugMode) {
                  debugPrint('🔄 Proactively refreshing expired token before request: ${options.uri}');
                }
                final refreshResponse = await dio.post(
                  'api/auth/token/refresh/',
                  data: {'refresh_token': refreshToken},
                );
                final data = refreshResponse.data;
                if (data is Map<String, dynamic>) {
                  final newToken = data['session_token'] as String?;
                  if (newToken != null) {
                    await AppState.setTokens(
                      session: newToken,
                      refresh: data['refresh_token'] as String? ?? refreshToken,
                    );
                  }
                }
              } catch (_) {
                // Let request proceed; if it fails with 401, response interceptor will handle it
              }
            }
          }

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
            if (e.response?.data != null) {
              debugPrint('   📄 Response Body: ${e.response?.data}');
            }
          }
          

          // Handle 403 Forbidden - Permission Denied / Access Denied
          // We should NOT clear the auth state (logout the user) on 403, 
          // because 403 means the user is authenticated but doesn't have access to this resource.
          if (e.response?.statusCode == 403) {
            if (kDebugMode) {
              debugPrint('⛔ 403 Forbidden / Access Denied detected for: ${e.requestOptions.uri}');
            }
            return handler.next(e);
          }

          // Handle 401 Unauthorized - attempt token refresh
          if (e.response?.statusCode == 401) {
            if (_isRefreshing) {
              if (kDebugMode) {
                debugPrint('🔄 Token refresh already in progress, skipping duplicate refresh');
              }
              return handler.next(e);
            }
            
            final refreshToken = AppState.refreshToken;
            if (kDebugMode) {
              debugPrint('🔑 401 Unauthorized detected. Current sessionToken: ${AppState.sessionToken != null ? (AppState.sessionToken!.length > 10 ? AppState.sessionToken!.substring(0, 10) : AppState.sessionToken) : "null"}...');
              debugPrint('🔑 Refresh token present: ${refreshToken != null && refreshToken.isNotEmpty} (length: ${refreshToken?.length ?? 0})');
            }
            
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
                    if (AppState.isStaff) {
                      await AppState.setStaffAuth(
                        username: AppState.staffUsername ?? '',
                        session: newSessionToken,
                        refresh: newRefreshToken ?? refreshToken,
                      );
                    } else {
                      await AppState.setAuth(
                        phone: AppState.phoneNumber ?? '',
                        session: newSessionToken,
                        refresh: newRefreshToken ?? refreshToken,
                      );
                    }
                    
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
                AppState.onAuthFailure?.call();
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
