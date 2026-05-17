import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/admin_api.dart';

final adminApiProvider = Provider((ref) => AdminApi());

final activityLogsProvider = FutureProvider.family<List<dynamic>, ({String? actionType, int? userId})>((ref, params) async {
  final api = ref.watch(adminApiProvider);
  final response = await api.getActivityLogs(
    actionType: params.actionType,
    userId: params.userId,
  );
  if (response['error'] == false) {
    return response['data'] as List<dynamic>;
  } else {
    throw Exception(response['message'] ?? 'Failed to fetch logs');
  }
});
