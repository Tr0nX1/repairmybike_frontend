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
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: scheme.surface,
      body: SafeArea(
        child: Center(
          child: Container(
            width: 140,
            height: 140,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: scheme.surface,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.20),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
              border: Border.all(color: scheme.primary, width: 2),
            ),
            clipBehavior: Clip.antiAlias,
            child: Image.network(
              Uri.base.resolve('build/flutter_assets/logo/repairmybike_logo.png').toString(),
              fit: BoxFit.cover,
              errorBuilder: (context, error, stack) {
                return Center(
                  child: Icon(
                    Icons.pedal_bike,
                    size: 64,
                    color: scheme.primary,
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}