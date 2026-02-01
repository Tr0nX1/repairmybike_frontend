import 'api_client.dart';

class ContactApi {
  final Dio _dio;

  ContactApi() : _dio = ApiClient().dio;

  Future<Map<String, dynamic>> submitContactForm({
    required String name,
    required String email,
    required String phone,
    required String message,
  }) async {
    final payload = {
      'name': name,
      'email': email,
      'phone': phone,
      'message': message,
    };

    final response = await _dio.post(
      'api/accounts/contact/',
      data: payload,
    );

    final body = response.data;
    if (body is Map<String, dynamic>) {
      final error = body['error'] == true;
      if (error) {
        throw Exception(body['message'] ?? 'Failed to send message');
      }
      return body;
    }
    
    throw Exception('Unexpected response from contact endpoint');
  }
}
