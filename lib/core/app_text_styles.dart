import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppTextStyles {
  // Ultra-bold, tight letter spacing for Linear/Stripe feel
  static const TextStyle h1 = TextStyle(
    fontSize: 80,
    fontWeight: FontWeight.w800,
    height: 1.05,
    color: AppColors.textPrimary,
    letterSpacing: -3.0,
  );

  static const TextStyle h2 = TextStyle(
    fontSize: 48,
    fontWeight: FontWeight.w800,
    height: 1.1,
    color: AppColors.textPrimary,
    letterSpacing: -2.0,
  );

  static const TextStyle h3 = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.w700,
    height: 1.2,
    color: AppColors.textPrimary,
    letterSpacing: -1.0,
  );

  static const TextStyle bodyLarge = TextStyle(
    fontSize: 22,
    height: 1.6,
    color: AppColors.textSecondary,
    letterSpacing: -0.2,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontSize: 18,
    height: 1.6,
    color: AppColors.textSecondary,
    letterSpacing: -0.1,
  );
  
  static const TextStyle bodySmall = TextStyle(
    fontSize: 15,
    height: 1.5,
    color: AppColors.textSecondary,
  );
  
  static const TextStyle sectionEyebrow = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w700,
    color: AppColors.accentRoyalBlue,
    letterSpacing: 2.0,
  );
}
