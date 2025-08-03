import 'package:flutter/material.dart';

class AppTheme {
  static ThemeData get darkTheme {
    return ThemeData(
      primarySwatch: Colors.red,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: const Color(0xFF0A0A0A),
      colorScheme: const ColorScheme.dark(
        primary: Color(0xFFFF0000), // Bright red
        secondary: Color(0xFF8B0000), // Dark red
        surface: Color(0xFF1A1A1A),
      ),
    );
  }

  // Color constants for consistent usage
  static const Color primaryRed = Color(0xFFFF0000);
  static const Color darkRed = Color(0xFF8B0000);
  static const Color crimsonRed = Color(0xFFDC143C);
  static const Color darkBackground = Color(0xFF0A0A0A);
  static const Color mediumBackground = Color(0xFF1A1A1A);
  static const Color lightBackground = Color(0xFF2A2A2A);
}
