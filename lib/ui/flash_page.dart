import 'dart:async';
import 'package:flutter/material.dart';
import '../data/app_state.dart';
import 'auth_page.dart';
import 'vehicle_type_page.dart';
import 'main_shell.dart';

class FlashPage extends StatefulWidget {
  const FlashPage({super.key});

  @override
  State<FlashPage> createState() => _FlashPageState();
}

class _FlashPageState extends State<FlashPage> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _initAndNavigate();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _initAndNavigate() async {
    // Ensure persisted state is loaded
    await AppState.init();
    // Keep splash visible for ~2s for a smooth experience
    _timer = Timer(const Duration(seconds: 2), () {
      if (!mounted) return;
      if (AppState.isAuthenticated && (AppState.fullName?.isNotEmpty ?? false)) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const MainShell()),
        );
      } else {
        // Go straight to authentication -> details flow as requested
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const AuthPage(toDetailsOnFinish: true)),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    const accent = Color(0xFF01C9F5);
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F0F),
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 96,
                height: 96,
                decoration: const BoxDecoration(
                  color: accent,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.pedal_bike, size: 56, color: Colors.black),
              ),
              const SizedBox(height: 16),
              const Text(
                'RepairMyBike',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Fast, reliable bike service near you',
                style: TextStyle(color: Colors.white54),
              ),
              const SizedBox(height: 24),
              OutlinedButton(
                onPressed: () {
                  if (!mounted) return;
                  _timer?.cancel();
                  if (AppState.isAuthenticated && (AppState.fullName?.isNotEmpty ?? false)) {
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(builder: (_) => const MainShell()),
                    );
                  } else {
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(builder: (_) => const VehicleTypePage()),
                    );
                  }
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: accent,
                  side: const BorderSide(color: accent),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
                child: const Text('Skip'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}