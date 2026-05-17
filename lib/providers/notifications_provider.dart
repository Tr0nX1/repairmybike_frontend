import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/notifications_api.dart';
import '../models/notification.dart';

final notificationsProvider = FutureProvider.autoDispose<List<NotificationItem>>((ref) async {
  final api = ref.read(notificationsApiProvider);
  return api.getNotifications();
});

final unreadNotificationsCountProvider = FutureProvider.autoDispose<int>((ref) async {
  final notes = await ref.watch(notificationsProvider.future);
  return notes.where((n) => !n.isRead).length;
});

final markNotificationReadProvider = FutureProvider.family<void, int>((ref, id) async {
  final api = ref.read(notificationsApiProvider);
  await api.markAsRead(id);
  ref.invalidate(notificationsProvider);
});

final markAllNotificationsReadProvider = FutureProvider.autoDispose<void>((ref) async {
  final api = ref.read(notificationsApiProvider);
  await api.markAllRead();
  ref.invalidate(notificationsProvider);
});
