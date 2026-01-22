import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'auth_api.dart';
import 'vehicles_api.dart';
import 'saved_services_api.dart';
import 'spare_parts_api.dart';

class AppState {
  // Keys for persistence
  static const _kPhone = 'phoneNumber';
  static const _kIsStaff = 'isStaff';
  static const _kUsername = 'staffUsername';
  static const _kAvatarUrl = 'avatarUrl';
  static const _kLastCustomerPhone = 'lastCustomerPhone';
  static const _kLikedServices = 'likedServices';
  static const _kLikedParts = 'likedParts';
  static const _kFullName = 'fullName';
  static const _kEmail = 'email';
  static const _kAddrFlat = 'addrFlat';
  static const _kAddrArea = 'addrArea';
  static const _kAddrLandmark = 'addrLandmark';
  static const _kAddrPincode = 'addrPincode';
  static const _kAddrCity = 'addrCity';
  static const _kAddrState = 'addrState';
  static const _kAddrInstructions = 'addrInstructions';
  static const _kAddrPhone = 'addrPhone';
  static const _kVehicleType = 'vehicleType';
  static const _kVehicleBrand = 'vehicleBrand';
  static const _kVehicleName = 'vehicleName';
  static const _kVehicleModelId = 'vehicleModelId';
  static const _kVehicleImageUrl = 'vehicleImageUrl';
  static const _kVehicleBrandImageUrl = 'vehicleBrandImageUrl';
  static const _kVehicleTypeImageUrl = 'vehicleTypeImageUrl';
  static const _kSession = 'session_token';
  static const _kRefresh = 'refresh_token';
  static const _kGuestId = 'guest_id';

  // Auth state
  static String? phoneNumber;
  static String? sessionToken;
  static String? refreshToken;
  static String? guestId;
  static bool isStaff = false;
  static String? staffUsername;

  // Profile fields
  static String? fullName;
  static String? email;
  static String? avatarUrl;
  static String? addrFlat;
  static String? addrArea;
  static String? addrLandmark;
  static String? addrPincode;
  static String? addrCity;
  static String? addrState;
  static String? addrInstructions;
  static String? addrPhone;

  // Vehicle fields
  static String? vehicleType;
  static String? vehicleBrand;
  static String? vehicleName;
  static int? vehicleModelId;
  static String? vehicleImageUrl;
  static String? vehicleBrandImageUrl;
  static String? vehicleTypeImageUrl;

  static String? lastCustomerPhone;
  static Set<int> likedServiceIds = <int>{};
  static Set<int> likedPartIds = <int>{};
  static Map<int, Map<String, dynamic>> serviceFeedbacks = {};
  static Map<String, dynamic>? pendingAction;

  static bool get isAuthenticated => sessionToken != null && sessionToken!.isNotEmpty;
  static bool get isCustomerAuthenticated => isAuthenticated && !isStaff;
  static bool get isStaffAuthenticated => isAuthenticated && isStaff;

  static bool get hasVehicle => vehicleName != null && vehicleName!.isNotEmpty;
  static bool get hasAddress => addrFlat != null && addrFlat!.isNotEmpty && addrPincode != null;

  static String? get address => addrFlat;
  static set address(String? value) => addrFlat = value;

  static String get fullAddress {
    final parts = [
      addrFlat,
      addrArea,
      addrLandmark,
      addrCity,
      addrState,
      addrPincode,
    ].where((e) => e != null && e.isNotEmpty).toList();
    return parts.join(', ');
  }

  static String normalizePhone(String p) {
    var s = p.trim().replaceAll(RegExp('\\D'), '');
    if (s.isEmpty) return '';
    if (s.length == 10) return '+91$s';
    if (s.length == 12 && s.startsWith('91')) return '+$s';
    if (s.startsWith('0') && s.length == 11) return '+91${s.substring(1)}';
    if (p.trim().startsWith('+')) return p.trim();
    return '+$s';
  }

