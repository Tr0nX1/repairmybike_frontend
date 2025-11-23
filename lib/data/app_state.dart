import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class AppState {
  // Keys for persistence
  static const _kPhone = 'phoneNumber';
  static const _kSession = 'sessionToken';
  static const _kRefresh = 'refreshToken';
  static const _kIsStaff = 'isStaff';
  static const _kUsername = 'staffUsername';
  static const _kFullName = 'fullName';
  static const _kAddress = 'address';
  static const _kEmail = 'email';
  static const _kVehicleType = 'vehicleType';
  static const _kVehicleBrand = 'vehicleBrand';
  static const _kVehicleName = 'vehicleName';
  static const _kAvatarUrl = 'avatarUrl';
  static const _kLastCustomerPhone = 'lastCustomerPhone';
  static const _kLikedServices = 'likedServices';
  static const _kFeedbackPrefix = 'feedback_service_';
  static const _kPendingAction = 'pending_action';

  static String? lastCustomerPhone;
  static Set<int> likedServiceIds = <int>{};

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
  static String? fullName;
  static String? address;
  static String? email;
  static String? avatarUrl; // Owner photo URL

  static bool get isAuthenticated =>
      sessionToken != null && sessionToken!.isNotEmpty;
  static bool get isCustomerAuthenticated => isAuthenticated && !isStaff;
  static bool get isStaffAuthenticated => isAuthenticated && isStaff;

  // Initialize from SharedPreferences
  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    phoneNumber = prefs.getString(_kPhone);
    sessionToken = prefs.getString(_kSession);
    refreshToken = prefs.getString(_kRefresh);
    isStaff = prefs.getBool(_kIsStaff) ?? false;
    staffUsername = prefs.getString(_kUsername);
    // Do NOT hydrate global profile/vehicle; use phone-scoped values only
    fullName = null;
    address = null;
    email = null;
    vehicleType = null;
    vehicleBrand = null;
    vehicleName = null;
    avatarUrl = prefs.getString(_kAvatarUrl);
    lastCustomerPhone = prefs.getString(_kLastCustomerPhone);

    // Likes
    final likedRaw = prefs.getStringList(_kLikedServices) ?? const [];
    likedServiceIds = likedRaw
        .map((e) => int.tryParse(e))
        .whereType<int>()
        .toSet();

    // Hydrate vehicle selection specific to a phone if available
    final p = phoneNumber ?? lastCustomerPhone;
    if (p != null && p.isNotEmpty) {
      final tPhone = prefs.getString('$_kVehicleType' '_' '$p');
      final bPhone = prefs.getString('$_kVehicleBrand' '_' '$p');
      final nPhone = prefs.getString('$_kVehicleName' '_' '$p');
      final fPhone = prefs.getString('$_kFullName' '_' '$p');
      final aPhone = prefs.getString('$_kAddress' '_' '$p');
      final ePhone = prefs.getString('$_kEmail' '_' '$p');
      if (tPhone != null) vehicleType = tPhone;
      if (bPhone != null) vehicleBrand = bPhone;
      if (nPhone != null) vehicleName = nPhone;
      if (fPhone != null) fullName = fPhone;
      if (aPhone != null) address = aPhone;
      if (ePhone != null) email = ePhone;
    }
  }

  static Future<void> setAuth({
    required String phone,
    required String session,
    required String refresh,
  }) async {
    phoneNumber = phone;
    sessionToken = session;
    refreshToken = refresh;
    isStaff = false;
    staffUsername = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kPhone, phone);
    await prefs.setString(_kSession, session);
    await prefs.setString(_kRefresh, refresh);
    await prefs.setBool(_kIsStaff, false);
    await prefs.remove(_kUsername);

    // Load phone-specific vehicle and profile when user signs in
    final tPhone = prefs.getString('$_kVehicleType' '_' '$phone');
    final bPhone = prefs.getString('$_kVehicleBrand' '_' '$phone');
    final nPhone = prefs.getString('$_kVehicleName' '_' '$phone');
    vehicleType = tPhone; // may be null for first-time
    vehicleBrand = bPhone;
    vehicleName = nPhone;
    final fPhone = prefs.getString('$_kFullName' '_' '$phone');
    final aPhone = prefs.getString('$_kAddress' '_' '$phone');
    final ePhone = prefs.getString('$_kEmail' '_' '$phone');
    fullName = fPhone;
    address = aPhone;
    email = ePhone;
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
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kPhone);
    await prefs.remove(_kSession);
    await prefs.remove(_kRefresh);
    await prefs.remove(_kIsStaff);
    await prefs.remove(_kUsername);
    // Do not clear likes or profile; they are user-preferences.
  }

  // Staff auth: username/password based session. No refresh for now.
  static Future<void> setStaffAuth({
    required String username,
    required String session,
    String? refresh,
  }) async {
    staffUsername = username;
    sessionToken = session;
    refreshToken = refresh;
    phoneNumber = null; // not applicable
    isStaff = true;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kSession, session);
    if (refresh != null && refresh.isNotEmpty) {
      await prefs.setString(_kRefresh, refresh);
    } else {
      await prefs.remove(_kRefresh);
    }
    await prefs.setBool(_kIsStaff, true);
    await prefs.setString(_kUsername, username);
    await prefs.remove(_kPhone);
  }

  static Future<void> setVehicleType(String type) async {
    vehicleType = type;
    final prefs = await SharedPreferences.getInstance();
    final phone = phoneNumber ?? lastCustomerPhone;
    if (phone != null && phone.isNotEmpty) {
      await prefs.setString('$_kVehicleType' '_' '$phone', type);
    }
  }

  static Future<void> setVehicleBrand(String brand) async {
    vehicleBrand = brand;
    final prefs = await SharedPreferences.getInstance();
    final phone = phoneNumber ?? lastCustomerPhone;
    if (phone != null && phone.isNotEmpty) {
      await prefs.setString('$_kVehicleBrand' '_' '$phone', brand);
    }
  }

  static Future<void> setVehicleName(String name) async {
    vehicleName = name;
    final prefs = await SharedPreferences.getInstance();
    final phone = phoneNumber ?? lastCustomerPhone;
    if (phone != null && phone.isNotEmpty) {
      await prefs.setString('$_kVehicleName' '_' '$phone', name);
    }
  }

  // Persist vehicle selection keyed by mobile number
  static Future<void> setVehicleForPhone({
    required String phone,
    String? type,
    String? brand,
    String? name,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    if (type != null) await prefs.setString('$_kVehicleType' '_' '$phone', type);
    if (brand != null) await prefs.setString('$_kVehicleBrand' '_' '$phone', brand);
    if (name != null) await prefs.setString('$_kVehicleName' '_' '$phone', name);
  }

  static Future<void> setProfile({String? name, String? addr, String? mail}) async {
    fullName = name ?? fullName;
    address = addr ?? address;
    email = mail ?? email;
    final prefs = await SharedPreferences.getInstance();
    final phone = phoneNumber ?? lastCustomerPhone;
    if (phone != null && phone.isNotEmpty) {
      if (name != null) await prefs.setString('$_kFullName' '_' '$phone', name);
      if (addr != null) await prefs.setString('$_kAddress' '_' '$phone', addr);
      if (mail != null) await prefs.setString('$_kEmail' '_' '$phone', mail);
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
    lastCustomerPhone = phone;
    final prefs = await SharedPreferences.getInstance();
    if (phone == null || phone.isEmpty) {
      await prefs.remove(_kLastCustomerPhone);
    } else {
      await prefs.setString(_kLastCustomerPhone, phone);
    }
  }

  // Likes API
  static bool isServiceLiked(int serviceId) => likedServiceIds.contains(serviceId);

  static Future<void> toggleLikeService(int serviceId) async {
    if (likedServiceIds.contains(serviceId)) {
      likedServiceIds.remove(serviceId);
    } else {
      likedServiceIds.add(serviceId);
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _kLikedServices,
      likedServiceIds.map((e) => e.toString()).toList(),
    );
  }

  static List<int> getLikedServiceIds() => likedServiceIds.toList()..sort();

  static Future<void> setLikedServices(List<int> ids) async {
    likedServiceIds = ids.toSet();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _kLikedServices,
      likedServiceIds.map((e) => e.toString()).toList(),
    );
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
}
