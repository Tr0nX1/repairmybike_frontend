import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/notifications_api.dart';
import '../models/notification.dart';
import '../data/repositories/auth_repository.dart';

final notificationsProvider = FutureProvider.autoDispose<List<NotificationItem>>((ref) async {
  final authState = ref.watch(authProvider);
  if (!authState.isAuthenticated) {
    return [];
  }
  final api = ref.read(notificationsApiProvider);
  return api.getNotifications();
});

final unreadNotificationsCountProvider = FutureProvider.autoDispose<int>((ref) async {
  final authState = ref.watch(authProvider);
  if (!authState.isAuthenticated) {
    return 0;
  }
  try {
    final notes = await ref.watch(notificationsProvider.future);
    return notes.where((n) => !n.isRead).length;
  } catch (_) {
    return 0;
  }
});

final markNotificationReadProvider = FutureProvider.family<void, int>((ref, id) async {
  final authState = ref.read(authProvider);
  if (!authState.isAuthenticated) return;
  final api = ref.read(notificationsApiProvider);
  await api.markAsRead(id);
  ref.invalidate(notificationsProvider);
});

final markAllNotificationsReadProvider = FutureProvider.autoDispose<void>((ref) async {
  final authState = ref.read(authProvider);
  if (!authState.isAuthenticated) return;
  final api = ref.read(notificationsApiProvider);
  await api.markAllRead();
  ref.invalidate(notificationsProvider);
});

