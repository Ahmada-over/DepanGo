import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ProTheme {
  // Pro Palette
  static const Color darkBg = Color(0xFF0B1120);       // Slate 950
  static const Color darkCard = Color(0xFF1E293B);     // Slate 800
  static const Color darkSurface = Color(0xFF161F30);  // Slate 900
  static const Color darkBorder = Color(0xFF334155);   // Slate 700
  
  static const Color primaryEmerald = Color(0xFF0F766E); // Primary Emerald Teal
  static const Color primaryLight = Color(0xFF14B8A6);   // Accent Teal
  static const Color amber = Color(0xFFF59E0B);          // Amber Orange
  static const Color success = Color(0xFF10B981);        // Success Green
  static const Color error = Color(0xFFEF4444);          // Red Error
  
  static const Color textWhite = Color(0xFFF8FAFC);
  static const Color textMuted = Color(0xFF94A3B8);

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: darkBg,
      primaryColor: primaryEmerald,
      colorScheme: const ColorScheme.dark(
        primary: primaryEmerald,
        secondary: primaryLight,
        surface: darkSurface,
        error: error,
        onPrimary: Colors.white,
        onSurface: textWhite,
      ),
      textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme).copyWith(
        displayLarge: const TextStyle(color: textWhite, fontWeight: FontWeight.bold),
        titleLarge: const TextStyle(color: textWhite, fontWeight: FontWeight.bold),
        titleMedium: const TextStyle(color: textWhite, fontWeight: FontWeight.w600),
        bodyLarge: const TextStyle(color: textWhite),
        bodyMedium: const TextStyle(color: textMuted),
      ),
      cardTheme: CardThemeData(
        color: darkCard,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: darkBorder, width: 1),
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: darkBg,
        elevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(color: textWhite),
        titleTextStyle: TextStyle(
          color: textWhite,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryEmerald,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
