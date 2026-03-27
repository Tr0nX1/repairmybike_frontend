import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../data/app_state.dart';
import '../data/auth_api.dart';
import '../utils/fcm_service.dart';
import 'package:go_router/go_router.dart';

class FlashPage extends StatefulWidget {
  const FlashPage({super.key});

  @override
  State<FlashPage> createState() => _FlashPageState();
}

class _FlashPageState extends State<FlashPage>
    with SingleTickerProviderStateMixin {
  Timer? _timer;
  late final AnimationController _controller;
  late final Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
    _initAndNavigate();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _initAndNavigate() async {
    await AppState.init();
    if (AppState.isAuthenticated &&
        (AppState.sessionToken?.isNotEmpty ?? false)) {
      try {
        final api = AuthApi();
        
        // Add timeout to prevent hanging if network is weird, though Dio has its own timeout.
        // If this throws (e.g. 403), the catch block will run.
        final profile = await api.getProfile(
          sessionToken: AppState.sessionToken!,
        ).timeout(const Duration(seconds: 10));

        // Register FCM Token for the returning user
        FcmService().registerTokenWithBackend(AppState.sessionToken);

        await AppState.updateFromProfileMap(profile);
      } catch (e) {
        // If an error occurs (e.g. 403 Forbidden), ApiClient has already cleared auth.
        // We log it and rely on the navigation logic below to see !isAuthenticated
        if (kDebugMode) {
            print('FlashPage: Profile fetch failed: $e');
        }
      }
    }
    if (mounted) _controller.forward();
    _timer = Timer(const Duration(milliseconds: 2500), () {
      if (AppState.isAuthenticated) {
        if (!AppState.isStaff) {
          if (!AppState.hasVehicle) {
            context.go('/vehicle-type?phone=${AppState.phoneNumber}');
            return;
          }
        }
        context.go('/home');
      } else {
        // Direct unauthenticated users to high-end Landing Page
        context.go('/');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F0F),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Center(
                  child: FadeTransition(
                    opacity: _fade,
                    child: Container(
                      width: 220,
                      height: 220,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: Image.asset(
                        'assets/images/logo/repairmybike_newlogo.jpeg',
                        fit: BoxFit.cover,
                        filterQuality: FilterQuality.high,
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
