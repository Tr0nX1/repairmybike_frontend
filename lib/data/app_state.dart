import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'auth_api.dart';
import 'vehicles_api.dart';
import 'saved_services_api.dart';

class AppState {
  // Keys for persistence
  static const _kPhone = 'phoneNumber';
  static const _kIsStaff = 'isStaff';
  static const _kUsername = 'staffUsername';
  static const _kAvatarUrl = 'avatarUrl';
  static const _kLastCustomerPhone = 'lastCustomerPhone';
  static const _kLikedServices = 'likedServices';
  static const _kFeedbackPrefix = 'feedback_service_';
  static const _kPendingAction = 'pending_action';
  
  // Offline cache keys
  static const _kCachedBookings = 'cached_bookings_v1';
  static const _kCachedOrders = 'cached_orders_v1';
  static const _kLastSyncBookings = 'last_sync_bookings';
  static const _kLastSyncOrders = 'last_sync_orders';

  // Token keys (stored in SharedPreferences for Windows compatibility)
  static const _kSession = 'session_token';
  static const _kRefresh = 'refresh_token';


  static String? lastCustomerPhone;
  static Set<int> likedServiceIds = <int>{};

  static String normalizePhone(String p) {
    var s = p.trim().replaceAll(RegExp('\\D'), '');
    if (s.isEmpty) return '';
    if (s.length == 10) return '+91' + s;
    if (s.length == 12 && s.startsWith('91')) return '+' + s;
    if (s.startsWith('0') && s.length == 11) return '+91' + s.substring(1);
    if (p.trim().startsWith('+')) return p.trim();
    return '+' + s;
  }

  // Auth state
  static String? phoneNumber;
  static String? sessionToken;
  static String? refreshToken;
  static bool isStaff = false;
  static String? staffUsername;

  // Onboarding/profile details
  static String? vehicleType; // 'scooter' or 'motorcycle'
  static String? vehicleBrand; // e.g., 'Honda', 'Yamaha', 'TVS'
  static String? vehicleName; // e.g., 'Activa 6G', 'FZ-S V3'
  static int? vehicleModelId; // Backend ID for vehicle model
  static String? fullName;
  static String? address;
  static String? email;
  static String? avatarUrl; // Owner photo URL

  static bool get isAuthenticated =>
      sessionToken != null && sessionToken!.isNotEmpty;
  static bool get isCustomerAuthenticated => isAuthenticated && !isStaff;
  static bool get isStaffAuthenticated => isAuthenticated && isStaff;

  static int? _jwtExpEpoch(String? jwt) {
    try {
      if (jwt == null || jwt.isEmpty) return null;
      final parts = jwt.split('.');
      if (parts.length < 2) return null;
      String norm(String s) =>
          s.padRight(s.length + (4 - s.length % 4) % 4, '=');
      final payload = utf8.decode(base64Url.decode(norm(parts[1])));
      final map = jsonDecode(payload);
      if (map is Map && map['exp'] is num) return (map['exp'] as num).toInt();
    } catch (_) {}
    return null;
  }

  static bool get isSessionExpired {
    final exp = _jwtExpEpoch(sessionToken);
    if (exp == null) return false;
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    return now >= exp;
  }


  // Initialize from SharedPreferences and SecureStorage
  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Read non-sensitive from Prefs
    phoneNumber = prefs.getString(_kPhone);
    isStaff = prefs.getBool(_kIsStaff) ?? false;
    staffUsername = prefs.getString(_kUsername);
    avatarUrl = prefs.getString(_kAvatarUrl);
    lastCustomerPhone = prefs.getString(_kLastCustomerPhone);

    // Read sensitive from SharedPreferences
    sessionToken = prefs.getString(_kSession);
    refreshToken = prefs.getString(_kRefresh);

    if (isSessionExpired) {
      // Attempt to refresh token
      bool refreshed = false;
      if (refreshToken != null && refreshToken!.isNotEmpty) {
        try {
          final res = await AuthApi().refreshToken(refreshToken: refreshToken!);
          final newSession = res['session_token'] as String?;
          final newRefresh = res['refresh_token'] as String?;
          if (newSession != null) {
            sessionToken = newSession;
            await prefs.setString(_kSession, newSession);
            if (newRefresh != null) {
              refreshToken = newRefresh;
              await prefs.setString(_kRefresh, newRefresh);
            }
            refreshed = true;
            print('Session refreshed successfully');
          }
        } catch (e) {
          print('Session refresh failed: $e');
        }
      }

      if (!refreshed) {
        sessionToken = null;
        refreshToken = null;
        await prefs.remove(_kSession);
        await prefs.remove(_kRefresh);
      }
    }

    // Initialize profile fields as null (fetch from API later for fresh "Truth")
    fullName = null;
    address = null;
    email = null;
    vehicleType = null;
    vehicleBrand = null;
    vehicleName = null;
    vehicleModelId = null;

