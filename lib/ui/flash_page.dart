import 'dart:async';
import 'package:flutter/material.dart';
import '../data/app_state.dart';
import '../data/auth_api.dart';
import '../data/vehicles_api.dart';
import 'auth_page.dart';
import 'main_shell.dart';
import 'profile_details_page.dart';
import 'vehicle_type_page.dart';
import 'landing_page.dart';

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
        final profile = await api.getProfile(
          sessionToken: AppState.sessionToken!,
        );
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

        // Sync vehicle
        final vApi = VehiclesApi();
        final vehicles = await vApi.getUserVehicles(
          sessionToken: AppState.sessionToken!,
        );
        if (vehicles.isNotEmpty) {
          // Sort by default or created_at? Backend sorts by -is_default, -created_at
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
    }
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
            builder: (_) => const LandingPage(),
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
