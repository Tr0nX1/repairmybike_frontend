import 'package:flutter/foundation.dart';
import 'api_client.dart';
import 'app_state.dart';
import '../utils/phone_utils.dart';


class AuthApi {
  final Dio _dio;

  AuthApi() : _dio = ApiClient().dio;


  String _normalizePhone(String phone) => normalizePhoneNumber(phone);

  /// Staff login using username and password. Returns auth map.
  /// Expects backend endpoint `/api/auth/staff/login/password/`.
  Future<Map<String, dynamic>> loginStaff({
    required String username,
    required String password,
  }) async {
    try {
      final res = await _dio.post(
        'api/auth/staff/login/password/',
        data: {
          'identifier': username, 
          'password': password,
          'device_id': AppState.deviceId,
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
    final normalized = _normalizePhone(phone);
    DioException? lastErr;
    for (var attempt = 0; attempt < 2; attempt++) {
      try {
        await _dio.post(
          'api/auth/otp/request/',
          data: {
            'identifier': normalized, 
            'method': 'phone',
            'device_id': AppState.deviceId,
          },
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
      final payload = {
        'identifier': normalized, 
        'otp_code': code, 
        'method': 'phone',
        'device_id': AppState.deviceId,
      };

      debugPrint('=== API CALL DEBUG ===');
      debugPrint('Endpoint: api/auth/otp/verify/');
      debugPrint('Payload: $payload');

      final res = await _dio.post(
        'api/auth/otp/verify/',
        data: payload,
      );

      debugPrint('=== RESPONSE DEBUG ===');
      debugPrint('Status: ${res.statusCode}');
      debugPrint('Body: ${res.data}');

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
      debugPrint('=== ERROR DEBUG ===');
      debugPrint('Error type: ${e.runtimeType}');
      debugPrint('Error: $e');
      
      debugPrint('DioError type: ${e.type}');
      debugPrint('Response status: ${e.response?.statusCode}');
      debugPrint('Response body: ${e.response?.data}');
      
      final data = e.response?.data;
      String msg = 'OTP verification failed';
      if (data is Map) {
        if (data['message'] is String && data['message'].isNotEmpty) {
          msg = data['message'] as String;
        } else if (data['details'] is String && data['details'].contains('errorDescription')) {
           // Fallback to extract from details string if needed
           msg = data['details'].toString();
        } else if (data['error'] is String && data['error'].isNotEmpty) {
          msg = data['error'] as String;
        }
      } else if (data['string'] is String && (data['string'] as String).isNotEmpty) {
        msg = data['string'];
      }
      throw Exception(msg);
    }
  }

  Future<void> logout({String? refreshToken, String? sessionToken}) async {
    await _dio.post(
      'api/auth/logout/',
      data: refreshToken != null ? {'refresh_token': refreshToken} : {},
    );
  }

  Future<Map<String, dynamic>> refreshToken({required String refreshToken}) async {
    try {
      final res = await _dio.post(
        'api/auth/token/refresh/',
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
    final res = await _dio.get('api/auth/profile/');

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
    int? defaultVehicle,
  }) async {
    final payload = <String, dynamic>{};
    if (firstName != null) payload['first_name'] = firstName;
    if (lastName != null) payload['last_name'] = lastName;
    if (phoneNumber != null) payload['phone_number'] = phoneNumber;
    if (profilePicture != null) payload['profile_picture'] = profilePicture;
    if (email != null) payload['email'] = email;
    if (defaultVehicle != null) payload['default_vehicle'] = defaultVehicle;
    final res = await _dio.patch(
      'api/auth/profile/',
      data: payload,
    );
    final data = res.data;
    if (data is Map<String, dynamic>) return data;
    throw Exception('Unexpected response shape for update profile');
  }

  /// Upload a profile photo.
  Future<Map<String, dynamic>> uploadProfilePhoto({
    required String filePath,
  }) async {
    final formData = FormData.fromMap({
      'profile_picture': await MultipartFile.fromFile(filePath),
    });

    try {
      final res = await _dio.post(
        '/api/auth/profile/upload-photo/',
        data: formData,
        options: Options(
          headers: {'Content-Type': 'multipart/form-data'},
        ),
      );
      if (res.data?['error'] == true) {
        throw Exception(res.data?['message'] ?? 'Upload failed');
      }
      return res.data;
    } on DioException catch (e) {
      throw Exception('Photo upload failed: ${e.response?.statusCode}');
    }
  }

  Future<Map<String, dynamic>> addAddress({
    required String sessionToken,
    required String fullName,
    required String phone,
    required String flat,
    required String area,
    String? landmark,
    required String pincode,
    required String city,
    required String state,
    bool isDefault = true,
    String? instructions,
  }) async {
    final res = await _dio.post(
      'api/auth/addresses/',
      data: {
        'full_name': fullName,
        'phone_number': phone,
        'flat_house_no': flat,
        'area_street': area,
        'landmark': landmark,
        'pincode': pincode,
        'town_city': city,
        'state': state,
        'is_default': isDefault,
        'delivery_instructions': instructions,
      },
    );
    return res.data;
  }

  Future<void> deleteAddress(int id, {required String sessionToken}) async {
    await _dio.delete('api/auth/addresses/$id/');
  }
}