  static int? _jwtExpEpoch(String? jwt) {
    try {
      if (jwt == null || jwt.isEmpty) return null;
      final parts = jwt.split('.');
      if (parts.length < 2) return null;
      String norm(String s) => s.padRight(s.length + (4 - s.length % 4) % 4, '=');
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

  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    phoneNumber = prefs.getString(_kPhone);
    isStaff = prefs.getBool(_kIsStaff) ?? false;
    staffUsername = prefs.getString(_kUsername);
    avatarUrl = prefs.getString(_kAvatarUrl);
    fullName = prefs.getString(_kFullName);
    email = prefs.getString(_kEmail);
    addrFlat = prefs.getString(_kAddrFlat);
    addrArea = prefs.getString(_kAddrArea);
    addrLandmark = prefs.getString(_kAddrLandmark);
    addrPincode = prefs.getString(_kAddrPincode);
    addrCity = prefs.getString(_kAddrCity);
    addrState = prefs.getString(_kAddrState);
    addrInstructions = prefs.getString(_kAddrInstructions);
    addrPhone = prefs.getString(_kAddrPhone);
    vehicleType = prefs.getString(_kVehicleType);
    vehicleBrand = prefs.getString(_kVehicleBrand);
    vehicleName = prefs.getString(_kVehicleName);
    vehicleModelId = prefs.getInt(_kVehicleModelId);
    vehicleImageUrl = prefs.getString(_kVehicleImageUrl);
    vehicleBrandImageUrl = prefs.getString(_kVehicleBrandImageUrl);
    vehicleTypeImageUrl = prefs.getString(_kVehicleTypeImageUrl);
    sessionToken = prefs.getString(_kSession);
    refreshToken = prefs.getString(_kRefresh);
    guestId = prefs.getString(_kGuestId);
    
    // Generate Guest ID if not exists (simple stable identifier)
    if (guestId == null || guestId!.isEmpty) {
      final timestamp = DateTime.now().millisecondsSinceEpoch.toRadixString(16).padLeft(12, '0');
      // Format: 00000000-0000-4000-8000-timestamp (UUID v4-like)
      guestId = "00000000-0000-4000-8000-$timestamp";
      await prefs.setString(_kGuestId, guestId!);
    }
    lastCustomerPhone = prefs.getString(_kLastCustomerPhone);
    final likedS = prefs.getStringList(_kLikedServices);
    if (likedS != null) likedServiceIds = likedS.map(int.parse).toSet();
    final likedP = prefs.getStringList(_kLikedParts);
    if (likedP != null) likedPartIds = likedP.map(int.parse).toSet();
    
    final fbJson = prefs.getString('serviceFeedbacks');
    if (fbJson != null) {
      try {
        final Map<String, dynamic> deco = jsonDecode(fbJson);
        serviceFeedbacks = deco.map((k, v) => MapEntry(int.parse(k), v as Map<String, dynamic>));
      } catch (_) {}
    }
  }

  static Future<void> setPhone(String phone) async {
    phoneNumber = phone;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kPhone, phone);
  }

