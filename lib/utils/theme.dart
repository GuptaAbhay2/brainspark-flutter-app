import 'package:flutter/material.dart';

class AppTheme {
  static const Color primary   = Color(0xFF185FA5);
  static const Color secondary = Color(0xFF3B6D11);
  static const Color accent    = Color(0xFF854F0B);
  static const Color purple    = Color(0xFF534AB7);

  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(seedColor: primary),
    fontFamily: 'Roboto',
    scaffoldBackgroundColor: const Color(0xFFF5F7FA),
    cardTheme: CardThemeData(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: Colors.white,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.white,
      elevation: 0,
      titleTextStyle: TextStyle(
        color: Color(0xFF1A1A2E), fontSize: 20, fontWeight: FontWeight.w700,
      ),
      iconTheme: IconThemeData(color: Color(0xFF1A1A2E)),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 0,
      ),
    ),
  );

  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: primary, brightness: Brightness.dark,
    ),
    scaffoldBackgroundColor: const Color(0xFF0F0F1A),
    cardTheme: CardThemeData(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: const Color(0xFF1A1A2E),
    ),
  );
}
