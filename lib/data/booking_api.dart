import 'package:dio/dio.dart';
import 'api_client.dart';


class BookingApi {
  final Dio _dio;

  BookingApi() : _dio = ApiClient().dio;


  /// Create a booking using cash payment only.
  ///
  /// Required params follow backend contract.
  /// For now `payment_method` is hardcoded to `cash`.
  ///
  /// Later when integrating a payment gateway (e.g., Razorpay),
  /// you can:
  /// 1) Create an order after booking is created (or before, depending on flow)
  ///    via `/api/payments/razorpay/create-order` with `{ booking_id }`.
  /// 2) After client-side payment, verify via `/api/payments/razorpay/verify`
  ///    posting `{ razorpay_order_id, razorpay_payment_id, razorpay_signature }`.
  Future<Map<String, dynamic>> createBooking({
    required String customerName,
    required String customerPhone,
    String? customerEmail,
    required int vehicleModelId,
    required List<int> serviceIds,
    required String serviceLocation, // 'home' | 'shop'
    String? address,
    required String appointmentDate, // YYYY-MM-DD
    required String appointmentTime, // HH:MM:SS
    String? notes,
  }) async {
    final payload = {
      'customer_name': customerName,
      'customer_phone': customerPhone,
      if (customerEmail != null && customerEmail.isNotEmpty)
        'customer_email': customerEmail,
      'vehicle_model_id': vehicleModelId,
      'service_ids': serviceIds,
      'service_location': serviceLocation,
      if (address != null) 'address': address,
      'appointment_date': appointmentDate,
      'appointment_time': appointmentTime,
      // Cash only for now
      'payment_method': 'cash',
      if (notes != null && notes.isNotEmpty) 'notes': notes,
    };

    try {
      final res = await _dio.post('api/bookings/bookings/', data: payload);
      final body = res.data;
      if (body is Map<String, dynamic>) {
        final error = body['error'] == true;
        if (error) {
          throw Exception(body['message'] ?? 'Failed to create booking');
        }
        final data = body['data'];
        if (data is Map<String, dynamic>) {
          return data;
        }
      }
      throw Exception('Unexpected response shape for booking');
    } on DioException catch (e) {
      // Extract meaningful server-provided message when available
      final code = e.response?.statusCode ?? 0;
      final data = e.response?.data;
      if (data is Map<String, dynamic>) {
        if (data['message'] is String) {
          throw Exception(data['message'] as String);
        }
        // Our backend now returns { error, message, details } for validation
        if (data['details'] is Map) {
          final details = data['details'] as Map;
          final parts = <String>[];
          details.forEach((k, v) {
            if (v is List && v.isNotEmpty) {
              parts.add('$k: ${v.first}');
            } else if (v is String) {
              parts.add('$k: $v');
            }
          });
          if (parts.isNotEmpty) {
            throw Exception(parts.join('\n'));
          }
        }
        // DRF default field errors shape { field: ["msg"] }
        final parts = <String>[];
        data.forEach((k, v) {
          if (v is List && v.isNotEmpty) {
            parts.add('$k: ${v.first}');
          } else if (v is String) {
            parts.add('$k: $v');
          }
        });
        if (parts.isNotEmpty) {
          throw Exception(parts.join('\n'));
        }
      }
      throw Exception('Failed to create booking: HTTP $code');
    }
  }

  /// List bookings for the authenticated user.
  /// Returns a list of booking summary maps per backend list serializer.
  Future<List<Map<String, dynamic>>> getBookings() async {
    try {
      final res = await _dio.get(
        'api/bookings/bookings/',
      );
      final body = res.data;
      // Accept plain list or wrapped map {data: [...]}
      if (body is List) {
        return body.whereType<Map<String, dynamic>>().map((e) => e).toList();
      }
      if (body is Map<String, dynamic>) {
        final error = body['error'] == true;
        if (error) {
          throw Exception(body['message'] ?? 'Failed to fetch bookings');
        }
        final data = body['data'] ?? body['results'];
        if (data is List) {
          return data.whereType<Map<String, dynamic>>().map((e) => e).toList();
        }
      }
      throw Exception('Unexpected response shape for bookings list');
    } on DioException catch (e) {
      final code = e.response?.statusCode ?? 0;
      if (code == 429) {
        // Friendlier message for DRF throttling
        throw Exception(
          'Too many requests (429). Please wait a minute and try again.',
        );
      }
      // Bubble up original server message when available
      final data = e.response?.data;
      if (data is Map && data['message'] is String) {
        throw Exception(data['message'] as String);
      }
      throw Exception('Failed to fetch bookings: HTTP $code');
    }
  }

  /// Update booking schedule (date/time). Returns updated booking map.
  Future<Map<String, dynamic>> updateBookingSchedule({
    required int bookingId,
    required String appointmentDate, // YYYY-MM-DD
    required String appointmentTime, // HH:MM:SS
  }) async {
    final payload = {
      'appointment_date': appointmentDate,
      'appointment_time': appointmentTime,
    };
    final res = await _dio.patch(
      'api/bookings/bookings/$bookingId/',
      data: payload,
    );
    final body = res.data;
    if (body is Map<String, dynamic>) {
      final error = body['error'] == true;
      if (error) {
        throw Exception(body['message'] ?? 'Failed to update schedule');
      }
      final data = body['data'];
      if (data is Map<String, dynamic>) {
        return data;
      }
    }
    throw Exception('Unexpected response shape for update schedule');
  }

  /// Staff-only: update booking status via staff endpoint.
  /// Accepted statuses: pending, confirmed, in_progress, completed, cancelled.
  Future<Map<String, dynamic>> staffUpdateStatus({
    required int bookingId,
    required String status,
    required String sessionToken,
  }) async {
    final payload = {'status': status};
    final res = await _dio.patch(
      'api/staff/bookings/$bookingId/update-status/',
      data: payload,
    );
    final body = res.data;
    if (body is Map<String, dynamic>) {
      final error = body['error'] == true;
      if (error) {
        throw Exception(body['message'] ?? 'Failed to update status');
      }
      final data = body['data'];
      if (data is Map<String, dynamic>) {
        return data;
      }
    }
    throw Exception('Unexpected response shape for update status');
  }
}
