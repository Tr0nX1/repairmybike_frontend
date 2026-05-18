import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../network/secure_api_client.dart';
// ignore: depend_on_referenced_packages
import '../app_state.dart' as legacy;

class UserProfile {
  final String fullName;
  final String? email;
  final String? avatarUrl;
  final List<Map<String, dynamic>> addresses;
  final Map<String, dynamic>? defaultVehicle;

  UserProfile({
    required this.fullName,
    this.email,
    this.avatarUrl,
    required this.addresses,
    this.defaultVehicle,
  });

  Map<String, dynamic>? get defaultAddress {
    if (addresses.isEmpty) return null;
    return addresses.firstWhere(
      (a) => a['is_default'] == true,
      orElse: () => addresses.first,
    );
  }
}

class ProfileNotifier extends AsyncNotifier<UserProfile?> {
  @override
  FutureOr<UserProfile?> build() {
    return null;
  }

  Future<void> fetchProfile() async {
    state = const AsyncValue.loading();
    try {
      final dio = ref.read(secureApiClientProvider);
      
      final res = await dio.get('api/auth/profile/');
      final data = res.data;
      
      if (data is Map<String, dynamic>) {
        final profile = UserProfile(
          fullName: "${data['first_name'] ?? ''} ${data['last_name'] ?? ''}".trim().isNotEmpty
              ? "${data['first_name'] ?? ''} ${data['last_name'] ?? ''}".trim()
              : data['username']?.toString() ?? 'User',
          email: data['email']?.toString(),
          avatarUrl: data['profile_picture']?.toString(),
          addresses: (data['addresses'] as List<dynamic>?)
                  ?.whereType<Map<String, dynamic>>()
                  .map((e) => Map<String, dynamic>.from(e))
                  .toList() ?? [],
          defaultVehicle: data['default_vehicle'] is Map ? Map<String, dynamic>.from(data['default_vehicle']) : null,
        );
        
        state = AsyncValue.data(profile);

        // SYNC BACKWARDS TO LEGACY APPSTATE 
        await legacy.AppState.updateFromProfileMap(data);
      } else {
        state = AsyncValue.error('Invalid profile data payload from server', StackTrace.current);
      }
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> clearProfile() async {
    state = const AsyncValue.data(null);
  }
}

/// A global provider to access or refresh user profile data securely.
final profileProvider = AsyncNotifierProvider<ProfileNotifier, UserProfile?>(ProfileNotifier.new);
