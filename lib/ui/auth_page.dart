import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'main_shell.dart';
import 'profile_details_page.dart';
import '../data/auth_api.dart';
import '../data/app_state.dart';
import 'vehicle_type_page.dart';
import '../providers/cart_provider.dart';

class AuthPage extends ConsumerStatefulWidget {
  final VoidCallback? onFinished;
  final bool toDetailsOnFinish;
  const AuthPage({super.key, this.onFinished, this.toDetailsOnFinish = false});

  @override
  ConsumerState<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends ConsumerState<AuthPage> {
  static const Color bg = Color(0xFF0F0F0F);
  static const Color card = Color(0xFF1C1C1C);
  static const Color border = Color(0xFF2A2A2A);
  static const Color accent = Color(0xFF01C9F5);

  final _phoneCtrl = TextEditingController(text: AppState.phoneNumber ?? '');
  final _otpCtrl = TextEditingController();
  final _api = AuthApi();
  final _usernameCtrl = TextEditingController(
    text: AppState.staffUsername ?? '',
  );
  final _passwordCtrl = TextEditingController();

  bool _loading = false;
  bool _otpStep = false;
  int _secondsLeft = 0;
  Timer? _timer;
  String _mode = AppState.isStaff
      ? 'staff'
      : 'customer'; // 'customer' | 'staff'
  bool _phoneLocked = false;
  String? _lockedPhone;

  @override
  void dispose() {
    _timer?.cancel();
    _phoneCtrl.dispose();
    _otpCtrl.dispose();
    super.dispose();
  }

  void _startCountdown([int seconds = 30]) {
    _timer?.cancel();
    setState(() => _secondsLeft = seconds);
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_secondsLeft <= 1) {
        t.cancel();
        setState(() => _secondsLeft = 0);
      } else {
        setState(() => _secondsLeft--);
      }
    });
  }

  Future<void> _loginStaff() async {
    final username = _usernameCtrl.text.trim();
    final password = _passwordCtrl.text.trim();
    if (username.isEmpty || password.isEmpty) {
      _showSnack('Please enter username and password');
      return;
    }
    setState(() => _loading = true);
    try {
      final res = await _api.loginStaff(username: username, password: password);
      final session = (res['session_token'] ?? '') as String;
      final refresh = (res['refresh_token'] ?? '') as String?;
      await AppState.setStaffAuth(
        username: username,
        session: session,
        refresh: refresh,
      );

      // Fetch profile for staff too
      try {
        final profile = await _api.getProfile(sessionToken: session);
        final first = (profile['first_name'] ?? '') as String;
        final last = (profile['last_name'] ?? '') as String;
        final mail = (profile['email'] ?? '') as String;
        final full = [
          first,
          last,
        ].where((e) => e.trim().isNotEmpty).join(' ').trim();
        await AppState.setProfile(
          name: full.isNotEmpty ? full : null,
          addr: null,
          mail: mail.isNotEmpty ? mail : null,
        );
      } catch (_) {}

      _showSnack('Signed in as staff');
      _finish();
    } catch (e) {
      _showSnack(_extractError(e, fallback: 'Staff login failed'));
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _sendOtp([String? overridePhone]) async {
    final raw = (overridePhone ?? _phoneCtrl.text).trim();
    if (raw.isEmpty) {
      _showSnack('Please enter your phone number');
      return;
    }
    final phone = AppState.normalizePhone(raw);
    final digits = phone.replaceAll(RegExp(r'\D'), '');
    if (digits.length < 10) {
      _showSnack('Enter a valid phone number with at least 10 digits');
      return;
    }
    setState(() => _loading = true);
    try {
      await _api.requestOtpPhone(phone);
      setState(() {
        _otpStep = true;
        _phoneLocked = true;
        _lockedPhone = phone;
      });
      _startCountdown();
      _showSnack('OTP sent');
    } catch (e) {
      _showSnack(_extractError(e, fallback: 'Failed to send OTP'));
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _verifyOtp() async {
    if (!_phoneLocked || (_lockedPhone == null || _lockedPhone!.isEmpty)) {
      _showSnack('Mobile number is not locked. Please request OTP first.');
      return;
    }
    final phone = _lockedPhone!;
    final code = _otpCtrl.text.trim();
    if (code.isEmpty || code.length < 4) {
      _showSnack('Enter the 4–6 digit OTP code');
      return;
    }
    setState(() => _loading = true);
    try {
      final res = await _api.verifyOtpPhone(phone: phone, code: code);
      final session = (res['session_token'] ?? '') as String;
      final refresh = (res['refresh_token'] ?? '') as String;
      await AppState.setAuth(phone: phone, session: session, refresh: refresh);
      await AppState.setLastCustomerPhone(phone);
      // Invalidate cart to load user-specific data
      ref.invalidate(cartProvider);
      try {
        final profile = await _api.getProfile(sessionToken: session);
        final first = (profile['first_name'] ?? '') as String;
        final last = (profile['last_name'] ?? '') as String;
        final mail = (profile['email'] ?? '') as String;
        final full = [
          first,
          last,
        ].where((e) => e.trim().isNotEmpty).join(' ').trim();
        await AppState.setProfile(
          name: full.isNotEmpty ? full : null,
          addr: null,
          mail: mail.isNotEmpty ? mail : null,
        );
      } catch (_) {}
      // _showSnack('Signed in');
      setState(() {
        _otpStep = false;
        _otpCtrl.clear();
      });
      // Finish flow: either notify parent tab or go to MainShell
      _finish();
    } catch (e) {
      _showSnack(_extractError(e, fallback: 'Verification failed'));
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _logout() async {
    setState(() => _loading = true);
    try {
      await _api.logout(
        refreshToken: AppState.refreshToken,
        sessionToken: AppState.sessionToken,
      );
      await AppState.clearAuth();
      await AppState.setLastCustomerPhone(null);
      // Invalidate cart to clear/reset state for guest or new user
      ref.invalidate(cartProvider);
      setState(() {
        _otpStep = false;
        _mode = 'customer';
        _usernameCtrl.clear();
        _passwordCtrl.clear();
      });
      _showSnack('Logged out');
    } catch (e) {
      _showSnack(_extractError(e, fallback: 'Logout failed'));
    } finally {
      setState(() => _loading = false);
    }
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  String _extractError(Object e, {required String fallback}) {
    if (e is DioException) {
      final data = e.response?.data;
      // Map by status code first (e.g., provider rate limits)
      final status = e.response?.statusCode ?? 0;
      if (status == 429) {
        return 'Too many attempts. Please wait a minute and try again.';
      }
      if (data is Map && data['message'] is String)
        return data['message'] as String;
      if (data is Map && data['error'] is String)
        return data['error'] as String;
      if (data is String && data.isNotEmpty) return data;
      return fallback;
    }
    var msg = e.toString();
    // Strip the common Exception prefix for cleaner display
    if (msg.startsWith('Exception: ')) {
      msg = msg.substring('Exception: '.length);
    }
    if (msg.isNotEmpty && !msg.contains('DioException')) {
      // Provide a helpful hint for common provider messages
      final lower = msg.toLowerCase();
      if (lower.contains('illegal phone') || lower.contains('invalid phone')) {
        return 'Illegal phone number. Please include country code (e.g., +91xxxxxxxxxx).';
      }
      // Rate limit / resend cooldown
      if (lower.contains('rate') && lower.contains('limit') ||
          lower.contains('too many requests') ||
          lower.contains('429') ||
          (lower.contains('resend') && lower.contains('otp')) ||
          lower.contains('cooldown')) {
        return 'Too many attempts. Please wait a minute and try again.';
      }
      // Provider/service unavailable
      if (lower.contains('service unavailable') ||
          lower.contains('provider unavailable') ||
          lower.contains('temporarily unavailable') ||
          lower.contains('503')) {
        return 'OTP service is temporarily unavailable. Please try again later.';
      }
      // Network/timeout issues
      if (lower.contains('socket') ||
          lower.contains('network') ||
          lower.contains('timeout')) {
        return 'Network issue. Check your internet connection and try again.';
      }
      // OTP verification messages
      if (lower.contains('invalid otp') ||
          lower.contains('wrong otp') ||
          lower.contains('otp code invalid') ||
          lower.contains('expired')) {
        return 'Invalid or expired OTP. Please request a new code.';
      }
      return msg;
    }
    return fallback;
  }

  void _finish() {
    // If parent wants a callback, honor it.
    if (widget.onFinished != null) {
      widget.onFinished!.call();
      return;
    }

    // Check if new user needs to select vehicle
    final hasVehicle =
        (AppState.vehicleBrand?.isNotEmpty ?? false) &&
        (AppState.vehicleName?.isNotEmpty ?? false);
    
    // Check if user needs to complete profile
    // We check fullName as a proxy for completed profile
    final hasProfile = (AppState.fullName?.isNotEmpty ?? false);
    
    // If customer has no vehicle (and isn't staff), force selection flow
    if (!AppState.isStaff) {
       if (!hasVehicle) {
         Navigator.of(context).pushReplacement(
           MaterialPageRoute(
             builder: (_) => VehicleTypePage(phone: AppState.phoneNumber),
           ),
         );
         return;
       }
       if (!hasProfile) {
         Navigator.of(context).pushReplacement(
           MaterialPageRoute(
             builder: (_) => const ProfileDetailsPage(),
           ),
         );
         return;
       }
    }

    Navigator.of(
      context,
    ).pushReplacement(MaterialPageRoute(builder: (_) => const MainShell()));
  }

  Future<void> _onChangeNumber() async {
    if (_loading) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Change Mobile Number'),
        content: const Text(
          'This will clear OTP verification and require a new OTP for the updated number.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Continue'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    _timer?.cancel();
    setState(() {
      _otpStep = false;
      _secondsLeft = 0;
      _phoneLocked = false;
      _lockedPhone = null;
      _otpCtrl.clear();
    });
    await AppState.clearAuth();
    await AppState.setLastCustomerPhone(null);
    ref.invalidate(cartProvider);
  }

  @override
  Widget build(BuildContext context) {
    final authenticated = AppState.isAuthenticated;
    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: const Color(0xFF071A1D),
        title: const Text('Welcome Back'),
        actions: const [],
      ),
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 480),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: card,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: border),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 8),
              if (!authenticated) ...[
                _modeSwitcher(),
                const SizedBox(height: 12),
                if (_mode == 'customer') ...[
                  _PhoneField(
                    controller: _phoneCtrl,
                    locked: _phoneLocked,
                    onChangeNumber: _onChangeNumber,
                  ),
                  const SizedBox(height: 6),
                  // Helpful hint for correct phone formatting per user's request
                  const Text(
                    'Example: +91 94134 57023 (normalized to +919413457023)',
                    textAlign: TextAlign.left,
                    style: TextStyle(color: Colors.white54, fontSize: 12),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: _loading || _otpStep ? null : _sendOtp,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: accent,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text('Send OTP'),
                  ),
                  const SizedBox(height: 8),
                  if (_otpStep) ...[
                    const Divider(color: border),
                    const SizedBox(height: 12),
                    _OtpField(controller: _otpCtrl),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _loading ? null : _verifyOtp,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: accent,
                              foregroundColor: Colors.black,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                            child: const Text('Verify OTP'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        TextButton(
                          onPressed: (_secondsLeft == 0 && !_loading)
                              ? () => _sendOtp(_lockedPhone)
                              : null,
                          child: Text(
                            _secondsLeft == 0
                                ? 'Resend OTP'
                                : 'Resend in $_secondsLeft s',
                            style: const TextStyle(color: Colors.white70),
                          ),
                        ),
                      ],
                    ),
                  ],
                ] else ...[
                  _StaffFields(
                    usernameController: _usernameCtrl,
                    passwordController: _passwordCtrl,
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: _loading ? null : _loginStaff,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: accent,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text('Login as Staff'),
                  ),
                ],
                const SizedBox(height: 12),
                const Divider(color: border),
                const SizedBox(height: 12),
                OutlinedButton(
                  onPressed: _loading
                      ? null
                      : () {
                          final phone = _phoneCtrl.text.trim();
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => VehicleTypePage(
                                phone: phone.isEmpty ? null : phone,
                              ),
                            ),
                          );
                        },
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: accent),
                    foregroundColor: accent,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Text('Continue as Guest'),
                ),
                const SizedBox(height: 8),
                const Text(
                  'By continuing, you agree to our Terms & Privacy Policy.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white38),
                ),
              ] else ...[
                const Icon(Icons.check_circle, color: accent, size: 48),
                const SizedBox(height: 8),
                const Text(
                  'Signed in',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white70, fontSize: 18),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _modeSwitcher() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: _loading
                ? null
                : () => setState(() {
                    _mode = 'customer';
                  }),
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: _mode == 'customer' ? accent : border),
              foregroundColor: Colors.white,
            ),
            child: const Text('Customer Login'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: OutlinedButton(
            onPressed: _loading
                ? null
                : () => setState(() {
                    _mode = 'staff';
                  }),
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: _mode == 'staff' ? accent : border),
              foregroundColor: Colors.white,
            ),
            child: const Text('Staff Login'),
          ),
        ),
      ],
    );
  }
}

