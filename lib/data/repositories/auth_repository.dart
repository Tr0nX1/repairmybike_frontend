import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../providers/shared_preferences_provider.dart';
import 'dart:convert' as convert;

enum AuthStatus { initial, authenticated, guest, unauthenticated }

class AuthState {
  final AuthStatus status;
  final String? sessionToken;
  final String? refreshToken;
  final String? guestId;
  final bool isStaff;
  final String? phoneNumber;
  final String? staffUsername;

  const AuthState({
    required this.status,
    this.sessionToken,
    this.refreshToken,
    this.guestId,
    this.isStaff = false,
    this.phoneNumber,
    this.staffUsername,
  });

  AuthState copyWith({
    AuthStatus? status,
    String? sessionToken,
    String? refreshToken,
    String? guestId,
    bool? isStaff,
    String? phoneNumber,
    String? staffUsername,
  }) {
    return AuthState(
      status: status ?? this.status,
      sessionToken: sessionToken ?? this.sessionToken,
      refreshToken: refreshToken ?? this.refreshToken,
      guestId: guestId ?? this.guestId,
      isStaff: isStaff ?? this.isStaff,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      staffUsername: staffUsername ?? this.staffUsername,
    );
  }

  bool get isAuthenticated => status == AuthStatus.authenticated && sessionToken != null;
  bool get isCustomerAuthenticated => isAuthenticated && !isStaff;
  bool get isStaffAuthenticated => isAuthenticated && isStaff;

  bool get isSessionExpired {
    if (sessionToken == null || sessionToken!.isEmpty) return false;
    try {
      final parts = sessionToken!.split('.');
      if (parts.length < 2) return false;
      String norm(String s) => s.padRight(s.length + (4 - s.length % 4) % 4, '=');
      final payload = convert.utf8.decode(convert.base64Url.decode(norm(parts[1])));
      final map = convert.jsonDecode(payload);
      if (map is Map && map['exp'] is num) {
        final exp = (map['exp'] as num).toInt();
        final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
        return now >= exp;
      }
    } catch (_) {}
    return false;
  }
}

class AuthNotifier extends Notifier<AuthState> {
  late final SharedPreferences _prefs;

  static const _kPhone = 'phoneNumber';
  static const _kIsStaff = 'isStaff';
  static const _kUsername = 'staffUsername';
  static const _kSession = 'session_token';
  static const _kRefresh = 'refresh_token';
  static const _kGuestId = 'guest_id';
  static const _kLastTabIndex = 'last_tab_index';

  @override
  AuthState build() {
    _prefs = ref.watch(sharedPreferencesProvider);
    return _init();
  }

  AuthState _init() {
    final sessionToken = _prefs.getString(_kSession);
    final refreshToken = _prefs.getString(_kRefresh);
    final phoneNumber = _prefs.getString(_kPhone);
    final isStaff = _prefs.getBool(_kIsStaff) ?? false;
    final staffUsername = _prefs.getString(_kUsername);
    
    String? guestId = _prefs.getString(_kGuestId);
    if (guestId == null || guestId.isEmpty) {
      final timestamp = DateTime.now().millisecondsSinceEpoch.toRadixString(16).padLeft(12, '0');
      guestId = "00000000-0000-4000-8000-$timestamp";
      _prefs.setString(_kGuestId, guestId);
    }

    if (sessionToken != null && sessionToken.isNotEmpty) {
      return AuthState(
        status: AuthStatus.authenticated,
        sessionToken: sessionToken,
        refreshToken: refreshToken,
        guestId: guestId,
        isStaff: isStaff,
        phoneNumber: phoneNumber,
        staffUsername: staffUsername,
      );
    } else {
      return AuthState(
        status: AuthStatus.guest,
        guestId: guestId,
      );
    }
  }

  Future<void> setCustomerAuth({required String phone, required String session, String? refresh}) async {
    await _prefs.setString(_kPhone, phone);
    await _prefs.setString(_kSession, session);
    if (refresh != null) await _prefs.setString(_kRefresh, refresh);
    await _prefs.setBool(_kIsStaff, false);

    state = state.copyWith(
      status: AuthStatus.authenticated,
      sessionToken: session,
      refreshToken: refresh,
      phoneNumber: phone,
      isStaff: false,
    );
  }

  Future<void> setStaffAuth({required String username, required String session, String? refresh}) async {
    await _prefs.setString(_kUsername, username);
    await _prefs.setString(_kSession, session);
    if (refresh != null) await _prefs.setString(_kRefresh, refresh);
    await _prefs.setBool(_kIsStaff, true);

    state = state.copyWith(
      status: AuthStatus.authenticated,
      sessionToken: session,
      refreshToken: refresh,
      staffUsername: username,
      isStaff: true,
    );
  }

  Future<void> updateTokens({required String session, String? refresh}) async {
    await _prefs.setString(_kSession, session);
    if (refresh != null) await _prefs.setString(_kRefresh, refresh);
    
    state = state.copyWith(
      sessionToken: session,
      refreshToken: refresh ?? state.refreshToken,
    );
  }

  Future<void> logout() async {
    await _prefs.remove(_kSession);
    await _prefs.remove(_kRefresh);
    await _prefs.remove(_kPhone);
    await _prefs.remove(_kIsStaff);
    await _prefs.remove(_kUsername);
    await _prefs.remove(_kLastTabIndex);
    
    state = AuthState(
      status: AuthStatus.unauthenticated,
      guestId: state.guestId,
    );
  }
}

final authProvider = NotifierProvider<AuthNotifier, AuthState>(AuthNotifier.new);
