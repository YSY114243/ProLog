import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Central strict theme configuration for InternLog using a Global ColorScheme.
class AppTheme {
  // ── Status colours (Semantic) ──────────────────────────────────────────────
  static const Color statusSite = Color(0xFF4CAF50);
  static const Color statusOffice = Color(0xFF2196F3);
  static const Color statusReview = Color(0xFFFF9800);

  static ThemeData lightTheme() {
    final base = ThemeData.light(useMaterial3: true);

    // Strict Global Target Colors
    const primary = Color(0xFF1E3A8A); // Deep Navy Blue
    const secondary = Color(0xFF2563EB); // Vibrant Royal Blue
    const background = Color(0xFFF8FAFC); // Very Light Slate Gray
    const surface = Color(0xFFFFFFFF); // Pure White
    const textPrimary = Color(0xFF0F172A); // Dark Slate
    const textSecondary = Color(0xFF475569); // Slate 600
    const textMuted = Color(0xFF94A3B8); // Slate 400
    const dividerColor = Color(0xFFE2E8F0); // Slate 200

    return base.copyWith(
      scaffoldBackgroundColor: background,
      colorScheme: const ColorScheme.light(
        primary: primary,
        secondary: secondary,
        surface: surface,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: textPrimary,
      ),
      dividerColor: dividerColor,
      textTheme: GoogleFonts.interTextTheme(base.textTheme).copyWith(
        displayLarge: GoogleFonts.inter(
          fontSize: 32, fontWeight: FontWeight.w700, color: textPrimary,
        ),
        headlineMedium: GoogleFonts.inter(
          fontSize: 22, fontWeight: FontWeight.w600, color: textPrimary,
        ),
        titleLarge: GoogleFonts.inter(
          fontSize: 18, fontWeight: FontWeight.w600, color: textPrimary,
        ),
        titleMedium: GoogleFonts.inter(
          fontSize: 15, fontWeight: FontWeight.w500, color: textPrimary,
        ),
        bodyLarge: GoogleFonts.inter(
          fontSize: 14, fontWeight: FontWeight.w400, color: textPrimary,
        ),
        bodyMedium: GoogleFonts.inter(
          fontSize: 13, fontWeight: FontWeight.w400, color: textSecondary,
        ),
        labelSmall: GoogleFonts.inter(
          fontSize: 11, fontWeight: FontWeight.w500, color: textMuted,
          letterSpacing: 0.8,
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: surface,
        foregroundColor: textPrimary,
        elevation: 0,
        scrolledUnderElevation: 1,
        shadowColor: dividerColor,
        titleTextStyle: GoogleFonts.inter(
          fontSize: 18, fontWeight: FontWeight.w700, color: textPrimary,
        ),
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 2, // Subtle shadow for SaaS look
        shadowColor: Colors.black.withValues(alpha: 0.05),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: dividerColor, width: 1),
        ),
        margin: EdgeInsets.zero,
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
        ),
      ),
      dividerTheme: const DividerThemeData(color: dividerColor, thickness: 1),
      chipTheme: ChipThemeData(
        backgroundColor: background,
        labelStyle: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w500, color: textSecondary),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(6),
          side: BorderSide(color: dividerColor),
        ),
      ),
    );
  }
}
