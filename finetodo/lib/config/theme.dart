import 'package:flutter/material.dart';
// import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Light Mode Colors
  static const Color primaryLight = Color(0xFF6366F1);
  static const Color accentLight = Color(0xFF10B981);
  static const Color surfaceLight = Color(0xFFF8F9FA);
  static const Color onSurfaceLight = Color(0xFF1F2937);
  static const Color errorLight = Color(0xFFEF4444);

  // Dark Mode Colors
  static const Color primaryDark = Color(0xFF818CF8);
  static const Color accentDark = Color(0xFF34D399);
  static const Color surfaceDark = Color(0xFF111827);
  static const Color onSurfaceDark = Color(0xFFF3F4F6);
  static const Color errorDark = Color(0xFFFCA5A5);

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primaryColor: primaryLight,
      scaffoldBackgroundColor: surfaceLight,
      textTheme: const TextTheme(
        headlineLarge: TextStyle(
          color: onSurfaceLight,
          fontWeight: FontWeight.bold,
        ),
        headlineMedium: TextStyle(
          color: onSurfaceLight,
          fontWeight: FontWeight.bold,
        ),
        bodyLarge: TextStyle(color: onSurfaceLight),
        bodyMedium: TextStyle(color: onSurfaceLight),
      ),

      appBarTheme: const AppBarTheme(
        backgroundColor: surfaceLight,
        foregroundColor: onSurfaceLight,
        elevation: 0,
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: primaryLight,
        foregroundColor: Colors.white,
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      primaryColor: primaryDark,
      scaffoldBackgroundColor: surfaceDark,
      textTheme: const TextTheme(
        headlineLarge: TextStyle(
          color: onSurfaceDark,
          fontWeight: FontWeight.bold,
        ),
        headlineMedium: TextStyle(
          color: onSurfaceDark,
          fontWeight: FontWeight.bold,
        ),
        bodyLarge: TextStyle(color: onSurfaceDark),
        bodyMedium: TextStyle(color: onSurfaceDark),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: surfaceDark,
        foregroundColor: onSurfaceDark,
        elevation: 0,
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: primaryDark,
        foregroundColor: Colors.white,
      ),
    );
  }
}
