import 'package:dio/dio.dart';
import '../utils/api_config.dart';

class AuthApi {
  final Dio _dio;

  AuthApi()
      : _dio = Dio(
          BaseOptions(
            baseUrl: backendBase,
            connectTimeout: const Duration(seconds: 10),
            receiveTimeout: const Duration(seconds: 15),
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
        data: {
          'identifier': username,
          'password': password,
        },
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
    try {
      final normalized = _normalizePhone(phone);
      await _dio.post(
        '/api/auth/otp/request/',
        data: {
          // Backend UnifiedOTPRequestSerializer expects only these fields
          'identifier': normalized,
          'method': 'phone',
        },
      );
    } on DioException catch (e) {
      final data = e.response?.data;
      String msg = 'Failed to send OTP';
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

  Future<Map<String, dynamic>> verifyOtpPhone({
    required String phone,
    required String code,
  }) async {
    try {
      final normalized = _normalizePhone(phone);
      final res = await _dio.post(
        '/api/auth/otp/verify/',
        data: {
          // Backend UnifiedOTPVerifySerializer expects only these fields
          'identifier': normalized,
          'otp_code': code,
          'method': 'phone',
        },
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
}
