import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'ui/main_shell.dart';
import 'ui/flash_page.dart';
import 'providers/theme_provider.dart';

void main() {
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = ref.watch(themeModeProvider);
    const Color brandSeed = Color(0xFF01C9F5);
    final ColorScheme lightScheme = ColorScheme.fromSeed(
      seedColor: brandSeed,
      brightness: Brightness.light,
    );
    final ColorScheme darkScheme = ColorScheme.fromSeed(
      seedColor: brandSeed,
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
