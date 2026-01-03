import 'package:dio/dio.dart';
import '../utils/api_config.dart';

class AuthApi {
  final Dio _dio;

  AuthApi()
    : _dio = Dio(
        BaseOptions(
          baseUrl: backendBase,
          connectTimeout: const Duration(seconds: 20),
          receiveTimeout: const Duration(seconds: 30),
          sendTimeout: const Duration(seconds: 20),
        ),
      );

  String _normalizePhone(String phone) {
    final raw = phone.trim();
    // Strip all non-digits and rebuild E.164 with leading '+'
    final digits = raw.replaceAll(RegExp(r'\D'), '');
    if (digits.isEmpty) return raw;
    // Assume India by default for 10-digit inputs
    if (digits.length == 10) return '+91$digits';
    return '+$digits';
  }

  /// Staff login using username and password. Returns auth map.
  /// Expects backend endpoint `/api/auth/staff/login/password/`.
  Future<Map<String, dynamic>> loginStaff({
    required String username,
    required String password,
  }) async {
    try {
      final res = await _dio.post(
        '/api/auth/staff/login/password/',
        data: {'identifier': username, 'password': password},
      );
      final data = res.data;
      if (data is Map<String, dynamic>) {
        final error = data['error'] == true;
        if (error) {
          throw Exception(data['message'] ?? 'Staff login failed');
        }
        return data;
      }
      throw Exception('Unexpected response shape for staff login');
    } on DioException catch (e) {
      final data = e.response?.data;
      String msg = 'Staff login failed';
      if (data is Map && data['message'] is String) {
        msg = data['message'] as String;
      } else if (data is String && data.isNotEmpty) {
        msg = data;
      }
      throw Exception(msg);
    }
  }

  Future<void> requestOtpPhone(String phone) async {
    final normalized = _normalizePhone(phone);
    DioException? lastErr;
    for (var attempt = 0; attempt < 2; attempt++) {
      try {
        await _dio.post(
          '/api/auth/otp/request/',
          data: {'identifier': normalized, 'method': 'phone'},
        );
        return;
      } on DioException catch (e) {
        lastErr = e;
        if (attempt == 0 &&
            (e.type == DioExceptionType.connectionTimeout ||
                e.type == DioExceptionType.sendTimeout ||
                e.type == DioExceptionType.receiveTimeout)) {
          await Future.delayed(const Duration(seconds: 1));
          continue;
        }
        break;
      }
    }
    final e = lastErr;
    final data = e?.response?.data;
    String msg = 'Failed to send OTP';
    if (data is Map && data['message'] is String) {
      msg = data['message'] as String;
    } else if (data is Map && data['error'] is String) {
      msg = data['error'] as String;
    } else if (data is String && data.isNotEmpty) {
      msg = data;
    }
    assert(() {
      // ignore: avoid_print
      print(
        'OTP request error: ${e?.response?.statusCode} ${e?.message} -> $data',
      );
      return true;
    }());
    throw Exception(msg);
  }

  Future<Map<String, dynamic>> verifyOtpPhone({
    required String phone,
    required String code,
  }) async {
    try {
      final normalized = _normalizePhone(phone);
      final res = await _dio.post(
        '/api/auth/otp/verify/',
        data: {'identifier': normalized, 'otp_code': code, 'method': 'phone'},
      );
      final data = res.data;
      if (data is Map<String, dynamic>) {
        final error = data['error'] == true;
        if (error) {
          throw Exception(data['message'] ?? 'OTP verification failed');
        }
        return data;
      }
      throw Exception('Unexpected response shape for verify OTP');
    } on DioException catch (e) {
      final data = e.response?.data;
      String msg = 'OTP verification failed';
      if (data is Map && data['message'] is String) {
        msg = data['message'] as String;
      } else if (data is Map && data['error'] is String) {
        msg = data['error'] as String;
      } else if (data is String && data.isNotEmpty) {
        msg = data;
      }
      throw Exception(msg);
    }
  }

  Future<void> logout({String? refreshToken, String? sessionToken}) async {
    await _dio.post(
      '/api/auth/logout/',
      data: refreshToken != null ? {'refresh_token': refreshToken} : {},
      options: sessionToken != null
          ? Options(headers: {'Authorization': 'Bearer $sessionToken'})
          : null,
    );
  }

  Future<Map<String, dynamic>> refreshToken({required String refreshToken}) async {
    try {
      final res = await _dio.post(
        '/api/auth/token/refresh/',
        data: {'refresh_token': refreshToken},
      );
      final data = res.data;
      if (data is Map<String, dynamic>) {
        return data; // {session_token, refresh_token?}
      }
      throw Exception('Unexpected refresh response');
    } on DioException catch (e) {
      throw Exception('Token refresh failed: ${e.message}');
    }
  }

  Future<Map<String, dynamic>> getProfile({
    required String sessionToken,
  }) async {
    final res = await _dio.get(
      '/api/auth/profile/',
      options: Options(headers: {'Authorization': 'Bearer $sessionToken'}),
    );
    final data = res.data;
    if (data is Map<String, dynamic>) return data;
    throw Exception('Unexpected response shape for profile');
  }

  Future<Map<String, dynamic>> updateProfile({
    required String sessionToken,
    String? firstName,
    String? lastName,
    String? phoneNumber,
    String? profilePicture,
    String? email,
  }) async {
    final payload = <String, dynamic>{};
    if (firstName != null) payload['first_name'] = firstName;
    if (lastName != null) payload['last_name'] = lastName;
    if (phoneNumber != null) payload['phone_number'] = phoneNumber;
    if (profilePicture != null) payload['profile_picture'] = profilePicture;
    if (email != null) payload['email'] = email;
    final res = await _dio.patch(
      '/api/auth/profile/',
      data: payload,
      options: Options(headers: {'Authorization': 'Bearer $sessionToken'}),
    );
    final data = res.data;
    if (data is Map<String, dynamic>) return data;
    throw Exception('Unexpected response shape for update profile');
  }
}
