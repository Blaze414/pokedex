import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'services/api_service.dart';
import 'screens/home_screen.dart';
import 'providers/favorite_provider.dart';
import 'providers/settings_provider.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider(create: (_) => ApiService()),
        ChangeNotifierProvider(create: (_) => FavoriteProvider()),
        ChangeNotifierProvider(create: (_) => SettingsProvider()),
      ],
      child: Consumer<SettingsProvider>(
        builder: (context, settings, _) {
          return MaterialApp(
            title: 'Pokédex',
            debugShowCheckedModeBanner: false,
            themeMode: settings.themeMode,
            theme: _buildLightTheme(),
            darkTheme: _buildDarkTheme(),
            home: const HomeScreen(),
          );
        },
      ),
    );
  }

  ThemeData _buildLightTheme() {
    final base = ColorScheme.fromSeed(
      seedColor: const Color(0xFFE53935),
      brightness: Brightness.light,
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: base,
      textTheme: GoogleFonts.nunitoTextTheme(),
      scaffoldBackgroundColor: const Color(0xFFF5F5F5),
      appBarTheme: AppBarTheme(
        elevation: 0,
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: GoogleFonts.nunito(
          fontSize: 28, fontWeight: FontWeight.w900,
          color: const Color(0xFF1A1A2E),
        ),
        iconTheme: const IconThemeData(color: Color(0xFF1A1A2E)),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
    );
  }

  ThemeData _buildDarkTheme() {
    final base = ColorScheme.fromSeed(
      seedColor: const Color(0xFFE53935),
      brightness: Brightness.dark,
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: base.copyWith(
        surface: const Color(0xFF121212),
        surfaceContainerLowest: const Color(0xFF1E1E1E),
        surfaceContainerLow: const Color(0xFF242424),
        surfaceContainer: const Color(0xFF2A2A2A),
      ),
      textTheme: GoogleFonts.nunitoTextTheme(ThemeData.dark().textTheme),
      scaffoldBackgroundColor: const Color(0xFF121212),
      appBarTheme: AppBarTheme(
        elevation: 0,
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: GoogleFonts.nunito(
          fontSize: 28, fontWeight: FontWeight.w900, color: Colors.white,
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        color: const Color(0xFF1E1E1E),
      ),
    );
  }
}