class _PhoneField extends StatelessWidget {
  final TextEditingController controller;
  final bool locked;
  final VoidCallback onChangeNumber;
  const _PhoneField({
    required this.controller,
    required this.locked,
    required this.onChangeNumber,
  });

  @override
  Widget build(BuildContext context) {
    final border = const Color(0xFF2A2A2A);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: controller,
          keyboardType: TextInputType.phone,
          enabled: !locked,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'Enter phone number',
            hintStyle: const TextStyle(color: Colors.white54),
            filled: true,
            fillColor: const Color(0xFF151515),
            suffixIcon: locked
                ? const Icon(Icons.lock, color: Colors.white54)
                : null,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: border),
            ),
          ),
        ),
        if (locked) ...[
          const SizedBox(height: 8),
          const Text(
            'Mobile number locked for OTP verification. Changing number requires a new OTP.',
            style: TextStyle(color: Colors.white54, fontSize: 12),
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
              onPressed: onChangeNumber,
              child: const Text('Change Mobile Number'),
            ),
          ),
        ],
      ],
    );
  }
}

class _OtpField extends StatelessWidget {
  final TextEditingController controller;
  const _OtpField({required this.controller});

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.number,
      maxLength: 6,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        counterText: '',
        hintText: 'Enter OTP',
        hintStyle: const TextStyle(color: Colors.white54),
        filled: true,
        fillColor: const Color(0xFF151515),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF2A2A2A)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF2A2A2A)),
        ),
      ),
    );
  }
}

