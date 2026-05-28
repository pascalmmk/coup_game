import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: const Color(0xFF101416), // Dark moody background
      colorScheme: const ColorScheme.dark(
        primary: Color(0xFFE53935), // Balatro Red
        secondary: Color(0xFF1E88E5), // Balatro Blue
        surface: Color(0xFF1A1F24),
      ),
      textTheme: GoogleFonts.vt323TextTheme(ThemeData.dark().textTheme).copyWith(
        bodyMedium: GoogleFonts.vt323(fontSize: 24, color: Colors.white),
        bodyLarge: GoogleFonts.vt323(fontSize: 28, color: Colors.white),
        headlineSmall: GoogleFonts.vt323(fontSize: 32, color: Colors.white),
        headlineMedium: GoogleFonts.vt323(fontSize: 48, color: Colors.white, fontWeight: FontWeight.bold),
      ),
      cardTheme: CardThemeData(
        color: const Color(0xFF1A1F24),
        elevation: 12,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Colors.white24, width: 2),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFE53935),
          foregroundColor: Colors.white,
          elevation: 8,
          shadowColor: Colors.black,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: Colors.white, width: 2), // Chunky border
          ),
          textStyle: GoogleFonts.vt323(fontSize: 28, fontWeight: FontWeight.bold, letterSpacing: 2),
        ),
      ),
    );
  }
}