  static Future<void> setTokens({required String session, String? refresh}) async {
    sessionToken = session;
    refreshToken = refresh;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kSession, session);
    if (refresh != null) await prefs.setString(_kRefresh, refresh);
  }

  static Future<void> setVehicle({
    required String name,
    String? type,
    String? brand,
    int? modelId,
    String? imageUrl,
    String? brandImageUrl,
    String? typeImageUrl,
    bool syncToBackend = true,
  }) async {
    vehicleName = name;
    vehicleModelId = modelId;
    if (type != null) vehicleType = type;
    if (brand != null) vehicleBrand = brand;
    if (imageUrl != null) vehicleImageUrl = imageUrl;
    if (brandImageUrl != null) vehicleBrandImageUrl = brandImageUrl;
    if (typeImageUrl != null) vehicleTypeImageUrl = typeImageUrl;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kVehicleName, name);
    if (type != null) await prefs.setString(_kVehicleType, type);
    if (brand != null) await prefs.setString(_kVehicleBrand, brand);
    if (modelId != null) await prefs.setInt(_kVehicleModelId, modelId);
    if (imageUrl != null) await prefs.setString(_kVehicleImageUrl, imageUrl);
    if (brandImageUrl != null) await prefs.setString(_kVehicleBrandImageUrl, brandImageUrl);
    if (typeImageUrl != null) await prefs.setString(_kVehicleTypeImageUrl, typeImageUrl);
    if (syncToBackend && sessionToken != null) {
      try {
        await VehiclesApi().addUserVehicle(
          sessionToken: sessionToken!,
          vehicleModelId: modelId ?? 1,
        );
      } catch (_) {}
    }
  }

  static Future<void> setVehicleType(String type) async {
    vehicleType = type;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kVehicleType, type);
  }

  static Future<void> setVehicleBrand(String brand) async {
    vehicleBrand = brand;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kVehicleBrand, brand);
  }

  static Future<void> setProfile({
    String? name,
    String? mail,
    String? f,
    String? a,
    String? l,
    String? p,
    String? c,
    String? s,
    String? i,
    String? ph,
    String? addr,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    if (addr != null) {
      addrFlat = addr;
      await prefs.setString(_kAddrFlat, addr);
    }
    if (name != null) {
      fullName = name;
      await prefs.setString(_kFullName, name);
    }
    if (mail != null) {
      email = mail;
      await prefs.setString(_kEmail, mail);
    }
    if (f != null) {
      addrFlat = f;
      await prefs.setString(_kAddrFlat, f);
    }
    if (a != null) {
      addrArea = a;
      await prefs.setString(_kAddrArea, a);
    }
    if (l != null) {
      addrLandmark = l;
      await prefs.setString(_kAddrLandmark, l);
    }
    if (p != null) {
      addrPincode = p;
      await prefs.setString(_kAddrPincode, p);
    }
    if (c != null) {
      addrCity = c;
      await prefs.setString(_kAddrCity, c);
    }
    if (s != null) {
      addrState = s;
      await prefs.setString(_kAddrState, s);
    }
    if (i != null) {
      addrInstructions = i;
      await prefs.setString(_kAddrInstructions, i);
    }
    if (ph != null) {
      addrPhone = ph;
      await prefs.setString(_kAddrPhone, ph);
    }
  }

  static Future<void> clearAllData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    phoneNumber = null;
    isStaff = false;
    staffUsername = null;
    avatarUrl = null;
    fullName = null;
    email = null;
    addrFlat = null;
    addrArea = null;
    addrLandmark = null;
    addrPincode = null;
    addrCity = null;
    addrState = null;
    addrInstructions = null;
    addrPhone = null;
    vehicleType = null;
    vehicleBrand = null;
    vehicleName = null;
    vehicleModelId = null;
    vehicleImageUrl = null;
    vehicleBrandImageUrl = null;
    vehicleTypeImageUrl = null;
    sessionToken = null;
    refreshToken = null;
    likedServiceIds.clear();
    likedPartIds.clear();
  }

  static Future<void> setAuth({required String phone, required String session, String? refresh}) async {
    phoneNumber = phone;
    sessionToken = session;
    refreshToken = refresh;
    isStaff = false;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kPhone, phone);
    await prefs.setString(_kSession, session);
    if (refresh != null) await prefs.setString(_kRefresh, refresh);
    await prefs.setBool(_kIsStaff, false);
  }

  static Future<void> setStaffAuth({required String username, required String session, String? refresh}) async {
    staffUsername = username;
    sessionToken = session;
    refreshToken = refresh;
    isStaff = true;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kUsername, username);
    await prefs.setString(_kSession, session);
    if (refresh != null) await prefs.setString(_kRefresh, refresh);
    await prefs.setBool(_kIsStaff, true);
  }

  static Future<void> clearAuth() async {
    sessionToken = null;
    refreshToken = null;
    phoneNumber = null;
    isStaff = false;
    staffUsername = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kSession);
    await prefs.remove(_kRefresh);
    await prefs.remove(_kPhone);
    await prefs.remove(_kIsStaff);
    await prefs.remove(_kUsername);
  }
  
  static Future<void> setAvatarUrl(String? url) async {
    avatarUrl = url;
    final prefs = await SharedPreferences.getInstance();
    if (url == null) {
      await prefs.remove(_kAvatarUrl);
    } else {
      await prefs.setString(_kAvatarUrl, url);
    }
  }

  static Future<void> setVehicleName(String name) async {
    vehicleName = name;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kVehicleName, name);
  }

  static Future<void> setLastCustomerPhone(String? phone) async {
    lastCustomerPhone = phone;
    final prefs = await SharedPreferences.getInstance();
    if (phone == null) {
      await prefs.remove(_kLastCustomerPhone);
    } else {
      await prefs.setString(_kLastCustomerPhone, phone);
    }
  }

  static Future<void> toggleLikeService(int id) async {
    if (likedServiceIds.contains(id)) {
      likedServiceIds.remove(id);
    } else {
      likedServiceIds.add(id);
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_kLikedServices, likedServiceIds.map((e) => e.toString()).toList());
    if (isAuthenticated) {
      try {
        if (likedServiceIds.contains(id)) {
          await SavedServicesApi().removeService(id, sessionToken!);
        } else {
          await SavedServicesApi().saveService(id, sessionToken!);
        }
      } catch (_) {}
    }
  }

  static bool isServiceLiked(int id) => likedServiceIds.contains(id);

  static Future<void> toggleLikePart(int id) async {
    if (likedPartIds.contains(id)) {
      likedPartIds.remove(id);
    } else {
      likedPartIds.add(id);
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_kLikedParts, likedPartIds.map((e) => e.toString()).toList());
    if (isAuthenticated) {
      try {
        if (likedPartIds.contains(id)) {
          await SparePartsApi().removePart(id);
        } else {
          await SparePartsApi().savePart(id);
        }
      } catch (_) {}
    }
  }

  static bool isPartLiked(int id) => likedPartIds.contains(id);

  static Future<void> syncSavedServices() async {
    if (!isAuthenticated) return;
    try {
      final ids = await SavedServicesApi().getSavedServiceIds(sessionToken!);
      likedServiceIds = ids.toSet();
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_kLikedServices, likedServiceIds.map((e) => e.toString()).toList());
    } catch (_) {}
  }

  static Future<void> syncSavedParts() async {
    if (!isAuthenticated) return;
    try {
      final ids = await SparePartsApi().getSavedPartIds();
      likedPartIds = ids.toSet();
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_kLikedParts, likedPartIds.map((e) => e.toString()).toList());
    } catch (_) {}
  }

  static Future<void> setPendingAction(Map<String, dynamic>? action) async {
    pendingAction = action;
  }

  static Future<Map<String, dynamic>?> takePendingAction() async {
    final a = pendingAction;
    pendingAction = null;
    return a;
  }

  static Map<String, dynamic>? getServiceFeedback(int id) => serviceFeedbacks[id];

  static Future<void> setServiceFeedback({
    required int serviceId,
    required int rating,
    required String text,
  }) async {
    serviceFeedbacks[serviceId] = {'rating': rating, 'text': text};
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('serviceFeedbacks', jsonEncode(serviceFeedbacks.map((k, v) => MapEntry(k.toString(), v))));
  }

  static Future<List<Map<String, dynamic>>> getCachedBookings() async {
    final prefs = await SharedPreferences.getInstance();
    final s = prefs.getString('cachedBookings');
    if (s == null) return [];
    try {
      final List l = jsonDecode(s);
      return l.cast<Map<String, dynamic>>();
    } catch (_) {
      return [];
    }
  }

  static Future<List<Map<String, dynamic>>> getCachedOrders() async {
    final prefs = await SharedPreferences.getInstance();
    final s = prefs.getString('cachedOrders');
    if (s == null) return [];
    try {
      final List l = jsonDecode(s);
      return l.cast<Map<String, dynamic>>();
    } catch (_) {
      return [];
    }
  }

  static Future<DateTime?> getLastSyncBookings() async {
    final prefs = await SharedPreferences.getInstance();
    final ms = prefs.getInt('lastSyncBookings');
    return ms == null ? null : DateTime.fromMillisecondsSinceEpoch(ms);
  }

  static Future<DateTime?> getLastSyncOrders() async {
    final prefs = await SharedPreferences.getInstance();
    final ms = prefs.getInt('lastSyncOrders');
    return ms == null ? null : DateTime.fromMillisecondsSinceEpoch(ms);
  }

  static Future<void> cacheBookings(List<Map<String, dynamic>> data) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('cachedBookings', jsonEncode(data));
    await prefs.setInt('lastSyncBookings', DateTime.now().millisecondsSinceEpoch);
  }

  static Future<void> cacheOrders(List<Map<String, dynamic>> data) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('cachedOrders', jsonEncode(data));
    await prefs.setInt('lastSyncOrders', DateTime.now().millisecondsSinceEpoch);
  }

  static Future<String?> getCartSessionId() async {
    final prefs = await SharedPreferences.getInstance();
    String? sid = prefs.getString('cart_session_id');
    if (sid == null) {
      sid = DateTime.now().millisecondsSinceEpoch.toString();
      await prefs.setString('cart_session_id', sid);
    }
    return sid;
  }
}