class _StaffFields extends StatelessWidget {
  final TextEditingController usernameController;
  final TextEditingController passwordController;
  const _StaffFields({
    required this.usernameController,
    required this.passwordController,
  });

  @override
  Widget build(BuildContext context) {
    const Color border = Color(0xFF2A2A2A);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: usernameController,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            labelText: 'Username',
            labelStyle: const TextStyle(color: Colors.white70),
            filled: true,
            fillColor: const Color(0xFF141414),
            enabledBorder: OutlineInputBorder(
              borderSide: const BorderSide(color: border),
              borderRadius: BorderRadius.circular(12),
            ),
            focusedBorder: OutlineInputBorder(
              borderSide: const BorderSide(color: Color(0xFF01C9F5)),
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: passwordController,
          obscureText: true,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            labelText: 'Password',
            labelStyle: const TextStyle(color: Colors.white70),
            filled: true,
            fillColor: const Color(0xFF141414),
            enabledBorder: OutlineInputBorder(
              borderSide: const BorderSide(color: border),
              borderRadius: BorderRadius.circular(12),
            ),
            focusedBorder: OutlineInputBorder(
              borderSide: const BorderSide(color: Color(0xFF01C9F5)),
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(label, style: const TextStyle(color: Colors.white54)),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.right,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: Colors.white70),
          ),
        ),
      ],
    );
  }
}
