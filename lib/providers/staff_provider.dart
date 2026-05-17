import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/staff_api.dart';

final staffApiProvider = Provider((ref) => StaffApi());

final staffBookingsProvider = FutureProvider.family<List<dynamic>, String?>((ref, status) async {
  final api = ref.watch(staffApiProvider);
  final response = await api.getBookings(status: status);
  if (response['error'] == false) {
    return response['data'] as List<dynamic>;
  } else {
    throw Exception(response['message'] ?? 'Failed to fetch bookings');
  }
});

final staffStatsProvider = FutureProvider((ref) async {
  final api = ref.watch(staffApiProvider);
  final response = await api.getStats();
  if (response['error'] == false) {
    return response['data'] as Map<String, dynamic>;
  } else {
    throw Exception(response['message'] ?? 'Failed to fetch statistics');
  }
});

final pendingReconciliationsProvider = FutureProvider((ref) async {
  final api = ref.watch(staffApiProvider);
  final response = await api.getPendingReconciliations();
  if (response['error'] == false) {
    return response['data'] as List<dynamic>;
  } else {
    throw Exception(response['message'] ?? 'Failed to fetch reconciliations');
  }
});
