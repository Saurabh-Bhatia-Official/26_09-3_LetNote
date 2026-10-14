import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

enum AppAccentColor {
  emerald(Color(0xFF10B981), 'Emerald'),
  indigo(Color(0xFF6366F1), 'Indigo'),
  violet(Color(0xFF8B5CF6), 'Violet'),
  amber(Color(0xFFF59E0B), 'Amber'),
  rose(Color(0xFFF43F5E), 'Rose');

  final Color color;
  final String label;
  const AppAccentColor(this.color, this.label);
}

class AppTheme {
  // Brand colors
  static const Color darkBg = Color(0xFF0B0F19);
  static const Color darkCard = Color(0xFF151C2C);
  static const Color darkCardElevated = Color(0xFF1E293B);
  static const Color darkBorder = Color(0xFF26334D);
  static const Color darkSubtext = Color(0xFF94A3B8);

  static const Color lightBg = Color(0xFFF8FAFC);
  static const Color lightCard = Color(0xFFFFFFFF);
  static const Color lightCardElevated = Color(0xFFF1F5F9);
  static const Color lightBorder = Color(0xFFE2E8F0);
  static const Color lightSubtext = Color(0xFF64748B);

  static ThemeData lightTheme([AppAccentColor accent = AppAccentColor.emerald]) {
    final primary = accent.color;
    final textTheme = GoogleFonts.interTextTheme(ThemeData.light().textTheme);
    final titleTheme = GoogleFonts.outfitTextTheme(ThemeData.light().textTheme);

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primaryColor: primary,
      scaffoldBackgroundColor: lightBg,
      colorScheme: ColorScheme.light(
        primary: primary,
        secondary: primary.withValues(alpha: 0.8),
        surface: lightCard,
        onSurface: const Color(0xFF0F172A),
        outline: lightBorder,
      ),
      cardTheme: CardThemeData(
        color: lightCard,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: lightBorder, width: 1),
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: lightCard,
        elevation: 0,
        scrolledUnderElevation: 1,
        titleTextStyle: titleTheme.titleLarge?.copyWith(
          color: const Color(0xFF0F172A),
          fontWeight: FontWeight.w700,
        ),
        iconTheme: const IconThemeData(color: Color(0xFF1E293B)),
      ),
      dividerTheme: const DividerThemeData(
        color: lightBorder,
        thickness: 1,
        space: 1,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: lightCardElevated,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: lightBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: lightBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: primary, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      textTheme: textTheme.copyWith(
        headlineLarge: titleTheme.headlineLarge?.copyWith(fontWeight: FontWeight.bold),
        headlineMedium: titleTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
        titleLarge: titleTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
        titleMedium: titleTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
      ),
    );
  }

  static ThemeData darkTheme([AppAccentColor accent = AppAccentColor.emerald]) {
    final primary = accent.color;
    final textTheme = GoogleFonts.interTextTheme(ThemeData.dark().textTheme);
    final titleTheme = GoogleFonts.outfitTextTheme(ThemeData.dark().textTheme);

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      primaryColor: primary,
      scaffoldBackgroundColor: darkBg,
      colorScheme: ColorScheme.dark(
        primary: primary,
        secondary: primary.withValues(alpha: 0.8),
        surface: darkCard,
        onSurface: const Color(0xFFF1F5F9),
        outline: darkBorder,
      ),
      cardTheme: CardThemeData(
        color: darkCard,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: darkBorder, width: 1),
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: darkBg,
        elevation: 0,
        scrolledUnderElevation: 1,
        titleTextStyle: titleTheme.titleLarge?.copyWith(
          color: const Color(0xFFF1F5F9),
          fontWeight: FontWeight.w700,
        ),
        iconTheme: const IconThemeData(color: Color(0xFFCBD5E1)),
      ),
      dividerTheme: const DividerThemeData(
        color: darkBorder,
        thickness: 1,
        space: 1,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: darkCardElevated,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: darkBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: darkBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: primary, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      textTheme: textTheme.copyWith(
        headlineLarge: titleTheme.headlineLarge?.copyWith(fontWeight: FontWeight.bold),
        headlineMedium: titleTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
        titleLarge: titleTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
        titleMedium: titleTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
      ),
    );
  }
}
