import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'ui/main_shell.dart';
import 'ui/flash_page.dart';
import 'providers/theme_provider.dart';
import 'utils/api_config.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  debugPrint('🔥 BACKEND BASE URL: ${resolveBackendBase()}');
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = ref.watch(themeModeProvider);
    const Color brandPrimary = Color(0xFF01C9F5);
    const Color brandOnPrimary = Color(0xFF0B0F12);
    const Color brandSecondary = Color(0xFF005B8E);
    const Color brandOnSecondary = Color(0xFFFFFFFF);
    const Color brandBackground = Color(0xFFFFFFFF);
    const Color brandOnBackground = Color(0xFF0F1A1D);
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
      background: brandBackground,
      onBackground: brandOnBackground,
      surface: brandSurface,
      onSurface: brandOnSurface,
      surfaceVariant: brandSurfaceVariant,
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

    return MaterialApp(
      title: 'RepairMyBike',
      theme: lightTheme,
      darkTheme: darkTheme,
      themeMode: mode,
      home: const FlashPage(),
      debugShowCheckedModeBanner: false,
    );
  }
}