    // Initial sync for saved services
    if (isAuthenticated) {
      await syncSavedServices();
    } else {
      // Load local likes if not auth or fallback
      final likedRaw = prefs.getStringList(_kLikedServices) ?? const [];
      likedServiceIds = likedRaw.map((e) => int.tryParse(e)).whereType<int>().toSet();
    }
  }

  static Future<void> setAuth({
    required String phone,
    required String session,
    required String refresh,
  }) async {
    final nPhone = normalizePhone(phone);
    phoneNumber = nPhone;
    sessionToken = session;
    refreshToken = refresh;
    isStaff = false;
    staffUsername = null;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kPhone, nPhone);
    await prefs.setBool(_kIsStaff, false);
    await prefs.remove(_kUsername);

    await prefs.setString(_kSession, session);
    await prefs.setString(_kRefresh, refresh);
    
    print('Auth set for ' + nPhone);
  }

  static Future<void> clearAuth() async {
    phoneNumber = null;
    sessionToken = null;
    refreshToken = null;
    isStaff = false;
    staffUsername = null;
    fullName = null;
    address = null;
    email = null;
    vehicleType = null;
    vehicleBrand = null;
    vehicleName = null;
    vehicleModelId = null;
    lastCustomerPhone = null;

    // Clear in-memory likes
    likedServiceIds.clear();

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kPhone);
    await prefs.remove(_kIsStaff);
    await prefs.remove(_kUsername);
    await prefs.remove(_kLastCustomerPhone);
    await prefs.remove(_kLikedServices);
    await prefs.remove(_kAvatarUrl);

    await prefs.remove(_kSession);
    await prefs.remove(_kRefresh);

    // Clear cart data (keys defined in cart_provider.dart)
    await prefs.remove('cart_json_v1');
    await prefs.remove('session_id_v1');

    // Clear offline caches to prevent data leakage
    await prefs.remove(_kCachedBookings);
    await prefs.remove(_kCachedOrders);
    await prefs.remove(_kLastSyncBookings);
    await prefs.remove(_kLastSyncOrders);
  }

  // Staff auth: username/password based session.
  static Future<void> setStaffAuth({
    required String username,
    required String session,
    String? refresh,
  }) async {
    staffUsername = username;
    sessionToken = session;
    refreshToken = refresh;
    phoneNumber = null;
    isStaff = true;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kIsStaff, true);
    await prefs.setString(_kUsername, username);
    await prefs.remove(_kPhone);

    await prefs.setString(_kSession, session);
    if (refresh != null && refresh.isNotEmpty) {
      await prefs.setString(_kRefresh, refresh);
    } else {
      await prefs.remove(_kRefresh);
    }
  }


  static Future<void> setVehicleType(String type) async {
    vehicleType = type;
  }

  static Future<void> setVehicleBrand(String brand) async {
    vehicleBrand = brand;
  }

  static Future<void> setVehicle({
    required String name,
    int? modelId,
    bool syncToBackend = true,
  }) async {
    vehicleName = name;
    vehicleModelId = modelId;

    // Sync to backend if authenticated and requested
    if (syncToBackend &&
        isAuthenticated &&
        sessionToken != null &&
        modelId != null) {
      try {
        await VehiclesApi().addUserVehicle(
          sessionToken: sessionToken!,
          vehicleModelId: modelId,
        );
      } catch (e) {
        print('Failed to sync vehicle to backend: $e');
      }
    }
  }

  static Future<void> setVehicleName(String name) async {
    await setVehicle(name: name);
  }

  static Future<void> setProfile({
    String? name,
    String? addr,
    String? mail,
  }) async {
    fullName = name ?? fullName;
    address = addr ?? address;
    email = mail ?? email;

    // Sync to backend if authenticated
    if (isAuthenticated && sessionToken != null) {
      try {
        String? first;
        String? last;
        if (name != null) {
          final parts = name.trim().split(' ');
          if (parts.isNotEmpty) {
            first = parts.first;
            if (parts.length > 1) {
              last = parts.sublist(1).join(' ');
            }
          }
        }
        await AuthApi().updateProfile(
          sessionToken: sessionToken!,
          firstName: first,
          lastName: last,
          email: mail,
        );
      } catch (e) {
        print('Failed to sync profile to backend: $e');
      }
    }
  }

  static Future<void> setAvatarUrl(String? url) async {
    avatarUrl = url;
    final prefs = await SharedPreferences.getInstance();
    if (url == null || url.isEmpty) {
      await prefs.remove(_kAvatarUrl);
    } else {
      await prefs.setString(_kAvatarUrl, url);
    }
  }

  static Future<void> setLastCustomerPhone(String? phone) async {
    final cp = phone == null ? '' : normalizePhone(phone);
    lastCustomerPhone = cp.isEmpty ? null : cp;
    final prefs = await SharedPreferences.getInstance();
    if (cp.isEmpty) {
      await prefs.remove(_kLastCustomerPhone);
    } else {
      await prefs.setString(_kLastCustomerPhone, cp);
      print('Last customer phone set to ' + cp);
    }
  }

  // Likes API
  static bool isServiceLiked(int serviceId) =>
      likedServiceIds.contains(serviceId);

  static Future<void> toggleLikeService(int serviceId) async {
    final wasLiked = likedServiceIds.contains(serviceId);
    if (wasLiked) {
      likedServiceIds.remove(serviceId);
      if (isAuthenticated && sessionToken != null) {
        await SavedServicesApi().removeService(serviceId, sessionToken!);
      }
    } else {
      likedServiceIds.add(serviceId);
      if (isAuthenticated && sessionToken != null) {
        await SavedServicesApi().saveService(serviceId, sessionToken!);
      }
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
        _kLikedServices,
        likedServiceIds.map((e) => e.toString()).toList(),
    );
  }

  static List<int> getLikedServiceIds() => likedServiceIds.toList()..sort();

  static Future<void> syncSavedServices() async {
    if (!isAuthenticated || sessionToken == null) return;
    try {
      final ids = await SavedServicesApi().getSavedServiceIds(sessionToken!);
      likedServiceIds = ids.toSet();
      // Persist to local for offline/fast access
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(
        _kLikedServices,
        likedServiceIds.map((e) => e.toString()).toList(),
      );
    } catch (_) {
      // ignore
    }
  }

  // Pending action persistence
  static Future<void> setPendingAction(Map<String, dynamic>? action) async {
    final prefs = await SharedPreferences.getInstance();
    if (action == null) {
      await prefs.remove(_kPendingAction);
      return;
    }
    await prefs.setString(_kPendingAction, jsonEncode(action));
  }

  static Future<Map<String, dynamic>?> takePendingAction() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kPendingAction);
    if (raw == null) return null;
    await prefs.remove(_kPendingAction);
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) return decoded;
    } catch (_) {}
    return null;
  }

  // Feedback storage (local until backend endpoint exists)
  static Future<void> setServiceFeedback({
    required int serviceId,
    String? text,
    int? rating, // 1..5
  }) async {
    final payload = <String, dynamic>{
      if (text != null) 'text': text,
      if (rating != null) 'rating': rating,
      'updated_at': DateTime.now().toIso8601String(),
    };
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('$_kFeedbackPrefix$serviceId', jsonEncode(payload));
  }

  static Map<String, dynamic>? getServiceFeedback(int serviceId) {
    // Synchronous read via SharedPreferences cache is not supported; caller
    // should use init() then rely on getString. For convenience, we expose
    // a best-effort method that will return null if not available.
    // In UI, prefer reading via async prefs if guaranteed fresh.
    // Here, we attempt to read using SharedPreferences synchronously by
    // returning null and letting the UI ignore when not immediately needed.
    return null;
  }

  // Offline cache for bookings
  static Future<void> cacheBookings(List<Map<String, dynamic>> bookings) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kCachedBookings, jsonEncode(bookings));
    await prefs.setString(_kLastSyncBookings, DateTime.now().toIso8601String());
  }

  static Future<List<Map<String, dynamic>>> getCachedBookings() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kCachedBookings);
    if (raw == null || raw.isEmpty) return [];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is List) {
        return decoded.cast<Map<String, dynamic>>();
      }
    } catch (_) {}
    return [];
  }

  static Future<DateTime?> getLastSyncBookings() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kLastSyncBookings);
    if (raw == null) return null;
    return DateTime.tryParse(raw);
  }

  // Offline cache for spare parts orders
  static Future<void> cacheOrders(List<Map<String, dynamic>> orders) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kCachedOrders, jsonEncode(orders));
    await prefs.setString(_kLastSyncOrders, DateTime.now().toIso8601String());
  }

  static Future<List<Map<String, dynamic>>> getCachedOrders() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kCachedOrders);
    if (raw == null || raw.isEmpty) return [];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is List) {
        return decoded.cast<Map<String, dynamic>>();
      }
    } catch (_) {}
    return [];
  }

  static Future<DateTime?> getLastSyncOrders() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kLastSyncOrders);
    if (raw == null) return null;
    return DateTime.tryParse(raw);
  }

  // Helper to get the correct cart session ID (aligning with CartProvider logic)
  static Future<String?> getCartSessionId() async {
    final prefs = await SharedPreferences.getInstance();
    // Logic must match CartProvider: if auth, use suffixed key, else generic.
    // _kCartKey is 'session_id_v1' locally in CartProvider, we replicate here.
    const kCartKey = 'session_id_v1';
    final uniqueKey = isAuthenticated && (phoneNumber?.isNotEmpty ?? false)
        ? '${kCartKey}_$phoneNumber'
        : kCartKey;
    return prefs.getString(uniqueKey);
  }
}
