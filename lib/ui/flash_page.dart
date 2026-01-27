import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../data/app_state.dart';
import '../data/auth_api.dart';
import '../data/vehicles_api.dart';
import 'main_shell.dart';
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
    if (AppState.isAuthenticated &&
        (AppState.sessionToken?.isNotEmpty ?? false)) {
      try {
        final api = AuthApi();
        
        // Add timeout to prevent hanging if network is weird, though Dio has its own timeout.
        // If this throws (e.g. 403), the catch block will run.
        final profile = await api.getProfile(
          sessionToken: AppState.sessionToken!,
        ).timeout(const Duration(seconds: 10));

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

        // Handle addresses
        final addrs = profile['addresses'] as List?;
        if (addrs != null && addrs.isNotEmpty) {
          final addr = addrs.firstWhere((a) => a['is_default'] == true, orElse: () => addrs.first);
          await AppState.setProfile(
            f: addr['flat_house_no'],
            a: addr['area_street'],
            l: addr['landmark'],
            p: addr['pincode'],
            c: addr['town_city'],
            s: addr['state'],
            i: addr['delivery_instructions'],
            ph: addr['phone_number'],
          );
        }

        // Sync vehicle
        final vApi = VehiclesApi();
        final vehicles = await vApi.getUserVehicles(
          sessionToken: AppState.sessionToken!,
        );
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
      if (!mounted) return;
      if (AppState.isAuthenticated) {
        if (!AppState.isStaff) {
          if (!AppState.hasVehicle) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (_) => VehicleTypePage(phone: AppState.phoneNumber)),
            );
            return;
          }
        }
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const MainShell()),
        );
      } else {
        // Redirection for Guest Users: Skip forced login and go to MainShell
        // This allows Blinkit-style "browse first" experience.
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const MainShell()),
        );
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
