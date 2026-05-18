import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_strategy/url_strategy.dart';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'utils/fcm_service.dart';

import 'utils/router.dart';

import 'package:shared_preferences/shared_preferences.dart';
import 'data/providers/shared_preferences_provider.dart';

void main() async {
  setPathUrlStrategy();
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Global UI Error Boundary (Red Screen Replacement)
  ErrorWidget.builder = (FlutterErrorDetails details) {
    // Log the error globally
    debugPrint('🚨 GLOBAL UI ERROR: ${details.exceptionAsString()}');
    debugPrint(details.stack?.toString());

    return Material(
      color: const Color(0xFF0B0F12), // Brand primary dark background
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.warning_amber_rounded, color: Color(0xFFE83C3C), size: 64),
              const SizedBox(height: 16),
              const Text(
                'Something went wrong',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              const SizedBox(height: 8),
              const Text(
                'We hit a technical snag. Please continue or refresh the page.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Colors.white70),
              ),
            ],
          ),
        ),
      ),
    );
  };

  final sharedPreferences = await SharedPreferences.getInstance();
  
  // Initialize Firebase (safely handle Web where options might be missing)
  try {
    if (!kIsWeb) {
      await Firebase.initializeApp();
      // Setup FCM
      final fcmService = FcmService();
      await fcmService.initialize();
      FirebaseMessaging.onBackgroundMessage(fcmBackgroundHandler);
    } else {
      debugPrint('Firebase Web is not configured. Skipping FCM initialization.');
    }
  } catch (e) {
    debugPrint('Firebase initialization failed (likely missing config): $e');
  }

  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(sharedPreferences),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    const mode = ThemeMode.dark;
    // ... Color definitions remain unchanged ...
    const Color brandPrimary = Color(0xFF01C9F5);
    const Color brandOnPrimary = Color(0xFF0B0F12);
    const Color brandSecondary = Color(0xFF005B8E);
    const Color brandOnSecondary = Color(0xFFFFFFFF);
    const Color brandSurface = Color(0xFFF7F9FB);
    const Color brandOnSurface = Color(0xFF0F1A1D);
    const Color brandSurfaceVariant = Color(0xFFEEF2F6);
    const Color brandOnSurfaceVariant = Color(0xFF33424D);
    const Color brandOutline = Color(0xFFCBD5E1);
    const Color brandError = Color(0xFFE83C3C);
    const Color brandOnError = Color(0xFFFFFFFF);
    const Color brandTertiary = Color(0xFF1BBE7B);
    const Color brandOnTertiary = Color(0xFF0B0F12);

    final ColorScheme lightScheme = ColorScheme.fromSeed(
      seedColor: brandPrimary,
      brightness: Brightness.light,
    ).copyWith(
      primary: brandPrimary,
      onPrimary: brandOnPrimary,
      secondary: brandSecondary,
      onSecondary: brandOnSecondary,
      surface: brandSurface,
      onSurface: brandOnSurface,
      surfaceContainerHighest: brandSurfaceVariant,
      onSurfaceVariant: brandOnSurfaceVariant,
      outline: brandOutline,
      error: brandError,
      onError: brandOnError,
      tertiary: brandTertiary,
      onTertiary: brandOnTertiary,
    );
    final ColorScheme darkScheme = ColorScheme.fromSeed(
      seedColor: brandPrimary,
      brightness: Brightness.dark,
    );

    final ThemeData lightTheme = ThemeData(
      useMaterial3: true,
      colorScheme: lightScheme,
      scaffoldBackgroundColor: lightScheme.surface,
      appBarTheme: AppBarTheme(
        backgroundColor: lightScheme.surface,
        foregroundColor: lightScheme.onSurface,
        elevation: 0,
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: lightScheme.surface,
        selectedItemColor: lightScheme.primary,
        unselectedItemColor: lightScheme.onSurface,
        showUnselectedLabels: true,
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600),
        unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500),
      ),
      textTheme: ThemeData().textTheme.apply(
            bodyColor: lightScheme.onSurface,
            displayColor: lightScheme.onSurface,
          ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: ButtonStyle(
          foregroundColor: WidgetStatePropertyAll(lightScheme.primary),
          side: WidgetStatePropertyAll(BorderSide(color: lightScheme.primary)),
        ),
      ),
    );

    final ThemeData darkTheme = ThemeData(
      useMaterial3: true,
      colorScheme: darkScheme,
      scaffoldBackgroundColor: darkScheme.surface,
      appBarTheme: AppBarTheme(
        backgroundColor: darkScheme.surface,
        foregroundColor: darkScheme.onSurface,
        elevation: 0,
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: darkScheme.surface,
        selectedItemColor: darkScheme.primary,
        unselectedItemColor: darkScheme.onSurface,
        showUnselectedLabels: true,
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600),
        unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500),
      ),
      textTheme: ThemeData().textTheme.apply(
            bodyColor: darkScheme.onSurface,
            displayColor: darkScheme.onSurface,
          ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: ButtonStyle(
          foregroundColor: WidgetStatePropertyAll(darkScheme.primary),
          side: WidgetStatePropertyAll(BorderSide(color: darkScheme.primary)),
        ),
      ),
    );

    return MaterialApp.router(
      title: 'RepairMyBike',
      theme: lightTheme,
      darkTheme: darkTheme,
      themeMode: mode,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}
