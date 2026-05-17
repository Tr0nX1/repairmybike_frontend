import 'api_client.dart';
import 'package:dio/dio.dart';

class StaffApi {
  final ApiClient _client = ApiClient();

  /// Fetch bookings with optional status filter
  /// Used by Mechanic (status=confirmed/in_progress) and Staff (all statuses)
  Future<Map<String, dynamic>> getBookings({String? status, String? date, String? search}) async {
    try {
      final response = await _client.dio.get(
        'api/staff/bookings/',
        queryParameters: {
          if (status != null) 'status': status,
          if (date != null) 'date': date,
          if (search != null) 'search': search,
        },
      );
      return response.data;
    } catch (e) {
      rethrow;
    }
  }

  /// Update booking status
  /// Body: { "status": "confirmed" | "in_progress" | "completed" | "cancelled" }
  Future<Map<String, dynamic>> updateBookingStatus(int bookingId, String status) async {
    try {
      final response = await _client.dio.patch(
        'api/staff/bookings/$bookingId/update-status/',
        data: {'status': status},
      );
      return response.data;
    } catch (e) {
      rethrow;
    }
  }

  /// Get aggregate statistics for staff/admin
  Future<Map<String, dynamic>> getStats() async {
    try {
      final response = await _client.dio.get('api/staff/bookings/stats/');
      return response.data;
    } catch (e) {
      rethrow;
    }
  }

  /// Create a new booking (Walk-in)
  Future<Map<String, dynamic>> createBooking(Map<String, dynamic> bookingData) async {
    try {
      final response = await _client.dio.post('api/bookings/', data: bookingData);
      return response.data;
    } catch (e) {
      rethrow;
    }
  }

  /// Cash Handling: Mark booking as paid in cash and collected by staff
  Future<Map<String, dynamic>> collectCash(int bookingId, double amount) async {
    try {
      final response = await _client.dio.post(
        'api/staff/payments/collect/',
        data: {'booking_id': bookingId, 'amount': amount},
      );
      return response.data;
    } catch (e) {
      rethrow;
    }
  }

  /// Cash Handling: Verify cash received from another staff member (Handover)
  Future<Map<String, dynamic>> verifyCash(int paymentId) async {
    try {
      final response = await _client.dio.post(
        'api/staff/payments/$paymentId/verify/',
      );
      return response.data;
    } catch (e) {
      rethrow;
    }
  }

  /// Fetch payments pending reconciliation
  Future<Map<String, dynamic>> getPendingReconciliations() async {
    try {
      final response = await _client.dio.get('api/staff/payments/pending-reconciliation/');
      return response.data;
    } catch (e) {
      rethrow;
    }
  }

  /// Add a spare part to a booking
  Future<Map<String, dynamic>> addPartToBooking(int bookingId, int partId, int quantity) async {
    try {
      final response = await _client.dio.post(
        'api/staff/bookings/$bookingId/add-part/',
        data: {'part_id': partId, 'quantity': quantity},
      );
      return response.data;
    } catch (e) {
      rethrow;
    }
  }

  /// Remove a spare part from a booking
  Future<Map<String, dynamic>> removePartFromBooking(int bookingId, int bookingPartId) async {
    try {
      final response = await _client.dio.post(
        'api/staff/bookings/$bookingId/remove-part/',
        data: {'booking_part_id': bookingPartId},
      );
      return response.data;
    } catch (e) {
      rethrow;
    }
  }

  /// --- Cash Session Management ---
  
  Future<Map<String, dynamic>> getCurrentCashSession() async {
    try {
      final res = await _client.dio.get('api/staff/cash-sessions/current/');
      return res.data;
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> startCashSession(double openingBalance) async {
    try {
      final res = await _client.dio.post(
        'api/staff/cash-sessions/start/',
        data: {'opening_balance': openingBalance},
      );
      return res.data;
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> closeCashSession(int sessionId, double closingBalance) async {
    try {
      final res = await _client.dio.post(
        'api/staff/cash-sessions/$sessionId/close/',
        data: {'closing_balance': closingBalance},
      );
      return res.data;
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getCashMovements(int sessionId) async {
    try {
      final res = await _client.dio.get('api/staff/cash-sessions/$sessionId/movements/');
      return res.data;
    } catch (e) {
      rethrow;
    }
  }
}
