import 'package:flutter/material.dart';

class AppColors {
  // Brand Colors
  static const Color background = Color(0xFFF8FAFC);
  static const Color textPrimary = Color(0xFF0F172A);
  static const Color textSecondary = Color(0xFF475569);
  static const Color primaryDeepNavy = Color(0xFF1E3A8A);
  static const Color accentRoyalBlue = Color(0xFF2563EB);
  static const Color surfaceWhite = Colors.white;
  static const Color borderSubtle = Color(0xFFE2E8F0);

  // Common Box Shadows (Stripe/Linear style)
  static final List<BoxShadow> softShadow = [
    BoxShadow(
      color: textPrimary.withValues(alpha: 0.04),
      blurRadius: 10,
      offset: const Offset(0, 4),
    ),
    BoxShadow(
      color: textPrimary.withValues(alpha: 0.02),
      blurRadius: 4,
      offset: const Offset(0, 2),
    ),
  ];

  static final List<BoxShadow> floatingShadow = [
    BoxShadow(
      color: textPrimary.withValues(alpha: 0.08),
      blurRadius: 24,
      offset: const Offset(0, 12),
    ),
    BoxShadow(
      color: textPrimary.withValues(alpha: 0.04),
      blurRadius: 8,
      offset: const Offset(0, 4),
    ),
  ];
}
