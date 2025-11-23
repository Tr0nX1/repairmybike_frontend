import 'dart:async';
import 'package:flutter/material.dart';
import '../data/app_state.dart';
import 'auth_page.dart';
import 'main_shell.dart';
import 'profile_details_page.dart';
import 'vehicle_type_page.dart';

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
    if (mounted) _controller.forward();
    _timer = Timer(const Duration(milliseconds: 2500), () {
      if (!mounted) return;
      if (AppState.isAuthenticated) {
        final hasVehicle =
            (AppState.vehicleBrand?.isNotEmpty ?? false) &&
            (AppState.vehicleName?.isNotEmpty ?? false);
        final hasProfile =
            (AppState.fullName?.isNotEmpty ?? false) &&
            (AppState.address?.isNotEmpty ?? false);
        if (!hasVehicle) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (_) => VehicleTypePage(phone: AppState.phoneNumber),
            ),
          );
        } else if (!hasProfile) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const ProfileDetailsPage()),
          );
        } else {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const MainShell()),
          );
        }
      } else {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => const AuthPage(toDetailsOnFinish: true),
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
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
