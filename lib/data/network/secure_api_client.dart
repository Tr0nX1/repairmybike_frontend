import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../utils/api_config.dart';
import '../repositories/auth_repository.dart';

/// Interceptor that provides exponential backoff retries for failed network requests
class OfflineRetryInterceptor extends Interceptor {
  final Dio dio;
  final int maxRetries;

  OfflineRetryInterceptor({required this.dio, this.maxRetries = 3});

  bool _shouldRetry(DioException err) {
    return err.type == DioExceptionType.connectionTimeout ||
           err.type == DioExceptionType.sendTimeout ||
           err.type == DioExceptionType.receiveTimeout ||
           err.type == DioExceptionType.connectionError;
  }

  @override
  Future<void> onError(DioException err, ErrorInterceptorHandler handler) async {
    int retries = err.requestOptions.extra['retries'] ?? 0;
    
    // Check if error is network related and we haven't maxed out retries
    if (_shouldRetry(err) && retries < maxRetries) {
      retries++;
      if (kDebugMode) {
        debugPrint('⚠️ Network failure intercepted. Retrying [${err.requestOptions.path}] ($retries/$maxRetries)...');
      }
      
      // Calculate exponential backoff delay (1s, 2s, 4s)
      final delayMs = 1000 * (1 << (retries - 1));
      await Future.delayed(Duration(milliseconds: delayMs));
      
      try {
        err.requestOptions.extra['retries'] = retries;
        // Re-issue the exact same request
        final response = await dio.request(
          err.requestOptions.path,
          data: err.requestOptions.data,
          queryParameters: err.requestOptions.queryParameters,
          cancelToken: err.requestOptions.cancelToken,
          options: Options(
            method: err.requestOptions.method,
            headers: err.requestOptions.headers,
            extra: err.requestOptions.extra,
            responseType: err.requestOptions.responseType,
            contentType: err.requestOptions.contentType,
          ),
        );
        return handler.resolve(response);
      } catch (e) {
        return super.onError(e is DioException ? e : err, handler);
      }
    }
    return super.onError(err, handler);
  }
}

/// Provides a secure, initialized instance of Dio with interceptors attached to 
/// Riverpod's authProvider. Handles 401 Unauthorized globally by purging state.
final secureApiClientProvider = Provider<Dio>((ref) {
  var cleanedBase = backendBase.trim().replaceAll('..', '.');
  final normalizedBase = cleanedBase.endsWith('/') ? cleanedBase : '$cleanedBase/';

  if (kDebugMode) {
    debugPrint('🔒 Initializing SecureApiClient with Provider context');
  }

  final dio = Dio(
    BaseOptions(
      baseUrl: normalizedBase,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
    ),
  );

  bool isRefreshing = false;

  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) async {
        final path = options.path;
        final isAuthEndpoint = path.contains('auth/token') || path.contains('auth/otp');
        final authState = ref.read(authProvider);

        if (!isAuthEndpoint && authState.isSessionExpired) {
          final refreshToken = authState.refreshToken;
          if (refreshToken != null && refreshToken.isNotEmpty) {
            try {
              if (kDebugMode) {
                debugPrint('🔄 Proactively refreshing expired token before secure request: ${options.uri}');
              }
              final refreshResponse = await dio.post(
                'api/auth/token/refresh/',
                data: {'refresh_token': refreshToken},
              );
              final data = refreshResponse.data;
              if (data is Map<String, dynamic>) {
                final newSessionToken = data['session_token'] as String?;
                final newRefreshToken = data['refresh_token'] as String?;
                if (newSessionToken != null) {
                  await ref.read(authProvider.notifier).updateTokens(
                    session: newSessionToken,
                    refresh: newRefreshToken ?? refreshToken,
                  );
                }
              }
            } catch (_) {
              // Let request proceed; response interceptor will handle 401
            }
          }
        }

        // Fetch current snapshot of auth state synchronously 
        final freshAuthState = ref.read(authProvider);
        final token = freshAuthState.sessionToken;
        if (token != null && token.isNotEmpty) {
          options.headers['Authorization'] = 'Bearer $token';
        } else {
          final guestId = freshAuthState.guestId;
          if (guestId != null && guestId.isNotEmpty) {
            options.headers['X-Guest-ID'] = guestId;
          }
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
      onError: (DioException e, handler) async {
        if (kDebugMode) {
          debugPrint('❌ ${e.requestOptions.method} ${e.requestOptions.uri} -> ${e.message} [${e.response?.statusCode}]');
        }

        // 403 Forbidden: Permission Denied / Access Denied
        if (e.response?.statusCode == 403) {
          if (kDebugMode) {
            debugPrint('⛔ 403 Forbidden: ${e.requestOptions.uri}');
          }
          // Do NOT logout — 403 means permission denied,
          // not expired token. Token expiry returns 401.
          return handler.next(e);
        }

        // 401 Unauthorized: Expired token or deleted user -> Attempt Refresh
        if (e.response?.statusCode == 401 && !isRefreshing) {
          final authState = ref.read(authProvider);
          final refreshToken = authState.refreshToken;

          if (refreshToken != null && refreshToken.isNotEmpty) {
            isRefreshing = true;
            try {
              if (kDebugMode) debugPrint('🔄 401 intercepted. Attempting token refresh...');
              
              final refreshResponse = await dio.post(
                'api/auth/token/refresh/',
                data: {'refresh_token': refreshToken},
              );

              final data = refreshResponse.data;
              if (data is Map<String, dynamic>) {
                final newSessionToken = data['session_token'] as String?;
                final newRefreshToken = data['refresh_token'] as String?;

                if (newSessionToken != null) {
                  // Push new tokens to shared preferences and state
                  await ref.read(authProvider.notifier).updateTokens(
                    session: newSessionToken,
                    refresh: newRefreshToken,
                  );

                  // Retry original request with freshly minted token
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

                  isRefreshing = false;
                  return handler.resolve(retryResponse);
                }
              }
            } catch (refreshError) {
              if (kDebugMode) debugPrint('❌ Token refresh failed: $refreshError');
              // If the refresh token is also expired or invalid, set expired state and atom-bomb the session
              ref.read(sessionExpiredProvider.notifier).state = true;
              await ref.read(authProvider.notifier).logout();
            } finally {
              isRefreshing = false;
            }
          } else {
             // 401 but no refresh token available = hard logout
             ref.read(sessionExpiredProvider.notifier).state = true;
             await ref.read(authProvider.notifier).logout();
          }
        }
        
        // 500 Internal Server Error Global Interception
        if (e.response?.statusCode == 500) {
          debugPrint('🔥 CRITICAL 500 SERVER ERROR on ${e.requestOptions.path}');
          debugPrint('Data returned: ${e.response?.data}');
        }

        // 400 Bad Request Interception
        if (e.response?.statusCode == 400) {
          debugPrint('⚠️ BAD REQUEST 400 on ${e.requestOptions.path}');
          debugPrint('Validation/Error payload: ${e.response?.data}');
        }

        // Network / Timeout Error Interception
        if (e.type == DioExceptionType.connectionTimeout || 
            e.type == DioExceptionType.receiveTimeout || 
            e.type == DioExceptionType.connectionError) {
          debugPrint('🔌 NETWORK ERROR: ${e.type.toString()} - ${e.message}');
        }

        return handler.next(e);
      },
    ),
  );

  // Add the custom retry hook to automatically handle dropped network connections
  dio.interceptors.add(OfflineRetryInterceptor(dio: dio, maxRetries: 3));

  return dio;
});
