import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/auth_api.dart';
import '../data/app_state.dart';
import '../data/vehicles_api.dart';
import '../providers/cart_provider.dart';
import '../utils/fcm_service.dart';

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
    if (_loading) return;
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
      _startCountdown(0);
      _showSnack('OTP sent');
    } catch (e) {
      _showSnack(_extractError(e, fallback: 'Failed to send OTP'));
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _verifyOtp() async {
    if (_loading) return;
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
        await AppState.updateFromProfileMap(profile);
      } catch (_) {}

      // Sync vehicle for existing users
      try {
        final vApi = VehiclesApi();
        final vehicles = await vApi.getUserVehicles(sessionToken: session);
        if (vehicles.isNotEmpty) {
          final v = vehicles.first;
          final details = v['vehicle_model_details'];
          if (details != null) {
            final typeName = details['vehicle_type_name'];
            final brandName = details['brand_name'];
            final modelName = details['name'];
            final modelId = details['id'];

            if (typeName != null) await AppState.setVehicleType(typeName);
            if (brandName != null) await AppState.setVehicleBrand(brandName);
            if (modelName != null) {
              await AppState.setVehicle(
                name: modelName,
                modelId: modelId,
                syncToBackend: false,
              );
            }
          }
        }
      } catch (_) {}

      setState(() {
        _otpStep = false;
        _otpCtrl.clear();
      });
      _finish();
    } catch (e) {
      _showSnack(_extractError(e, fallback: 'Verification failed'));
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
      final status = e.response?.statusCode ?? 0;
      if (status == 429) {
        return 'Too many attempts. Please wait a minute and try again.';
      }
      if (data is Map && data['message'] is String) {
        return data['message'] as String;
      }
      if (data is Map && data['error'] is String) {
        return data['error'] as String;
      }
      return fallback;
    }
    return e.toString();
  }

  void _finish() {
    final session = AppState.sessionToken;
    if (session != null) {
      _api.getProfile(sessionToken: session).then((_) {
         FcmService().registerTokenWithBackend(session);
      }).catchError((_) {});
    }

    if (widget.onFinished != null) {
      widget.onFinished!.call();
      return;
    }

    if (!AppState.isStaff) {
       if (!AppState.hasVehicle) {
         context.go('/vehicle-type?phone=${AppState.phoneNumber}');
         return;
       }
    }

    context.go('/home');
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
        title: const Text('RepairMyBike'),
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
                          context.push('/vehicle-type?phone=${phone.isEmpty ? "" : phone}');
                        },
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: accent),
                    foregroundColor: accent,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Text('Continue as Guest'),
                ),
                const SizedBox(height: 8),
                RichText(
                  textAlign: TextAlign.center,
                  text: TextSpan(
                    style: const TextStyle(color: Colors.white38, fontSize: 13),
                    children: [
                      const TextSpan(text: 'By continuing, you agree to our '),
                      TextSpan(
                        text: 'Terms',
                        style: const TextStyle(
                          color: accent,
                          decoration: TextDecoration.underline,
                        ),
                        recognizer: TapGestureRecognizer()
                          ..onTap = () {
                            context.push('/terms');
                          },
                      ),
                      const TextSpan(text: ' & '),
                      TextSpan(
                        text: 'Privacy Policy',
                        style: const TextStyle(
                          color: accent,
                          decoration: TextDecoration.underline,
                        ),
                        recognizer: TapGestureRecognizer()
                          ..onTap = () {
                            context.push('/privacy');
                          },
                      ),
                      const TextSpan(text: '.'),
                    ],
                  ),
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
    const border = Color(0xFF2A2A2A);
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
              borderSide: const BorderSide(color: border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: border),
            ),
          ),
        ),
        if (locked) ...[
          const SizedBox(height: 8),
          const Text(
            'Mobile number locked for OTP verification.',
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
